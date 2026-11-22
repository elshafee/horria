"""
Dr. Horria orchestrator — FastAPI application.
Handles authentication, vitals ingestion, lab OCR, voice interaction,
WebSocket streaming, and printing for the biomedical robot.
"""
import uuid
import json
import logging
import os
from datetime import datetime
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

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("main")

app = FastAPI(title="Dr. Horria Orchestrator", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Request models ─────────────────────────────────────────────────────────────

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

class PrintEcgRequest(BaseModel):
    wave_points: Optional[List[float]] = None
    heart_rate: Optional[int] = None
    diagnosis: Optional[str] = None

class UpdateProfileRequest(BaseModel):
    user_id: int
    updates: Dict[str, str]

class ExtractSymptomsRequest(BaseModel):
    session_id: str
    text: str

class SpeakRequest(BaseModel):
    text: str


# ── Helpers ────────────────────────────────────────────────────────────────────

def _verify_password(plain: str, hashed: str) -> bool:
    return plain == hashed


def _build_login_payload(user: dict, resumed: bool, current_step: str) -> dict:
    session_id = str(uuid.uuid4())
    db.create_session(session_id, user["id"], resumed=resumed, current_step=current_step)
    greeting = f"أهلاً بك يا {user['name']}. دكتورة حورية ترحب بك وتتمنى لك صحة جيدة."
    tts.synthesize_speech(greeting)
    return {
        "user": {
            "id": user["id"],
            "name": user["name"],
            "phone": user["phone"],
            "age": user["age"],
            "sex": user["sex"],
            "preferred_language": user["preferred_language"],
        },
        "session_id": session_id,
        "current_step": current_step,
        "resumed": resumed,
        "greeting": greeting,
        "history": [],
    }


def _get_user_or_404(user_id: int) -> dict:
    user = db.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="المستخدم غير موجود")
    return user


# ── Health ─────────────────────────────────────────────────────────────────────

@app.get("/health")
def get_health():
    return {"status": "ok", "message": "Dr. Horria Orchestrator is running."}

@app.get("/led/state")
def get_led_state():
    return {"state": led_controller.get_current_led_state()}


# ── Authentication ─────────────────────────────────────────────────────────────

@app.post("/auth/password-login")
def password_login(req: PasswordLoginRequest):
    user = db.get_user_by_phone(req.phone)
    if not user or not _verify_password(req.password, user["password_hash"]):
        led_controller.set_led_state("ERROR")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="اسم المستخدم أو كلمة المرور غير صحيحة",
        )
    led_controller.set_led_state("SUCCESS")
    conn = db.get_db_connection()
    latest = conn.execute(
        "SELECT * FROM sessions WHERE user_id = ? ORDER BY created_at DESC LIMIT 1",
        (user["id"],),
    ).fetchone()
    conn.close()
    resumed = bool(latest)
    current_step = (latest["current_step"] or "HOME") if latest else "HOME"
    return _build_login_payload(user, resumed, current_step)


@app.post("/auth/face-login-image")
def face_login(req: FaceLoginRequest):
    led_controller.set_led_state("LISTENING")
    if req.liveness_frames:
        if not face_auth.verify_liveness(req.liveness_frames):
            led_controller.set_led_state("ERROR")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="فشل التحقق من الحيوية (تنبيه صورة ثابتة)",
            )
    conn = db.get_db_connection()
    users = conn.execute("SELECT * FROM users WHERE face_encoding IS NOT NULL").fetchall()
    conn.close()
    matched_user = next(
        (dict(u) for u in users if face_auth.match_face(req.image, u["face_encoding"])), None
    )
    if not matched_user:
        led_controller.set_led_state("ERROR")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="الوجه غير مسجل، يرجى تسجيل الدخول بكلمة المرور أو إنشاء حساب",
        )
    led_controller.set_led_state("SUCCESS")
    conn = db.get_db_connection()
    latest = conn.execute(
        "SELECT * FROM sessions WHERE user_id = ? ORDER BY created_at DESC LIMIT 1",
        (matched_user["id"],),
    ).fetchone()
    conn.close()
    resumed = bool(latest)
    current_step = (latest["current_step"] or "HOME") if latest else "HOME"
    return _build_login_payload(matched_user, resumed, current_step)


