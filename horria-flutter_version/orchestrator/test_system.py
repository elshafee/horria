"""
Dr. Horria — System Integration Test
=====================================
Run with: ./venv/bin/python test_system.py [--skip-nim]

Tests:
  1. DB initialization — all tables exist
  2. LLM smoke test — NIM chat model responds
  3. OCR smoke test — NIM vision model parses test_lab.png
  4. DB write/read — lab results saved with timestamps
  5. Agent turn — diagnosis agent responds with valid JSON schema
  6. Vitals evaluation — critical/normal classification
  7. AHA RAG — guideline lookup by BP
  8. LED controller — state transitions without crash
"""
import sys
import json
import os
import traceback

# ── Color output helpers ───────────────────────────────────────────────────────
GREEN  = "\033[92m"
RED    = "\033[91m"
YELLOW = "\033[93m"
BOLD   = "\033[1m"
RESET  = "\033[0m"

SKIP_NIM = "--skip-nim" in sys.argv  # pass flag to skip expensive API calls

results = []

def run_test(name: str, fn):
    try:
        fn()
        print(f"  {GREEN}✓ PASS{RESET}  {name}")
        results.append((name, "PASS", None))
    except Exception as e:
        print(f"  {RED}✗ FAIL{RESET}  {name}")
        print(f"         {RED}{e}{RESET}")
        results.append((name, "FAIL", str(e)))

def skip_test(name: str, reason: str = ""):
    print(f"  {YELLOW}– SKIP{RESET}  {name}  ({reason})")
    results.append((name, "SKIP", reason))

# ── 1. DB initialization ───────────────────────────────────────────────────────
print(f"\n{BOLD}[1] Database Initialization{RESET}")

def test_db_init():
    import db
    conn = db.get_db_connection()
    tables = {
        row[0] for row in conn.execute(
            "SELECT name FROM sqlite_master WHERE type='table'"
        ).fetchall()
    }
    conn.close()
    required = {"users", "sessions", "vitals", "lab_results", "medical_history", "chat_history"}
    missing = required - tables
    assert not missing, f"Missing tables: {missing}"

run_test("All required DB tables exist", test_db_init)

# ── 2. LLM smoke test ─────────────────────────────────────────────────────────
print(f"\n{BOLD}[2] LLM Smoke Test (NIM Chat Model){RESET}")

if SKIP_NIM:
    skip_test("NIM chat model responds", "--skip-nim flag set")
else:
    def test_llm_smoke():
        import llm
        response = llm.chat(
            system_prompt="You are a helpful assistant. Respond only in JSON.",
            user_message="Say hello in JSON format: {\"greeting\": \"...\"}",
            max_tokens=64,
        )
        assert response and len(response) > 2, f"Empty response: {response!r}"
        # Must be parseable JSON or at least contain a brace
        assert "{" in response or len(response) > 5, f"Unexpected response: {response!r}"

    run_test("NIM chat model responds", test_llm_smoke)

# ── 3. OCR smoke test ─────────────────────────────────────────────────────────
print(f"\n{BOLD}[3] OCR Smoke Test (NIM Vision Model){RESET}")

TEST_IMAGE = os.path.join(os.path.dirname(__file__), "..", "test_lab.png")

if SKIP_NIM:
    skip_test("NIM vision model parses test_lab.png", "--skip-nim flag set")
elif not os.path.exists(TEST_IMAGE):
    skip_test("NIM vision model parses test_lab.png", "test_lab.png not found at ../test_lab.png")
else:
    def test_ocr_smoke():
        import ocr_pipeline
        result = ocr_pipeline.run_lab_scan_ocr(image_path=TEST_IMAGE)
        assert isinstance(result, dict), f"Expected dict, got {type(result)}"
        for key in ("laboratory", "patient", "timestamps", "test_categories"):
            assert key in result, f"Missing key: {key}"
        cats = result["test_categories"]
        assert isinstance(cats, list) and len(cats) > 0, "test_categories is empty"
        # Validate first test has required fields
        first_test = cats[0]["tests"][0]
        for field in ("name", "result", "flag"):
            assert field in first_test, f"Test missing field: {field}"

    run_test("NIM vision model parses test_lab.png", test_ocr_smoke)

