import uuid
import logging
from typing import List, Dict, Any, Optional
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, status, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

import db
import prompts
import agent
import face_auth
import led_controller
import vitals_check
import tts
import stt
import ocr_pipeline
import printer

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("main")

app = FastAPI(title="Dr. Horria Orchestrator", version="1.0.0")

@app.on_event("startup")
async def startup_event():
    logger.info("Preloading LLaMA model...")
    import llm
    llm.preload()
    logger.info("LLaMA model preloaded successfully.")

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic request models

class PasswordLoginRequest(BaseModel):
    phone: str
    password: str

class FaceLoginRequest(BaseModel):
    image: str
    liveness_frames: Optional[List[str]] = None

class SignupRequest(BaseModel):
    name: str
    phone: str
    age: int
    sex: str
    password: Optional[str] = None
    image: Optional[str] = None
    medical_history: Optional[Dict[str, Any]] = None

class VitalsRequest(BaseModel):
    session_id: str
    user_id: int
    language: str
    hr: Optional[int] = None
    spo2: Optional[int] = None
    sys: Optional[int] = None
    dia: Optional[int] = None
    temp: Optional[float] = None
    ecg_wave: Optional[List[float]] = None

class LabScanRequest(BaseModel):
    session_id: str
    user_id: int

class VoiceRequest(BaseModel):
    session_id: str
    user_id: int
    audio: str
    test_transcription: Optional[str] = None

class LanguageRequest(BaseModel):
    language: str

class PrintAssessmentRequest(BaseModel):
    session_id: str
    user_id: int
    vitals: Optional[Dict[str, Any]] = None
    ecg: Optional[Dict[str, Any]] = None
    assessment: Optional[Dict[str, Any]] = None
    recommendations: Optional[List[str]] = None
    clinic_name: Optional[str] = None

# Helpers

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return plain_password == hashed_password

def build_login_success_payload(user: dict, resumed: bool, current_step: str) -> dict:
    session_id = str(uuid.uuid4())
    db.create_session(session_id, user['id'], resumed=resumed, current_step=current_step)
    
    greeting = f"أهلاً بك يا {user['name']}. دكتورة حورية ترحب بك وتتمنى لك صحة جيدة."
    greeting_audio = tts.synthesize_speech(greeting)
    
    chat_history = []
    return {
        "user": {
            "id": user['id'],
            "name": user['name'],
            "phone": user['phone'],
            "age": user['age'],
            "sex": user['sex'],
            "preferred_language": user['preferred_language']
        },
        "session_id": session_id,
        "current_step": current_step,
        "resumed": resumed,
        "greeting": greeting,
        "audio_base64": greeting_audio,
        "history": chat_history
    }

# REST Endpoints

@app.get("/health")
def get_health():
    logger.info("Health check ping received.")
    return {"status": "ok", "message": "Dr. Horria Orchestrator is running."}

@app.get("/led/state")
def get_led_state():
    state = led_controller.get_current_led_state()
    return {"state": state}

@app.post("/auth/password-login")
def password_login(req: PasswordLoginRequest):
    user = db.get_user_by_phone(req.phone)
    if not user or not verify_password(req.password, user['password_hash']):
        led_controller.set_led_state("ERROR")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="اسم المستخدم أو كلمة المرور غير صحيحة"
        )
    
    led_controller.set_led_state("SUCCESS")
    
    resumed = False
    current_step = "HOME"
    
    conn = db.get_db_connection()
    latest_sess = conn.execute(
        "SELECT * FROM sessions WHERE user_id = ? ORDER BY created_at DESC LIMIT 1",
        (user['id'],)
    ).fetchone()
    conn.close()
    
    if latest_sess:
        resumed = True
        current_step = latest_sess['current_step'] or "HOME"
        
    return build_login_success_payload(user, resumed, current_step)