@app.post("/auth/signup-image")
def signup(req: SignupRequest):
    import base64 as _b64
    if db.get_user_by_phone(req.phone):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="رقم الهاتف مسجل بالفعل"
        )
    face_encoding_str = "face_mock_reference"
    if req.image:
        try:
            clean = face_auth.uploaded_image_image_clean(req.image)
            clean += "=" * ((-len(clean)) % 4)
            image_bytes = _b64.b64decode(clean)
            embedding = face_auth.extract_embedding_from_image(image_bytes)
            if embedding is None:
                raise HTTPException(
                    status_code=400, detail="لم يتم العثور على وجه في الصورة."
                )
            face_encoding_str = json.dumps(embedding)
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Face embedding error during signup: {e}")
            raise HTTPException(status_code=400, detail="صورة الوجه غير صالحة.")
    user_id = db.create_user(
        name=req.name,
        phone=req.phone,
        password_hash=req.password or "",
        age=req.age,
        sex=req.sex,
        face_encoding=face_encoding_str,
        preferred_language="ar",
    )
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="حدث خطأ أثناء حفظ الملف الشخصي",
        )
    if req.medical_history:
        for q_id, val in req.medical_history.items():
            db.save_medical_history(user_id, q_id, str(val))
    return _build_login_payload(db.get_user_by_id(user_id), resumed=False, current_step="HOME")


@app.patch("/user/{user_id}/language")
def update_language(user_id: int, req: LanguageRequest):
    _get_user_or_404(user_id)
    db.update_user_language(user_id, req.language)
    return {"status": "ok", "message": "تم تحديث اللغة المفضلة بنجاح"}


# ── Vitals ─────────────────────────────────────────────────────────────────────

@app.post("/vitals")
def vitals(req: VitalsRequest):
    is_critical = vitals_check.evaluate_vitals(
        hr=req.hr, spo2=req.spo2, sys=req.sys, dia=req.dia, temp=req.temp
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
        is_critical=is_critical,
    )
    if is_critical:
        led_controller.set_led_state("ALERT_HIGH")
        msg = "تحذير: تم رصد قراءات حيوية خارج المعدل الطبيعي بشكل حرج. يرجى التزام الهدوء."
        tts.synthesize_speech(msg)
        return {"critical": True, "status": "أرقام حيوية حرجة للغاية!"}
    led_controller.set_led_state("SUCCESS")
    return {"critical": False, "status": "القراءات سليمة وضمن المعدلات الطبيعية"}


@app.get("/vitals/history/{user_id}")
def get_vitals_history(user_id: int, limit: int = Query(20, ge=1)):
    return db.get_vitals_history(user_id, limit=limit)


# ── Lab Scan ───────────────────────────────────────────────────────────────────

@app.post("/lab/scan")
def scan_lab_results(req: LabScanRequest):
    led_controller.set_led_state("THINKING")
    user_info = _get_user_or_404(req.user_id)

    raw = ocr_pipeline.run_lab_scan_ocr()

    results = []
    if isinstance(raw, dict) and "test_categories" in raw:
        ts_obj = raw.get("timestamps", {})
        specimen_ts = (
            ts_obj.get("collected") or ts_obj.get("printed") or ts_obj.get("registered")
        )
        for category in raw["test_categories"]:
            for test in category.get("tests", []):
                results.append({
                    "test_name": test.get("name", "Unknown Test"),
                    "value": str(test.get("result", "")),
                    "flag": test.get("flag") or "unknown",
                    "timestamp": specimen_ts,
                })
    elif isinstance(raw, list):
        for r in raw:
            results.append({
                "test_name": r.get("ocr_extracted_name", "Unknown Test"),
                "value": f"{r.get('value', '')} {r.get('unit', '')}".strip(),
                "flag": r.get("flag", "unknown"),
                "timestamp": None,
            })

    for res in results:
        db.save_lab_result(
            user_id=req.user_id,
            session_id=req.session_id,
            test_name=res["test_name"],
            value=res["value"],
            flag=res["flag"],
            timestamp=res["timestamp"],
        )

    printer.print_receipt(user_info["name"], results)
    led_controller.set_led_state("SUCCESS")
    return {"parsed_results": results}


@app.get("/lab/history/{user_id}")
def get_lab_history(user_id: int, limit: int = Query(50, ge=1)):
    return db.get_lab_history(user_id, limit=limit)


# ── Voice ──────────────────────────────────────────────────────────────────────

@app.post("/voice")
def voice_interaction(req: VoiceRequest):
    led_controller.set_led_state("LISTENING")
    transcript = stt.transcribe_audio(req.audio, test_transcription=req.test_transcription)
    led_controller.set_led_state("THINKING")
    agent_output = agent.run_agent_turn(req.user_id, req.session_id, transcript)
    db.save_chat_message(req.session_id, "user", transcript)
    db.save_chat_message(req.session_id, "agent", agent_output["response"])
    db.update_session_step(req.session_id, agent_output["next_action"])
    led_controller.set_led_state("SPEAKING")
    tts.synthesize_speech(agent_output["response"])
    if agent_output.get("urgency") == "high" or agent_output.get("theme_state") == "emergency":
        led_controller.set_led_state("ALERT_HIGH")
    else:
        led_controller.set_led_state("IDLE")
    return {
        "response": agent_output["response"],
        "next_action": agent_output["next_action"],
        "urgency": agent_output["urgency"],
        "theme_state": agent_output.get("theme_state", "normal"),
        "control_command": agent_output.get("control_command", "NONE"),
        "lab_tests_needed": agent_output.get("lab_tests_needed", []),
    }