# ── 4. DB write / read for lab results ────────────────────────────────────────
print(f"\n{BOLD}[4] DB Lab Result Write / Read{RESET}")

def test_db_lab_write_read():
    import db, time
    conn = db.get_db_connection()
    # Ensure test user exists
    user = conn.execute("SELECT id FROM users LIMIT 1").fetchone()
    if not user:
        conn.execute(
            "INSERT INTO users (name, phone, password_hash, age, sex) "
            "VALUES ('Test User', '00000000', '', 30, 'male')"
        )
        conn.commit()
        user = conn.execute("SELECT id FROM users LIMIT 1").fetchone()
    user_id = user[0]

    # Ensure test session exists
    sess_id = "test_system_session"
    existing = conn.execute("SELECT id FROM sessions WHERE id = ?", (sess_id,)).fetchone()
    if not existing:
        conn.execute(
            "INSERT INTO sessions (id, user_id, created_at) VALUES (?, ?, datetime('now'))",
            (sess_id, user_id),
        )
        conn.commit()
    conn.close()

    # Use a unique name so we can find it regardless of limit ordering
    unique_name = f"TEST_MARKER_{int(time.time())}"
    db.save_lab_result(
        user_id=user_id,
        session_id=sess_id,
        test_name=unique_name,
        value="5.6",
        flag="Normal",
        timestamp="01-06-2026 11:31:00",
    )
    # Query directly from DB to verify
    conn = db.get_db_connection()
    row = conn.execute(
        "SELECT * FROM lab_results WHERE test_name = ? AND timestamp = ?",
        (unique_name, "01-06-2026 11:31:00"),
    ).fetchone()
    conn.close()
    assert row is not None, f"Written record not found in DB for name={unique_name}"
    assert dict(row)["flag"] == "Normal"

run_test("Lab result saved with specimen timestamp and retrieved correctly", test_db_lab_write_read)

# ── 5. Agent turn ──────────────────────────────────────────────────────────────
print(f"\n{BOLD}[5] Agent Diagnosis Turn{RESET}")

if SKIP_NIM:
    skip_test("Agent returns valid response schema", "--skip-nim flag set")
else:
    def test_agent_turn():
        import db, agent

        conn = db.get_db_connection()
        user = conn.execute("SELECT id FROM users LIMIT 1").fetchone()
        conn.close()
        assert user, "No users in DB — run DB test first"
        user_id = user[0]

        response = agent.run_agent_turn(
            user_id=user_id,
            session_id="test_system_session",
            user_message="ظهرت نتائج تحاليلي، هل يمكنك مراجعتها؟",
        )
        required_keys = {"response", "next_action", "urgency", "theme_state",
                         "options", "differential_diagnoses", "control_command"}
        missing = required_keys - set(response.keys())
        assert not missing, f"Agent response missing keys: {missing}"
        assert response["response"], "Agent response text is empty"
        valid_actions = {"CONTINUE_CHAT", "GO_TO_VITALS_SCREEN",
                         "SHOW_EMERGENCY_ALERT", "SHOW_DIAGNOSES"}
        assert response["next_action"] in valid_actions, \
            f"Unexpected next_action: {response['next_action']}"

    run_test("Agent returns valid response schema", test_agent_turn)

# ── 6. Vitals evaluation ───────────────────────────────────────────────────────
print(f"\n{BOLD}[6] Vitals Evaluation Logic{RESET}")

def test_vitals_normal():
    from vitals_check import evaluate_vitals
    assert evaluate_vitals(hr=72, spo2=98, sys=120, dia=78, temp=36.8) is False

