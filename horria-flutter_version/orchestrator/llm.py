"""
NVIDIA NIM LLM client for Dr. Horria diagnosis chat and symptom extraction.
Uses the text-only NIM_CHAT_MODEL — NOT the vision model (that is in ocr_pipeline.py).
"""
import json
import logging
import requests

from config import NIM_API_KEY, NIM_BASE_URL, NIM_CHAT_MODEL

logger = logging.getLogger("llm")

# Shared request timeout — NIM text models respond within 30s under normal load
_TIMEOUT = 90


def _nim_post(messages: list, max_tokens: int = 1024, temperature: float = 0.3) -> str:
    """
    Internal helper: POST a chat-completions request to NVIDIA NIM.
    Returns the raw content string, or a safe JSON fallback on any error.
    """
    headers = {
        "Authorization": f"Bearer {NIM_API_KEY}",
        "Accept": "application/json"
    }
    payload = {
        "model": NIM_CHAT_MODEL,
        "messages": messages,
        "max_tokens": max_tokens,
        "temperature": temperature,
    }
    try:
        res = requests.post(
            f"{NIM_BASE_URL}/chat/completions",
            headers=headers,
            json=payload,
            timeout=_TIMEOUT,
        )
        if res.status_code == 200:
            data = res.json()
            message = data["choices"][0]["message"]
            content = message.get("content") or message.get("reasoning_content")
            if not content:
                logger.error(f"NIM returned empty content: {data}")
                return _fallback_json()
            return content.strip()
        else:
            logger.error(f"NIM API error {res.status_code}: {res.text}")
            return _fallback_json()
    except Exception as e:
        logger.error(f"NIM request failed: {e}")
        return _fallback_json()


def _fallback_json() -> str:
    return json.dumps({
        "response": "عذراً، أواجه مشكلة في تشغيل نموذج الذكاء الاصطناعي.",
        "options": [],
        "next_action": "CONTINUE_CHAT",
        "differential_diagnoses": []
    }, ensure_ascii=False)


def chat(system_prompt: str, user_message: str,
         max_tokens: int = 1024, temperature: float = 0.3) -> str:
    """Single-turn chat with a system and user message."""
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_message},
    ]
    return _nim_post(messages, max_tokens=max_tokens, temperature=temperature)


def chat_with_history(system_prompt: str, history: list, user_message: str,
                      max_tokens: int = 1024, temperature: float = 0.3) -> str:
    """Multi-turn chat. `history` is a list of {role, content} dicts."""
    messages = (
        [{"role": "system", "content": system_prompt}]
        + history
        + [{"role": "user", "content": user_message}]
    )
    return _nim_post(messages, max_tokens=max_tokens, temperature=temperature)


def extract_symptoms(arabic_text: str) -> list:
    """Extract a list of medical symptoms from a free-form Arabic patient utterance."""
    system = (
        "انت مساعد طبي متخصص. مهمتك استخراج الاعراض الطبية فقط من كلام المريض. "
        "اجب بقائمة نقطية باللغة العربية فقط، كل عرض في سطر يبدا بشرطة. "
        "لا تضف اي تفسير او كلام اضافي."
    )
    raw = chat(system, f"استخرج الاعراض من النص التالي:\n{arabic_text}",
               max_tokens=256, temperature=0.2)
    return [
        line.strip().lstrip("-•* ").strip()
        for line in raw.splitlines()
        if line.strip().lstrip("-•* ").strip()
    ]


def analyze_vitals(vitals: dict) -> str:
    """Return a brief Arabic clinical summary of the provided vitals dict."""
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
