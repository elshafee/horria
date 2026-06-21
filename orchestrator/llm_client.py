import os
import json
import logging
import requests

logger = logging.getLogger("llm_client")

API_URL = "https://router.huggingface.co/v1/chat/completions"
# Using Qwen 2.5 72B because it is the absolute best open source model for Arabic text and JSON formatting.
HF_MODEL = "google/gemma-3-4b-it:featherless-ai"

HF_TOKEN = "hf_jwt_eyJhbGciOiJIUzI1NiJ9.eyJwZXJtaXNzaW9ucyI6eyJpbmZlcmVuY2Uuc2VydmVybGVzcy53cml0ZSI6dHJ1ZX0sIm9uQmVoYWxmT2YiOnsia2luZCI6InVzZXIiLCJfaWQiOiI2OTU3ZjEwZTgwMTJjODhjMDYzMDNlNWEiLCJ1c2VyIjoiYWhtYWRlbHNoYWZlZSIsInNlc3Npb25JZCI6IjZhMzRiMmYwMzVlMmMwZGI1YTIyNzJjNSJ9LCJpYXQiOjE3ODE4Mzg3MjQsImp0aSI6IjVmYzA1NGRiLWYyMDQtNGJkMi04MWMyLTA5NGQwN2FhOWY3YiIsInN1YiI6Imh0dHBzOi8vcm91dGVyLmh1Z2dpbmdmYWNlLmNvIiwiZXhwIjoxNzgxODQyMzI0LCJpc3MiOiJodHRwczovL2h1Z2dpbmdmYWNlLmNvIn0.HtJvobzjOzM5vqD7hTQp4E8MkgfGt2g9UfQlehOKL-g"

def query_llm(prompt: str) -> str:
    """
    Sends a query prompt to the HuggingFace Serverless Inference API.
    """
    logger.info(f"Querying HuggingFace Cloud API model: {HF_MODEL}")
    
    headers = {
        "Authorization": f"Bearer {HF_TOKEN}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "model": HF_MODEL,
        "messages": [
            {
                "role": "user",
                "content": prompt
            }
        ],
        "temperature": 0.3,
        "max_tokens": 1024,
        "stream": False
    }
    
    try:
        response = requests.post(API_URL, headers=headers, json=payload, timeout=60)
        response.raise_for_status()
        result = response.json()
        
        # Extract the assistant's text reply from the Chat Completions format
        if "choices" in result and len(result["choices"]) > 0:
            return result["choices"][0]["message"]["content"]
        else:
            logger.error(f"Unexpected response format from HF: {result}")
            return _generate_fallback_response()
            
    except requests.exceptions.RequestException as e:
        logger.error(f"Error querying HuggingFace API: {e}")
        return _generate_fallback_response()

def _generate_fallback_response() -> str:
    """
    Secure fallback JSON if the Cloud API is unreachable.
    """
    resp_obj = {
        "response": "عذراً، أواجه مشكلة في الاتصال بالخادم السحابي للذكاء الاصطناعي. يرجى التحقق من اتصال الإنترنت.",
        "options": [],
        "next_action": "CONTINUE_CHAT",
        "differential_diagnoses": []
    }
    return json.dumps(resp_obj, ensure_ascii=False)