def test_vitals_critical_spo2():
    from vitals_check import evaluate_vitals
    assert evaluate_vitals(hr=72, spo2=85, sys=120, dia=78, temp=36.8) is True

def test_vitals_critical_bp():
    from vitals_check import evaluate_vitals
    assert evaluate_vitals(hr=72, spo2=98, sys=185, dia=115, temp=36.8) is True

def test_vitals_critical_hr():
    from vitals_check import evaluate_vitals
    assert evaluate_vitals(hr=150, spo2=98, sys=120, dia=78, temp=36.8) is True

def test_vitals_none_fields():
    from vitals_check import evaluate_vitals
    # Partial readings (some sensors not connected) should not crash
    assert isinstance(evaluate_vitals(hr=None, spo2=None, sys=None, dia=None, temp=None), bool)

run_test("Normal vitals → not critical", test_vitals_normal)
run_test("SpO2 85% → critical", test_vitals_critical_spo2)
run_test("BP 185/115 → critical", test_vitals_critical_bp)
run_test("HR 150 → critical", test_vitals_critical_hr)
run_test("All-None vitals → no crash", test_vitals_none_fields)

# ── 7. AHA RAG guideline lookup ────────────────────────────────────────────────
print(f"\n{BOLD}[7] AHA RAG Guideline Lookup{RESET}")

def test_rag_normal_bp():
    from rag import search_aha_guideline
    result = search_aha_guideline("فحص ضغط الدم", sys=115, dia=75)
    assert "طبيعي" in result.lower() or "Normal" in result

def test_rag_crisis():
    from rag import search_aha_guideline
    result = search_aha_guideline("ضغط دم مرتفع", sys=190, dia=125)
    assert "أزمة" in result or "Crisis" in result or "حادة" in result

def test_rag_no_bp():
    from rag import search_aha_guideline
    result = search_aha_guideline("ما هي أعراض الضغط؟")
    assert isinstance(result, str) and len(result) > 10

run_test("RAG: Normal BP → normal classification", test_rag_normal_bp)
run_test("RAG: BP 190/125 → hypertensive crisis", test_rag_crisis)
run_test("RAG: no BP params → keyword fallback", test_rag_no_bp)

# ── 8. LED controller ──────────────────────────────────────────────────────────
print(f"\n{BOLD}[8] LED Controller State Transitions{RESET}")

def test_led_all_states():
    import led_controller
    states = ["IDLE", "LISTENING", "THINKING", "SPEAKING",
              "SUCCESS", "ERROR", "ALERT_HIGH", "ALERT_MEDIUM", "MEASURING"]
    for state in states:
        result = led_controller.set_led_state(state)
        assert result is True, f"set_led_state({state!r}) returned False"
    assert led_controller.get_current_led_state() == "MEASURING"

def test_led_invalid_state():
    import led_controller
    result = led_controller.set_led_state("INVALID_STATE_XYZ")
    assert result is False, "Invalid state should return False"

run_test("All valid LED states transition without crash", test_led_all_states)
run_test("Invalid LED state returns False", test_led_invalid_state)

# ── Summary ────────────────────────────────────────────────────────────────────
passed = sum(1 for _, s, _ in results if s == "PASS")
failed = sum(1 for _, s, _ in results if s == "FAIL")
skipped = sum(1 for _, s, _ in results if s == "SKIP")
total = len(results)

print(f"\n{BOLD}{'='*55}")
print(f" Test Summary: {passed}/{total} passed, {failed} failed, {skipped} skipped")
print(f"{'='*55}{RESET}\n")

if failed > 0:
    print(f"{RED}Failed tests:{RESET}")
    for name, status, err in results:
        if status == "FAIL":
            print(f"  • {name}: {err}")
    sys.exit(1)
else:
    print(f"{GREEN}All tests passed!{RESET}\n")
    sys.exit(0)
