"""
Dr. Horria diagnosis agent.
Retrieves full patient context from the database, queries AHA RAG guidelines,
builds a structured system prompt, and invokes the NIM LLM to return a
clinical JSON response.
"""
import json
import logging
import re

import db
import prompts
import llm
import rag

logger = logging.getLogger("agent")


def run_agent_turn(user_id: int, session_id: str, user_message: str) -> dict:
    """
    Run a single agent turn for the given patient.

    Returns a dict conforming to the Horria agent response schema:
      {response, options, next_action, control_command, theme_state,
       urgency, differential_diagnoses}
    """
    logger.info(f"Agent turn — user={user_id}, session={session_id}")

    # --- 1. Fetch patient context ---
    user_info = db.get_user_by_id(user_id)
    if not user_info:
        return _error_response("عذراً، لم أتمكن من العثور على ملفك الشخصي.")

    medical_history = db.get_medical_history(user_id)
    history_str = (
        ", ".join(f"{h['question_id']}: {h['answer']}" for h in medical_history)
        if medical_history
        else "لا يوجد سجل طبي مدون."
    )

    session_vitals = db.get_vitals_by_session(session_id)
    sys_val = dia_val = None
    if session_vitals:
        v = session_vitals
        sys_val = v.get("sys")
        dia_val = v.get("dia")
        parts = []
        if v.get("hr") is not None:
            parts.append(f"نبض: {v['hr']} bpm")
        if v.get("spo2") is not None:
            parts.append(f"أكسجين: {v['spo2']}%")
        if sys_val is not None and dia_val is not None:
            parts.append(f"ضغط: {sys_val}/{dia_val} mmHg")
        if v.get("temp") is not None:
            parts.append(f"حرارة: {v['temp']}°C")
        crit = "نعم" if v.get("is_critical") else "لا"
        vitals_ctx = (
            f"التاريخ: {v['timestamp']}, {', '.join(parts)}. (حرج: {crit})"
            if parts
            else "لا توجد قياسات علامات حيوية سابقة."
        )
    else:
        vitals_ctx = "لا توجد قياسات علامات حيوية سابقة."

    labs_history = db.get_lab_history(user_id, limit=50)
    labs_ctx = (
        "\n".join(
            f"- {l['test_name']}: {l['value']} (الحالة: {l['flag']}) [تاريخ العينة: {l['timestamp']}]"
            for l in labs_history
        )
        if labs_history
        else "لا توجد نتائج تحاليل معملية سابقة."
    )

    # --- 2. AHA guideline RAG lookup ---
    aha_guidelines = rag.search_aha_guideline(user_message, sys=sys_val, dia=dia_val)

    # --- 3. Build system prompt ---
    system_prompt = prompts.AGENT_SYSTEM_PROMPT.format(
        name=user_info["name"],
        age=user_info["age"],
        sex=user_info["sex"],
        language=user_info.get("preferred_language") or "ar",
        medical_history=history_str,
        vitals_context=vitals_ctx,
        labs_context=labs_ctx,
        aha_guidelines_context=aha_guidelines,
    )

    # --- 4. Build chat history (last 8 turns to fit context window) ---
    raw_history = db.get_chat_history(session_id)[-8:]
    chat_history = [
        {"role": "assistant" if h["sender"] == "agent" else "user", "content": h["message"]}
        for h in raw_history
    ]

    user_prompt = f"PATIENT MESSAGE: {user_message}\n\nRESPOND ONLY IN PURE JSON FORMAT."

    # --- 5. Query NIM LLM ---
    llm_output = llm.chat_with_history(system_prompt, chat_history, user_prompt)

    # --- 6. Parse JSON response ---
    return _parse_llm_output(llm_output)


def _parse_llm_output(raw: str) -> dict:
    """
    Parse the LLM's raw string output into a validated response dict.
    Strips <think> tags, markdown fences, and attempts JSON recovery
    if the model truncated its output.
    """
    cleaned = raw.strip()

    # Remove any chain-of-thought reasoning block
    cleaned = re.sub(r"<think>.*?</think>", "", cleaned, flags=re.DOTALL).strip()

    # Strip markdown code fences
    if cleaned.startswith("```"):
        cleaned = cleaned.split("\n", 1)[1] if "\n" in cleaned else cleaned[3:]
    if cleaned.endswith("```"):
        cleaned = cleaned.rsplit("\n", 1)[0]
    cleaned = cleaned.strip()

    # Attempt to extract the first complete JSON object via brace counting
    start = cleaned.find("{")
    if start != -1:
        stack = 0
        for i in range(start, len(cleaned)):
            if cleaned[i] == "{":
                stack += 1
            elif cleaned[i] == "}":
                stack -= 1
                if stack == 0:
                    try:
                        parsed = json.loads(cleaned[start : i + 1])
                        return _apply_defaults(parsed)
                    except json.JSONDecodeError:
                        break

    # Last resort: try to parse as-is
    try:
        parsed = json.loads(cleaned)
        return _apply_defaults(parsed)
    except Exception:
        logger.error(f"Failed to parse LLM JSON. Raw output (first 300): {raw[:300]}")
        return _error_response("عذراً، أواجه مشكلة في صياغة الإجابة حالياً. هل تشعر بأي أعراض طارئة؟")


def _apply_defaults(parsed: dict) -> dict:
    """Ensure all required fields are present with safe defaults."""
    parsed.setdefault("options", [])
    parsed.setdefault("differential_diagnoses", [])
    parsed.setdefault("theme_state", "normal")
    parsed.setdefault("urgency", "normal")
    parsed.setdefault("next_action", "CONTINUE_CHAT")
    parsed.setdefault("control_command", "NONE")
    return parsed


def _error_response(message: str) -> dict:
    return {
        "response": message,
        "options": ["نعم", "لا"],
        "next_action": "CONTINUE_CHAT",
        "urgency": "normal",
        "theme_state": "normal",
        "control_command": "NONE",
        "differential_diagnoses": [],
    }