# ── User Profile ───────────────────────────────────────────────────────────────

@app.get("/user-profile/{user_id}")
def get_user_profile(user_id: int):
    user = _get_user_or_404(user_id)
    medical_history = db.get_medical_history(user_id)
    return {
        "user": user,
        "medical_history": {item["question_id"]: item["answer"] for item in medical_history},
    }


@app.post("/update-user-profile")
def update_user_profile(req: UpdateProfileRequest):
    _get_user_or_404(req.user_id)
    for key, val in req.updates.items():
        db.update_medical_history(req.user_id, key, val)
    return {"status": "success"}


# ── Printing ───────────────────────────────────────────────────────────────────

@app.post("/print-assessment")
def print_assessment(req: PrintAssessmentRequest):
    user_info = _get_user_or_404(req.user_id)
    try:
        if req.vitals:
            vitals_dict = req.vitals
            ecg_wave_data = req.vitals.get("ecg_wave")
        else:
            sv = db.get_vitals_by_session(req.session_id) or {}
            sys_v = sv.get("sys")
            dia_v = sv.get("dia")
            vitals_dict = {
                "heart_rate": sv.get("hr", "N/A"),
                "spo2": sv.get("spo2", "N/A"),
                "blood_pressure": f"{sys_v}/{dia_v}" if sys_v and dia_v else "N/A",
                "temp": sv.get("temp", "N/A"),
            }
            ecg_wave_data = sv.get("ecg_wave")
        data = {
            "name": user_info["name"],
            "age": str(user_info.get("age", "Unknown")),
            "gender": user_info.get("sex", "Unknown"),
            "clinic_name": req.clinic_name,
            "vitals": vitals_dict,
            "ecg_wave": ecg_wave_data,
            "ecg": req.ecg or {},
            "assessment": req.assessment or {},
            "recommendations": req.recommendations or [
                "* ممارسة الرياضة بانتظام",
                "* شرب كمية كافية من الماء",
                "* النوم 7-9 ساعات يومياً",
            ],
        }
        success = printer.print_full_assessment(data)
        if success:
            return {"status": "success", "message": "Assessment printed successfully"}
        raise HTTPException(status_code=500, detail="Failed to print assessment")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"print_assessment error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/print-assessment/{session_id}")
def print_assessment_by_session(session_id: str):
    session = db.get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    user_info = _get_user_or_404(session["user_id"])
    vitals = db.get_vitals_by_session(session_id) or {}
    recs = []
    cache_file = os.path.join(os.path.dirname(__file__), "diagnoses_cache", f"{session_id}.json")
    if os.path.exists(cache_file):
        try:
            with open(cache_file) as f:
                diagnoses = json.load(f)
            if diagnoses:
                for rec_obj in diagnoses[0].get("recommendations", []):
                    items = rec_obj.get("items", [])
                    if items:
                        recs.append(f"{rec_obj.get('title', 'توصية')}: {', '.join(items)}")
        except Exception as e:
            logger.error(f"Diagnoses cache read error: {e}")
    ts = vitals.get("timestamp") or session.get("created_at", "")
    try:
        ts = datetime.fromisoformat(ts).strftime("%Y-%m-%d %H:%M")
    except Exception:
        pass
    data = {
        "name": user_info["name"],
        "age": str(user_info.get("age", "Unknown")),
        "gender": user_info.get("sex", "Unknown"),
        "clinic_name": "Clinic",
        "date": ts,
        "vitals": {
            "heart_rate": vitals.get("hr", "N/A"),
            "spo2": vitals.get("spo2", "N/A"),
            "blood_pressure": f"{vitals.get('sys', 'N/A')}/{vitals.get('dia', 'N/A')}",
            "temp": vitals.get("temp", "N/A"),
        },
        "ecg_wave": vitals.get("ecg_wave"),
        "ecg": {},
        "assessment": {},
        "recommendations": recs,
    }
    success = printer.print_full_assessment(data)
    if success:
        return {"status": "success"}
    raise HTTPException(status_code=500, detail="Failed to print assessment")


@app.post("/print-ecg")
def print_ecg_strip(req: PrintEcgRequest):
    success = printer.print_ecg_strip_standalone(
        wave_points=req.wave_points,
        heart_rate=req.heart_rate,
        diagnosis=req.diagnosis,
    )
    if success:
        return {"status": "success", "message": "ECG Strip printed successfully"}
    raise HTTPException(status_code=500, detail="Failed to print ECG strip")


