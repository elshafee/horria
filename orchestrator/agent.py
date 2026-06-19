import json
import logging
import db
import prompts
import llm_client
import rag

logger = logging.getLogger("agent")

def run_agent_turn(user_id: int, session_id: str, user_message: str) -> dict:
    """
    Retrieves user history context, queries AHA RAG guidelines, builds prompt,
    queries the LLM, and returns a structured clinical JSON response containing SDUI metadata.
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
            "sdui_components": []
        }
        
    medical_history = db.get_medical_history(user_id)
    history_str = ", ".join([f"{h['question_id']}: {h['answer']}" for h in medical_history]) if medical_history else "لا يوجد سجل طبي مدون."
    
    vitals_history = db.get_vitals_history(user_id, limit=1)
    sys_val = None
    dia_val = None
    
    if vitals_history:
        v = vitals_history[0]
        sys_val = v.get('sys')
        dia_val = v.get('dia')
        vitals_ctx = f"التاريخ: {v['timestamp']}, نبض: {v['hr']} bpm, أكسجين: {v['spo2']}%, ضغط: {v['sys']}/{v['dia']} mmHg, حرارة: {v['temp']}°C. (حرج: {'نعم' if v['is_critical'] else 'لا'})"
    else:
        vitals_ctx = "لا توجد قياسات علامات حيوية سابقة."
        
    labs_history = db.get_lab_history(user_id, limit=5)
    if labs_history:
        labs_ctx = "\n".join([f"- {l['test_name']}: {l['value']} (الحالة: {l['flag']})" for l in labs_history])
    else:
        labs_ctx = "لا توجد نتائج تحاليل معملية سابقة."

    # 2. Query AHA Guidelines RAG Database
    aha_guidelines = rag.search_aha_guideline(user_message, sys=sys_val, dia=dia_val)

    # 3. Build final prompt from template
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
    
    # Append the user's message context
    formatted_prompt += f"\n\nPATIENT MESSAGE: {user_message}\nRESPONSE JSON:"
    
    # 4. Query LLM
    llm_output = llm_client.query_llm(formatted_prompt)
    
    # 5. Parse JSON response
    try:
        # Strip code fences if present
        cleaned_output = llm_output.strip()
        
        # Strip <think> blocks which some reasoning models inject
        import re
        cleaned_output = re.sub(r'<think>.*?</think>', '', cleaned_output, flags=re.DOTALL).strip()
        
        if cleaned_output.startswith("```"):
            cleaned_output = cleaned_output.split("\n", 1)[1]
        if cleaned_output.endswith("```"):
            cleaned_output = cleaned_output.rsplit("\n", 1)[0]
        cleaned_output = cleaned_output.strip()
        
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
            
        return parsed_response
    except Exception as e:
        logger.error(f"Failed to parse LLM JSON output. Raw output: {llm_output}. Error: {e}")
        # Secure fallback response
        return {
            "response": "عذراً، أواجه مشكلة في معالجة طلبك حالياً. هل تشعر بأي أعراض طارئة؟",
            "options": ["نعم", "لا"],
            "next_action": "CONTINUE_CHAT",
            "urgency": "normal",
            "theme_state": "normal",
            "differential_diagnoses": []
        }
