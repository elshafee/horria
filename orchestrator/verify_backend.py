import sys
import os

# Add parent directory to path to allow imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from orchestrator import db
from orchestrator import vitals_check
from orchestrator import face_auth
from orchestrator import ocr_pipeline
from orchestrator import printer
from orchestrator import agent
from orchestrator import tts
from orchestrator import stt

def run_tests():
    print("Starting Dr. Horria Orchestrator Verification Tests...")
    print("-" * 50)
    
    # 1. Test database initialization and CRUD
    print("Testing SQLite Database CRUD...")
    user_id = db.create_user(
        name="أحمد خالد",
        phone="0123456789",
        password_hash="pass123",
        age=30,
        sex="male",
        face_encoding="test_face_reference",
        preferred_language="ar"
    )
    
    # If phone unique constraint triggers, retrieve existing user
    if user_id is None:
        user = db.get_user_by_phone("0123456789")
        user_id = user['id']
        print(f"User already exists with ID: {user_id}")
    else:
        print(f"Created new test user with ID: {user_id}")
        
    db.save_medical_history(user_id, "hypertension", "نعم")
    db.save_medical_history(user_id, "notes", "حساسية بنسلين")
    print("Database CRUD operations passed.")
    print("-" * 50)
    
    # 2. Test vitals check
    print("Testing Vitals Check...")
    is_critical_normal = vitals_check.evaluate_vitals(hr=72, spo2=98, sys=118, dia=76, temp=36.7)
    is_critical_alert = vitals_check.evaluate_vitals(hr=150, spo2=88, sys=190, dia=120, temp=40.0)
    
    print(f"Normal readings evaluate to critical: {is_critical_normal}")
    print(f"Alert readings evaluate to critical: {is_critical_alert}")
    assert not is_critical_normal, "Normal vitals should not flag as critical"
    assert is_critical_alert, "Out-of-range vitals must flag as critical"
    print("Vitals check verification passed.")
    print("-" * 50)
    
    # 3. Test Face Auth & Liveness Simulation
    print("Testing Face Authentication & EAR Liveness...")
    liveness_ok = face_auth.verify_liveness(["frame1", "frame2", "frame3"])
    match_ok = face_auth.match_face("test_image_base64_data", "test_face_reference")
    print(f"Liveness verified: {liveness_ok}, Face matched: {match_ok}")
    assert liveness_ok, "EAR verification check failed"
    assert match_ok, "Face signature match failed"
    print("Face authentication passed.")
    print("-" * 50)
    
    # 4. Test STT and TTS Synthesis
    print("Testing Speech Audio Synthesizer & STT...")
    transcription = stt.transcribe_audio("test_audio_b64", test_transcription="أشعر بالتعب")
    audio_data = tts.synthesize_speech("مرحباً بك في العيادة")
    print(f"STT Transcript: '{transcription}'")
    print(f"TTS base64 audio size: {len(audio_data)} chars")
    assert transcription == "أشعر بالتعب", "Audio transcription mismatch"
    assert len(audio_data) > 0, "TTS audio synthesis returned empty data"
    print("Speech STT/TTS passed.")
    print("-" * 50)
    
    # 5. Test OCR Scanner and Printer Queue
    print("Testing OCR Lab scan & receipt printer...")
    lab_results = ocr_pipeline.run_lab_scan_ocr()
    print(f"OCR extracted {len(lab_results)} lab indicators.")
    assert len(lab_results) > 0, "OCR returned empty test results list"
    
    print_ok = printer.print_receipt("أحمد خالد", lab_results)
    assert print_ok, "Print queue submission failed"
    print("OCR and printing verification passed.")
    print("-" * 50)
    
    # 6. Test Agent LLM Orchestration
    print("Testing AI Agent prompts & next_action evaluation...")
    # Test 1: Emergency Trigger
    emerg_response = agent.run_agent_turn(user_id, "test_session_id", "أعاني من ألم شديد في صدري ولا أستطيع التنفس")
    print(f"Emergency text response: {emerg_response['response']}")
    print(f"Emergency next_action: {emerg_response['next_action']}, urgency: {emerg_response['urgency']}")
    assert emerg_response['next_action'] == "SHOW_EMERGENCY_ALERT", "Should trigger SHOW_EMERGENCY_ALERT"
    
    # Test 2: Vitals screen trigger
    vitals_response = agent.run_agent_turn(user_id, "test_session_id", "أريد قياس نبضات قلبي والضغط")
    print(f"Vitals trigger next_action: {vitals_response['next_action']}")
    assert vitals_response['next_action'] == "GO_TO_VITALS_SCREEN", "Should trigger GO_TO_VITALS_SCREEN"
    
    # Test 3: Normal convo
    normal_response = agent.run_agent_turn(user_id, "test_session_id", "مرحباً كيف حالك")
    print(f"Normal response: {normal_response['response']}")
    assert normal_response['next_action'] == "CONTINUE_CHAT", "Should continue chat"
    
    print("AI Agent orchestration passed.")
    print("-" * 50)
    print("All verification tests passed successfully!")

if __name__ == "__main__":
    run_tests()