@app.post("/auth/face-login-image")
def face_login(req: FaceLoginRequest):
    led_controller.set_led_state("LISTENING")
    
    if req.liveness_frames:
        liveness_ok = face_auth.verify_liveness(req.liveness_frames)
        if not liveness_ok:
            led_controller.set_led_state("ERROR")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="فشل التحقق من الحيوية (تنبيه صورة ثابتة)"
            )
            
    conn = db.get_db_connection()
    users = conn.execute("SELECT * FROM users WHERE face_encoding IS NOT NULL").fetchall()
    conn.close()
    
    matched_user = None
    for u in users:
        if face_auth.match_face(req.image, u['face_encoding']):
            matched_user = dict(u)
            break
            
    if not matched_user:
        led_controller.set_led_state("ERROR")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="الوجه غير مسجل، يرجى تسجيل الدخول بكلمة المرور أو إنشاء حساب"
        )
        
    led_controller.set_led_state("SUCCESS")
    
    resumed = False
    current_step = "HOME"
    
    conn = db.get_db_connection()
    latest_sess = conn.execute(
        "SELECT * FROM sessions WHERE user_id = ? ORDER BY created_at DESC LIMIT 1",
        (matched_user['id'],)
    ).fetchone()
    conn.close()
    
    if latest_sess:
        resumed = True
        current_step = latest_sess['current_step'] or "HOME"
        
    return build_login_success_payload(matched_user, resumed, current_step)

@app.post("/auth/signup-image")
def signup(req: SignupRequest):
    existing = db.get_user_by_phone(req.phone)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="رقم الهاتف مسجل بالفعل"
        )
        
    import base64
    import json
    
    face_encoding_str = "face_mock_reference"
    if req.image:
        try:
            clean_b64 = face_auth.uploaded_image_image_clean(req.image)
            missing_padding = len(clean_b64) % 4
            if missing_padding:
                clean_b64 += '=' * (4 - missing_padding)
            image_bytes = base64.b64decode(clean_b64)
            embedding = face_auth.extract_embedding_from_image(image_bytes)
            if embedding is None:
                raise HTTPException(status_code=400, detail="لم يتم العثور على وجه في الصورة. يرجى المحاولة مرة أخرى.")
            face_encoding_str = json.dumps(embedding)
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error extracting face embedding during signup: {e}")
            raise HTTPException(status_code=400, detail="صورة الوجه غير صالحة.")
            
    user_id = db.create_user(
        name=req.name,
        phone=req.phone,
        password_hash=req.password or "",
        age=req.age,
        sex=req.sex,
        face_encoding=face_encoding_str,
        preferred_language='ar'
    )
    
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="حدث خطأ أثناء حفظ الملف الشخصي للمستخدم"
        )
        
    if req.medical_history:
        for q_id, val in req.medical_history.items():
            db.save_medical_history(user_id, q_id, str(val))
            
    new_user = db.get_user_by_id(user_id)
    return build_login_success_payload(new_user, resumed=False, current_step="HOME")

@app.patch("/user/{user_id}/language")
def update_language(user_id: int, req: LanguageRequest):
    user = db.get_user_by_id(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="المستخدم غير موجود"
        )
        
    db.update_user_language(user_id, req.language)
    return {"status": "ok", "message": "تم تحديث اللغة المفضلة بنجاح"}

@app.post("/vitals")
def vitals(req: VitalsRequest):
    is_critical = vitals_check.evaluate_vitals(
        hr=req.hr,
        spo2=req.spo2,
        sys=req.sys,
        dia=req.dia,
        temp=req.temp
    )
    
    db.save_vitals(
        user_id=req.user_id,
        session_id=req.session_id,
        hr=req.hr,
        spo2=req.spo2,
        sys=req.sys,
        dia=req.dia,
        temp=req.temp,
        ecg_wave=req.ecg_wave,
        is_critical=is_critical
    )
    
    if is_critical:
        led_controller.set_led_state("ALERT_HIGH")
        alert_msg = "تحذير: تم رصد قراءات حيوية خارج المعدل الطبيعي بشكل حرج. يرجى التزام الهدوء، نقوم بالاتصال بالإسعاف لمساعدتك فوراً."
        alert_audio = tts.synthesize_speech(alert_msg)
        return {
            "critical": True,
            "status": "أرقام حيوية حرجة للغاية!",
            "audio_base64": alert_audio
        }
        
    led_controller.set_led_state("SUCCESS")
    return {
        "critical": False,
        "status": "القراءات سليمة وضمن المعدلات الطبيعية",
        "audio_base64": ""
    }

