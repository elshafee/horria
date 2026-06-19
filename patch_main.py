import re

with open("orchestrator/main.py", "r") as f:
    content = f.read()

new_endpoints = """
# --- Diagnosis APIs ---
from typing import List, Dict, Any

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

"""

if "# --- Diagnosis APIs ---" not in content:
    content = content.replace("# WebSockets Endpoint", new_endpoints + "\n# WebSockets Endpoint")
    with open("orchestrator/main.py", "w") as f:
        f.write(content)
    print("Endpoints added.")
else:
    print("Endpoints already exist.")

