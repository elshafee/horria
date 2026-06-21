import json
import logging
import db
import prompts
import llm
import rag

logger = logging.getLogger("agent")

def run_agent_turn(user_id: int, session_id: str, user_message: str) -> dict:
    """
    Retrieves user history context, queries AHA RAG guidelines, builds prompt,
    queries the LLM with chat history memory, and returns a structured clinical JSON response.
    """
    logger.info(f"Running agent turn for user {user_id}, session {session_id}")
    
    # 1. Fetch context from Database
    user_info = db.get_user_by_id(user_id)
    if not user_info:
        return {
            "response": "عذراً، لم أتمكن من العثور على ملفك الشخصي.",
            "next_action": "CONTINUE_CHAT",
            "urgency": "normal",
            "theme_state": "normal",
            "control_command": "NONE",
            "options": [],
            "differential_diagnoses": []
        }
        
    medical_history = db.get_medical_history(user_id)
    history_str = ", ".join([f"{h['question_id']}: {h['answer']}" for h in medical_history]) if medical_history else "لا يوجد سجل طبي مدون."
    
    session_vitals = db.get_vitals_by_session(session_id)
    sys_val = None
    dia_val = None
    
    if session_vitals:
        v = session_vitals
        sys_val = v.get('sys')
        dia_val = v.get('dia')
        
        # Build vital string safely checking for None
        v_str = []
        if v.get('hr') is not None: v_str.append(f"نبض: {v['hr']} bpm")
        if v.get('spo2') is not None: v_str.append(f"أكسجين: {v['spo2']}%")
        if sys_val is not None and dia_val is not None: v_str.append(f"ضغط: {sys_val}/{dia_val} mmHg")
        if v.get('temp') is not None: v_str.append(f"حرارة: {v['temp']}°C")
        
        if v_str:
            crit_str = 'نعم' if v.get('is_critical') else 'لا'
            vitals_ctx = f"التاريخ: {v['timestamp']}, {', '.join(v_str)}. (حرج: {crit_str})"
        else:
            vitals_ctx = "لا توجد قياسات علامات حيوية سابقة."
    else:
        vitals_ctx = "لا توجد قياسات علامات حيوية سابقة."
        
    labs_history = db.get_lab_history(user_id, limit=5)
    if labs_history:
        labs_ctx = "\n".join([f"- {l['test_name']}: {l['value']} (الحالة: {l['flag']})" for l in labs_history])
    else:
        labs_ctx = "لا توجد نتائج تحاليل معملية سابقة."

    # 2. Query AHA Guidelines RAG Database
    aha_guidelines = rag.search_aha_guideline(user_message, sys=sys_val, dia=dia_val)

    # 3. Build system prompt from template
    formatted_prompt = prompts.AGENT_SYSTEM_PROMPT.format(
        name=user_info['name'],
        age=user_info['age'],
        sex=user_info['sex'],
        language=user_info['preferred_language'] or 'ar',
        medical_history=history_str,
        vitals_context=vitals_ctx,
        labs_context=labs_ctx,
        aha_guidelines_context=aha_guidelines
    )
    
    # 4. Fetch Chat History (last 8 messages for context window safety)
    raw_history = db.get_chat_history(session_id)[-8:]
    chat_history = []
    for h in raw_history:
        role = "assistant" if h['sender'] == 'agent' else "user"
        chat_history.append({"role": role, "content": h['message']})
        
    # Append the JSON rules to the very end of the user message to strictly enforce JSON output
    user_prompt = f"PATIENT MESSAGE: {user_message}\n\nRESPOND ONLY IN PURE JSON FORMAT."

    # 5. Query LLM WITH HISTORY
    llm_output = llm.chat_with_history(formatted_prompt, chat_history, user_prompt)
    
    # 6. Parse JSON response
    try:
        cleaned_output = llm_output.strip()
        
        import re
        cleaned_output = re.sub(r'<think>.*?</think>', '', cleaned_output, flags=re.DOTALL).strip()
        
        if cleaned_output.startswith("```"):
            cleaned_output = cleaned_output.split("\n", 1)[1]
        if cleaned_output.endswith("```"):
            cleaned_output = cleaned_output.rsplit("\n", 1)[0]
        cleaned_output = cleaned_output.strip()
        
        # Sometimes the LLM fails to close the JSON gracefully if it hits max_tokens
        # Fallback if unclosed
        if not cleaned_output.endswith("}"):
            cleaned_output += '"}'
            
        parsed_response = json.loads(cleaned_output)
        
        # Populate defaults if omitted
        if "options" not in parsed_response:
            parsed_response["options"] = []
        if "differential_diagnoses" not in parsed_response:
            parsed_response["differential_diagnoses"] = []
        if "theme_state" not in parsed_response:
            parsed_response["theme_state"] = "normal"
        if "urgency" not in parsed_response:
            parsed_response["urgency"] = "normal"
        if "next_action" not in parsed_response:
            parsed_response["next_action"] = "CONTINUE_CHAT"
        if "control_command" not in parsed_response:
            parsed_response["control_command"] = "NONE"
            
        return parsed_response
    except Exception as e:
        logger.error(f"Failed to parse LLM JSON output. Raw output: {llm_output}. Error: {e}")
        # Secure fallback response
        return {
            "response": "عذراً، أواجه مشكلة في صياغة الإجابة حالياً. هل تشعر بأي أعراض طارئة؟",
            "options": ["نعم", "لا"],
            "next_action": "CONTINUE_CHAT",
            "urgency": "normal",
            "theme_state": "normal",
            "control_command": "NONE",
            "differential_diagnoses": []
        }