@app.post("/lab/scan")
def scan_lab_results(req: LabScanRequest):
    led_controller.set_led_state("THINKING")
    
    user_info = db.get_user_by_id(req.user_id)
    if not user_info:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="المستخدم غير موجود"
        )
        
    results = ocr_pipeline.run_lab_scan_ocr()
    
    for res in results:
        db.save_lab_result(
            user_id=req.user_id,
            session_id=req.session_id,
            test_name=res['test_name'],
            value=res['value'],
            flag=res['flag']
        )
        
    printer.print_receipt(user_info['name'], results)
    led_controller.set_led_state("SUCCESS")
    return {"parsed_results": results}

@app.post("/print-assessment")
def print_assessment(req: PrintAssessmentRequest):
    logger.info(f"Received print assessment request for user {req.user_id}")
    
    user_info = db.get_user_by_id(req.user_id)
    if not user_info:
        raise HTTPException(status_code=404, detail="User not found")
        
    if req.vitals:
        vitals_dict = req.vitals
        ecg_wave_data = req.vitals.get("ecg_wave")
    else:
        session_vitals = db.get_vitals_by_session(req.session_id)
        latest_vitals = session_vitals if session_vitals else {}
        vitals_dict = {
            "heart_rate": latest_vitals.get('hr', 'N/A'),
            "spo2": latest_vitals.get('spo2', 'N/A'),
            "blood_pressure": f"{latest_vitals.get('sys', 'N/A')}/{latest_vitals.get('dia', 'N/A')}",
            "temp": latest_vitals.get('temp', 'N/A')
        }
        ecg_wave_data = latest_vitals.get("ecg_wave")
    
    data = {
        "name": user_info['name'],
        "age": f"{user_info.get('age', 'Unknown')}",
        "gender": user_info.get('sex', 'Unknown'),
        "clinic_name": req.clinic_name,
        "vitals": vitals_dict,
        "ecg_wave": ecg_wave_data,
        "ecg": req.ecg or {},
        "assessment": req.assessment or {},
        "recommendations": req.recommendations or [
            "* Exercise regularly",
            "* Drink enough water",
            "* Sleep 7-9 hours daily"
        ]
    }
    
    success = printer.print_full_assessment(data)
    if success:
        return {"status": "success", "message": "Assessment printed successfully"}
    else:
        raise HTTPException(status_code=500, detail="Failed to print assessment")

@app.get("/print-assessment/{session_id}")
def print_assessment_by_id(session_id: str):
    logger.info(f"Received print request for session {session_id}")
    
    session = db.get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
        
    user_id = session['user_id']
    user_info = db.get_user_by_id(user_id)
    if not user_info:
        raise HTTPException(status_code=404, detail="User not found")
        
    vitals = db.get_vitals_by_session(session_id) or {}
    
    # Check if there's any AI diagnosis for this session from chat history
    recs = []
    cache_file = os.path.join(os.path.dirname(__file__), "diagnoses_cache", f"{session_id}.json")
    if os.path.exists(cache_file):
        try:
            with open(cache_file, "r") as f:
                diagnoses = json.load(f)
                if diagnoses:
                    top_diag = diagnoses[0]
                    # Extract string arrays from recommendation objects
                    for rec_obj in top_diag.get("recommendations", []):
                        title = rec_obj.get("title", "توصية")
                        items = rec_obj.get("items", [])
                        if items:
                            recs.append(f"{title}: {', '.join(items)}")
        except Exception as e:
            logger.error(f"Failed to read diagnoses cache for printing: {e}")
            
    timestamp_str = vitals.get('timestamp') or session.get('created_at', '')
    if timestamp_str:
        # Reformat from ISO to human readable
        try:
            timestamp_str = datetime.fromisoformat(timestamp_str).strftime("%Y-%m-%d %H:%M")
        except:
            pass

    data = {
        "name": user_info['name'],
        "age": f"{user_info.get('age', 'Unknown')}",
        "gender": user_info.get('sex', 'Unknown'),
        "clinic_name": "Clinic",
        "date": timestamp_str,
        "vitals": {
            "heart_rate": vitals.get('hr', 'N/A'),
            "spo2": vitals.get('spo2', 'N/A'),
            "blood_pressure": f"{vitals.get('sys', 'N/A')}/{vitals.get('dia', 'N/A')}",
            "temp": vitals.get('temp', 'N/A')
        },
        "ecg_wave": vitals.get("ecg_wave"),
        "ecg": {},
        "assessment": {},
        "recommendations": recs
    }
    
    success = printer.print_full_assessment(data)
    if success:
        return {"status": "success", "message": f"Assessment for session {session_id} printed successfully"}
    else:
        raise HTTPException(status_code=500, detail="Failed to print assessment")