# ── Diagnosis helpers ──────────────────────────────────────────────────────────

@app.get("/diagnosis/symptoms")
def get_symptoms():
    """Returns the symptom picker categories shown in the Flutter app."""
    return {
        "categories": [
            {"name": "أعراض القلب والدورة الدموية",
             "symptoms": ["ألم في الصدر", "خفقان القلب", "ضيق في التنفس", "دوخة ودوار", "إغماء"]},
            {"name": "أعراض ضغط الدم",
             "symptoms": ["صداع مستمر", "رؤية ضبابية", "إرهاق وضعف عام"]},
            {"name": "أعراض تنفسية",
             "symptoms": ["سعال", "أزيز بالصدر", "صعوبة في التنفس"]},
            {"name": "أعراض السكري",
             "symptoms": ["عطش شديد", "كثرة التبول", "فقدان الوزن"]},
            {"name": "أعراض أخرى", "symptoms": []},
        ]
    }


@app.post("/diagnosis/extract-symptoms")
def extract_symptoms(req: ExtractSymptomsRequest):
    import llm as _llm
    found = _llm.extract_symptoms(req.text)
    if not found:
        found.append("أعراض مخصصة (من الصوت)")
    return {"symptoms": found}


@app.post("/diagnosis/speak")
def speak_text(req: SpeakRequest):
    tts.synthesize_speech(req.text)
    return {"status": "ok"}


# ── WebSocket streaming ────────────────────────────────────────────────────────

@app.websocket("/ws/{session_id}/{user_id}")
async def websocket_chat(websocket: WebSocket, session_id: str, user_id: int):
    await websocket.accept()
    logger.info(f"WebSocket open — user={user_id}, session={session_id}")
    try:
        while True:
            data = await websocket.receive_json()
            agent_output = None
            user_msg = ""

            if data.get("type") == "text":
                user_msg = data.get("message", "")
                led_controller.set_led_state("THINKING")
                agent_output = agent.run_agent_turn(user_id, session_id, user_msg)
                db.save_chat_message(session_id, "user", user_msg)
                db.save_chat_message(session_id, "agent", agent_output["response"])
                db.update_session_step(session_id, agent_output["next_action"])

            elif data.get("type") == "sensor_data":
                s = data.get("data", {})
                hr, spo2 = s.get("hr", 72), s.get("spo2", 98)
                sys_v, dia_v, temp = s.get("sys"), s.get("dia"), s.get("temp")
                is_critical = vitals_check.evaluate_vitals(
                    hr=hr, spo2=spo2, sys=sys_v, dia=dia_v, temp=temp
                )
                db.save_vitals(user_id, session_id, hr, spo2, sys_v, dia_v, temp, is_critical)
                user_msg = (
                    f"تم إدخال العلامات الحيوية: "
                    f"ضغط: {sys_v}/{dia_v} mmHg, نبض: {hr} bpm, "
                    f"أكسجين: {spo2}%, حرارة: {temp}°C."
                )
                led_controller.set_led_state("THINKING")
                agent_output = agent.run_agent_turn(user_id, session_id, user_msg)
                db.save_chat_message(session_id, "user", "[تم قياس المؤشرات الحيوية تلقائياً]")
                db.save_chat_message(session_id, "agent", agent_output["response"])
                db.update_session_step(session_id, agent_output["next_action"])

            if agent_output:
                text_response = agent_output["response"]
                sentences = []
                current: list = []
                for ch in text_response:
                    current.append(ch)
                    if ch in (".", "،", "?", "!", "\n"):
                        s = "".join(current).strip()
                        if s:
                            sentences.append(s)
                        current = []
                if current:
                    s = "".join(current).strip()
                    if s:
                        sentences.append(s)
                if not sentences:
                    sentences = [text_response]

                led_controller.set_led_state("SPEAKING")
                for sent in sentences:
                    await websocket.send_json({"type": "sentence", "text": sent})

                await websocket.send_json({
                    "type": "done",
                    "next_action": agent_output["next_action"],
                    "urgency": agent_output["urgency"],
                    "theme_state": agent_output.get("theme_state", "normal"),
                    "options": agent_output.get("options", []),
                    "differential_diagnoses": agent_output.get("differential_diagnoses", []),
                    "control_command": agent_output.get("control_command", "NONE"),
                })

                if agent_output.get("urgency") == "high" or \
                        agent_output.get("theme_state") == "emergency":
                    led_controller.set_led_state("ALERT_HIGH")
                else:
                    led_controller.set_led_state("IDLE")

    except WebSocketDisconnect:
        logger.info(f"WebSocket closed — user={user_id}, session={session_id}")
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        await websocket.close()