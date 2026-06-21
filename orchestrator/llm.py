import os, logging, threading

logger = logging.getLogger("llm")

MODEL_PATH  = os.environ.get("LLM_MODEL_PATH", "/home/horria/orchestrator/models/gemma-3-4b-it-Q4_K_M.gguf")

# FORCE 4 threads for your physical i5 cores to maximize CPU performance
CPU_THREADS = int(os.environ.get("LLM_THREADS", "4"))

_llm  = None
_lock = threading.Lock()


def _load_model():
    from llama_cpp import Llama
    logger.info(f"Loading model from {MODEL_PATH} on {CPU_THREADS} threads ...")
    m = Llama(
        model_path = MODEL_PATH,
        n_ctx      = 1024,
        n_threads  = CPU_THREADS,
        n_batch    = 512,
        use_mmap   = True,
        use_mlock  = True,
        low_vram   = True,
        logits_all = False,
        verbose    = False,
    )
    logger.info("Model loaded.")
    return m


def preload():
    global _llm
    with _lock:
        if _llm is None:
            _llm = _load_model()


def get_llm():
    global _llm
    if _llm is None:
        with _lock:
            if _llm is None:
                _llm = _load_model()
    return _llm


def chat(system_prompt, user_message, max_tokens=512, temperature=0.3, top_p=0.9):
    try:
        out = get_llm().create_chat_completion(
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user",   "content": user_message},
            ],
            max_tokens=max_tokens, temperature=temperature, top_p=top_p, stream=False,
        )
        return out["choices"][0]["message"]["content"].strip()
    except Exception as e:
        logger.error(f"Error querying local llama_cpp model: {e}")
        return _generate_fallback_response()


def chat_with_history(system_prompt, history, user_message, max_tokens=512, temperature=0.3):
    try:
        messages = [{"role": "system", "content": system_prompt}] + history + [{"role": "user", "content": user_message}]
        out = get_llm().create_chat_completion(messages=messages, max_tokens=max_tokens, temperature=temperature, stream=False)
        return out["choices"][0]["message"]["content"].strip()
    except Exception as e:
        logger.error(f"Error querying local llama_cpp model: {e}")
        return _generate_fallback_response()


def _generate_fallback_response() -> str:
    import json
    resp_obj = {
        "response": "عذراً، أواجه مشكلة في تشغيل نموذج الذكاء الاصطناعي المحلي.",
        "options": [],
        "next_action": "CONTINUE_CHAT",
        "differential_diagnoses": []
    }
    return json.dumps(resp_obj, ensure_ascii=False)


def extract_symptoms(arabic_text):
    system = (
        "انت مساعد طبي متخصص. مهمتك استخراج الاعراض الطبية فقط من كلام المريض. "
        "اجب بقائمة نقطية باللغة العربية فقط، كل عرض في سطر يبدا بشرطة. "
        "لا تضف اي تفسير او كلام اضافي."
    )
    raw = chat(system, f"استخرج الاعراض من النص التالي:\n{arabic_text}", max_tokens=256, temperature=0.2)
    return [l.strip().lstrip("-•* ").strip() for l in raw.splitlines() if l.strip().lstrip("-•* ").strip()]


def analyze_vitals(vitals):
    system = (
        "أنت دكتورة حورية، طبيبة جادة ومباشرة جداً. "
        "حللي المؤشرات الحيوية المقدمة فوراً في سطرين فقط وبدون أي مقدمات أو ترحيب أو مجاملات."
    )
    user = (
        f"العلامات الحيوية:\n"
        f"- النبض: {vitals.get('hr', 'غير متاح')} نبضة/دقيقة\n"
        f"- اكسجين الدم: {vitals.get('spo2', 'غير متاح')}%\n"
        f"- ضغط الدم: {vitals.get('sys', '---')}/{vitals.get('dia', '---')} mmHg\n"
        f"- الحرارة: {vitals.get('temp', 'غير متاح')}°C"
    )
    return chat(system, user, max_tokens=120, temperature=0.2)