class PrintEcgRequest(BaseModel):
    wave_points: Optional[List[float]] = None
    heart_rate: Optional[int] = None
    diagnosis: Optional[str] = None

@app.post("/print-ecg")
def print_ecg_strip_endpoint(req: PrintEcgRequest = None):
    logger.info(f"Received print ECG strip request (wave_points={len(req.wave_points) if req and req.wave_points else 0})")
    success = printer.print_ecg_strip_standalone(
        wave_points=req.wave_points if req else None,
        heart_rate=req.heart_rate if req else None,
        diagnosis=req.diagnosis if req else None,
    )
    if success:
        return {"status": "success", "message": "ECG Strip printed successfully"}
    else:
        raise HTTPException(status_code=500, detail="Failed to print ECG strip")

@app.post("/voice")
def voice_interaction(req: VoiceRequest):
    led_controller.set_led_state("LISTENING")
    
    transcript = stt.transcribe_audio(req.audio, test_transcription=req.test_transcription)
    
    led_controller.set_led_state("THINKING")
    
    agent_output = agent.run_agent_turn(req.user_id, req.session_id, transcript)
    
    db.save_chat_message(req.session_id, "user", transcript)
    db.save_chat_message(req.session_id, "agent", agent_output['response'])
    db.update_session_step(req.session_id, agent_output['next_action'])
    
    led_controller.set_led_state("SPEAKING")
    audio_b64 = tts.synthesize_speech(agent_output['response'])
    
    if agent_output.get('urgency') == 'high' or agent_output.get('theme_state') == 'emergency':
        led_controller.set_led_state("ALERT_HIGH")
    else:
        led_controller.set_led_state("IDLE")
        
    return {
        "response": agent_output['response'],
        "next_action": agent_output['next_action'],
        "urgency": agent_output['urgency'],
        "theme_state": agent_output.get('theme_state', 'normal'),
        "control_command": agent_output.get('control_command', 'NONE'),
        "sdui_components": agent_output.get('sdui_components', []),
        "lab_tests_needed": agent_output.get('lab_tests_needed', []),
        "audio_base64": audio_b64
    }

@app.get("/vitals/history/{user_id}")
def get_vitals_history_list(user_id: int, limit: int = Query(20, ge=1)):
    return db.get_vitals_history(user_id, limit=limit)

@app.get("/lab/history/{user_id}")
def get_lab_history_list(user_id: int, limit: int = Query(20, ge=1)):
    return db.get_lab_history(user_id, limit=limit)

class UpdateProfileRequest(BaseModel):
    user_id: int
    updates: Dict[str, str]

@app.get("/user-profile/{user_id}")
def get_user_profile(user_id: int):
    user = db.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    medical_history = db.get_medical_history(user_id)
    return {
        "user": user,
        "medical_history": {item['question_id']: item['answer'] for item in medical_history}
    }

@app.post("/update-user-profile")
def update_user_profile(req: UpdateProfileRequest):
    user = db.get_user_by_id(req.user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    for key, val in req.updates.items():
        db.update_medical_history(req.user_id, key, val)
    return {"status": "success"}

# --- Diagnosis APIs ---
from typing import List, Dict, Any


class ExtractSymptomsRequest(BaseModel):
    session_id: str
    text: str

@app.post("/diagnosis/extract-symptoms")
def extract_symptoms(req: ExtractSymptomsRequest):
    logger.info(f"Extracting symptoms from: {req.text}")
    import llm
    found_symptoms = llm.extract_symptoms(req.text)
    if not found_symptoms:
        found_symptoms.append("أعراض مخصصة (من الصوت)")
    return {"symptoms": found_symptoms}


class SpeakRequest(BaseModel):
    text: str

@app.post("/diagnosis/speak")
def speak_text(req: SpeakRequest):
    logger.info(f"Speaking text via TTS: {req.text}")
    from tts import synthesize_speech
    synthesize_speech(req.text, lang="ar")
    return {"status": "ok"}

class StartDiagnosisRequest(BaseModel):
    session_id: str
    symptoms: List[str]
    duration: str

class MeasurementResultRequest(BaseModel):
    session_id: str
    measurement: str
    value: Dict[str, Any]

@app.get("/diagnosis/symptoms")
def get_symptoms():
    return {
        "categories": [
            {
                "name": "أعراض القلب والدورة الدموية",
                "symptoms": ["ألم في الصدر", "خفقان القلب", "ضيق في التنفس", "دوخة ودوار", "إغماء"]
            },
            {
                "name": "أعراض ضغط الدم",
                "symptoms": ["صداع مستمر", "رؤية ضبابية", "إرهاق وضعف عام"]
            },
            {
                "name": "أعراض تنفسية",
                "symptoms": ["سعال", "أزيز بالصدر", "صعوبة في التنفس"]
            },
            {
                "name": "أعراض السكري",
                "symptoms": ["عطش شديد", "كثرة التبول", "فقدان الوزن"]
            },
            {
                "name": "أعراض أخرى",
                "symptoms": []
            }
        ]
    }

@app.post("/diagnosis/start")
def start_diagnosis(req: StartDiagnosisRequest):
    logger.info(f"Diagnosis started for session {req.session_id}")
    return {"status": "ok", "message": "Diagnosis started", "session_id": req.session_id}

@app.post("/diagnosis/analyze")
def analyze_diagnosis(req: dict):
    # Temporary mock until local LLM integration is completed
    return {
        "possible_conditions": ["Hypertension", "Heart Failure"],
        "required_measurements": ["BloodPressure", "HeartRate", "SpO2", "ECG"]
    }

@app.get("/diagnosis/measurement/current")
def get_current_measurement(session_id: str):
    return {
        "measurement": "BloodPressure",
        "title": "قياس ضغط الدم",
        "instruction": "ضع الحزام على ذراعك الأيسر فوق المرفق مباشرة.",
        "audio_base64": "" # TTS audio to be added
    }

@app.post("/diagnosis/measurement/result")
def submit_measurement_result(req: MeasurementResultRequest):
    return {"next_measurement": "SpO2"}

@app.post("/diagnosis/final-analysis")
def final_analysis(req: dict):
    return {
        "possible_conditions": ["Possible Hypertension"],
        "risk_level": "Moderate",
        "confidence": "High",
        "recommendations": ["Reduce sodium intake", "Monitor daily", "Consult a physician"],
        "explanation": "Based on the elevated blood pressure readings and reported symptoms."
    }


# WebSockets Endpoint

@app.websocket("/ws/{session_id}/{user_id}")
async def websocket_chat_endpoint(websocket: WebSocket, session_id: str, user_id: int):
    await websocket.accept()
    logger.info(f"WebSocket connection established for user {user_id}, session {session_id}")
    
    try:
        while True:
            data = await websocket.receive_json()
            agent_output = None
            user_msg = ""
            
            # Case 1: Simple text query
            if data.get("type") == "text":
                user_msg = data.get("message")
                led_controller.set_led_state("THINKING")
                agent_output = agent.run_agent_turn(user_id, session_id, user_msg)
                
                db.save_chat_message(session_id, "user", user_msg)
                db.save_chat_message(session_id, "agent", agent_output['response'])
                db.update_session_step(session_id, agent_output['next_action'])
            
            # Case 2: Direct sensor raw data stream uploaded via Method Channel
            elif data.get("type") == "sensor_data":
                sensor_vals = data.get("data", {}) # e.g. {"sys": 135, "dia": 82, "hr": 70, "temp": 36.8, "spo2": 98}
                hr = sensor_vals.get("hr", 72)
                spo2 = sensor_vals.get("spo2", 98)
                sys = sensor_vals.get("sys")
                dia = sensor_vals.get("dia")
                temp = sensor_vals.get("temp")
                
                is_critical = vitals_check.evaluate_vitals(hr=hr, spo2=spo2, sys=sys, dia=dia, temp=temp)
                db.save_vitals(user_id, session_id, hr, spo2, sys, dia, temp, is_critical)
                
                # Auto trigger an LLM agent turn explaining the raw reading classification
                user_msg = f"تم إدخال العلامات الحيوية: ضغط: {sys}/{dia} mmHg, نبض: {hr} bpm, أكسجين: {spo2}%, حرارة: {temp}°C."
                led_controller.set_led_state("THINKING")
                agent_output = agent.run_agent_turn(user_id, session_id, user_msg)
                
                db.save_chat_message(session_id, "user", "[تم قياس المؤشرات الحيوية تلقائياً]")
                db.save_chat_message(session_id, "agent", agent_output['response'])
                db.update_session_step(session_id, agent_output['next_action'])
                
            if agent_output:
                # Split response text into sentences to stream speech chunks
                text_response = agent_output['response']
                sentences = []
                current_sentence = []
                
                for char in text_response:
                    current_sentence.append(char)
                    if char in ['.', '،', '?', '!', '\n']:
                        joined = "".join(current_sentence).strip()
                        if joined:
                            sentences.append(joined)
                        current_sentence = []
                if current_sentence:
                    joined = "".join(current_sentence).strip()
                    if joined:
                        sentences.append(joined)
                        
                if not sentences:
                    sentences = [text_response]
                
                led_controller.set_led_state("SPEAKING")
                
                for sent in sentences:
                    audio_b64 = tts.synthesize_speech(sent)
                    await websocket.send_json({
                        "type": "sentence",
                        "text": sent,
                        "audio_base64": audio_b64
                    })
                
                # Send the final done indicator containing full response meta
                await websocket.send_json({
                    "type": "done",
                    "next_action": agent_output['next_action'],
                    "urgency": agent_output['urgency'],
                    "theme_state": agent_output.get('theme_state', 'normal'),
                    "options": agent_output.get('options', []),
                    "differential_diagnoses": agent_output.get('differential_diagnoses', []),
                    "control_command": agent_output.get('control_command', 'NONE')
                })
                
                if agent_output.get('urgency') == 'high' or agent_output.get('theme_state') == 'emergency':
                    led_controller.set_led_state("ALERT_HIGH")
                else:
                    led_controller.set_led_state("IDLE")
                    
    except WebSocketDisconnect:
        logger.info(f"WebSocket disconnected for user {user_id}, session {session_id}")
    except Exception as e:
        logger.error(f"Error in WebSocket pipeline: {e}")
        await websocket.close()
# --- DEBUG: log every request (method, path, headers, body) ---
@app.middleware("http")
async def log_requests(request, call_next):
    body_bytes = await request.body()
    try:
        body_text = body_bytes.decode("utf-8")
    except Exception:
        body_text = repr(body_bytes)

    logger.info(
        "INCOMING REQUEST: %s %s | client=%s | headers=%s | body=%s",
        request.method,
        request.url.path,
        request.client.host if request.client else "unknown",
        dict(request.headers),
        body_text,
    )

    # Need to re-inject the body since we already consumed the stream above
    async def receive():
        return {"type": "http.request", "body": body_bytes}
    request._receive = receive

    response = await call_next(request)

    logger.info(
        "RESPONSE: %s %s -> status=%s",
        request.method,
        request.url.path,
        response.status_code,
    )

    return response
# --- END DEBUG ---