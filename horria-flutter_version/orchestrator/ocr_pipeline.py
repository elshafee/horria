"""
NVIDIA NIM Vision OCR pipeline for Dr. Horria.
Scans a lab report image (from hardware scanner or file path) and returns
a structured JSON object conforming to the Horria lab schema.
"""
import subprocess
import os
import logging
import time
import tempfile
import base64
import requests
import json

from config import NIM_API_KEY, NIM_BASE_URL, NIM_VISION_MODEL

logger = logging.getLogger("ocr_pipeline")

SCAN_OUTPUT_DIR = os.getenv("HORRIA_SCAN_OUTPUT_DIR", "/home/horria-backend/data/scans")
FALLBACK_SCAN_OUTPUT_DIR = os.path.join(tempfile.gettempdir(), "horria_scans")

# Vision API timeout — 90B model generating full JSON can take up to 3 minutes
_VISION_TIMEOUT = 240


def scan_document(device: str = None) -> str | None:
    """
    Trigger the hardware flatbed scanner.
    Returns the saved image path on success, or None if scanning fails.
    """
    try:
        os.makedirs(SCAN_OUTPUT_DIR, exist_ok=True)
        scan_output_dir = SCAN_OUTPUT_DIR
    except OSError as e:
        logger.warning(
            f"Cannot use {SCAN_OUTPUT_DIR}: {e}. Falling back to {FALLBACK_SCAN_OUTPUT_DIR}."
        )
        os.makedirs(FALLBACK_SCAN_OUTPUT_DIR, exist_ok=True)
        scan_output_dir = FALLBACK_SCAN_OUTPUT_DIR

    ts = int(time.time())
    output_path = os.path.join(scan_output_dir, f"scan_{ts}.png")
    cmd = ["scanimage", "--format=png", "--resolution", "300", "-o", output_path]
    if device:
        cmd += ["-d", device]

    try:
        subprocess.run(cmd, check=True, capture_output=True, timeout=120)
        logger.info(f"Scan saved to {output_path}")
        return output_path
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, FileNotFoundError) as e:
        logger.error(f"Scan failed: {e}")
        return None


def _encode_image(image_path: str) -> tuple[str, str]:
    """Return (base64_string, mime_type) for the given image file."""
    ext = image_path.rsplit(".", 1)[-1].lower()
    mime_type = f"image/{ext}" if ext in ("jpg", "jpeg", "png", "webp") else "image/jpeg"
    with open(image_path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8"), mime_type


def _extract_json_object(text: str) -> dict | None:
    """
    Robustly extract the first complete JSON object from `text` using brace counting.
    Handles cases where the model wraps the JSON in markdown or adds trailing text.
    """
    start = text.find("{")
    if start == -1:
        return None
    stack = 0
    for i in range(start, len(text)):
        if text[i] == "{":
            stack += 1
        elif text[i] == "}":
            stack -= 1
            if stack == 0:
                try:
                    return json.loads(text[start : i + 1])
                except json.JSONDecodeError:
                    pass
    return None


_OCR_PROMPT = (
    "You are an expert medical data extraction AI. "
    "Please act as an OCR and carefully read the laboratory test results from this image. "
    "Extract the data and return it STRICTLY as a JSON object matching the following schema. "
    "Do not include markdown code blocks or any other text.\n\n"
    "EXPECTED SCHEMA:\n"
    "{\n"
    "  \"laboratory\": {\"name_en\": string, \"name_ar\": string, \"subtitle_en\": string, \"subtitle_ar\": string},\n"
    "  \"branch\": {\"branch_name\": string, \"manager\": string, \"unit_manager\": string, \"unit_physician\": string, \"additional_physician\": string},\n"
    "  \"management\": {\"chairman\": string, \"laboratory_manager\": string},\n"
    "  \"patient\": {\"name\": {\"ar\": string, \"en\": string}, \"visit_number\": string, \"age\": {\"value\": number, \"unit\": string}, \"gender\": string, \"client_id\": string, \"referred_by\": string},\n"
    "  \"timestamps\": {\"registered\": string, \"collected\": string, \"authenticated\": string, \"printed\": string},\n"
    "  \"test_categories\": [\n"
    "    {\n"
    "      \"category\": string,\n"
    "      \"tests\": [\n"
    "        {\n"
    "          \"name\": string,\n"
    "          \"result\": number or string,\n"
    "          \"unit\": string or null,\n"
    "          \"reference_range\": object mapping labels to ranges "
    "(e.g. {\"normal\": \"< 5.7\", \"prediabetes\": \"5.7 - 6.4\"}). "
    "NEVER use a multiline string — always break into an object if multiple ranges exist,\n"
    "          \"flag\": string (e.g. 'Normal', 'High', 'Low'). "
    "YOU MUST INFER THIS based on result vs reference range — do not leave null,\n"
    "          \"previous_result\": string or null\n"
    "        }\n"
    "      ]\n"
    "    }\n"
    "  ],\n"
    "  \"assay_method\": {\"method\": string, \"note\": string},\n"
    "  \"report\": {\"page\": string, \"signed_by\": {\"name\": string, \"title\": string}}\n"
    "}\n\n"
    "CRITICAL: Be incredibly precise. Extract everything exactly as written in the image. "
    "You MUST output the full JSON including assay_method and report at the bottom."
)


def extract_lab_results_with_nim(image_path: str) -> dict:
    """
    Send `image_path` to the NVIDIA NIM 90B vision model.
    Returns the parsed lab report dict, or an empty dict on failure.
    """
    logger.info(f"Sending {image_path} to NIM Vision API ({NIM_VISION_MODEL})...")
    try:
        b64_image, mime_type = _encode_image(image_path)
    except Exception as e:
        logger.error(f"Failed to encode image: {e}")
        return {}

    headers = {
        "Authorization": f"Bearer {NIM_API_KEY}",
        "Accept": "application/json",
    }
    payload = {
        "model": NIM_VISION_MODEL,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": _OCR_PROMPT},
                    {
                        "type": "image_url",
                        "image_url": {"url": f"data:{mime_type};base64,{b64_image}"},
                    },
                ],
            }
        ],
        "max_tokens": 4096,
        "temperature": 0.1,
    }

    try:
        response = requests.post(
            f"{NIM_BASE_URL}/chat/completions",
            headers=headers,
            json=payload,
            timeout=_VISION_TIMEOUT,
        )
    except requests.exceptions.RequestException as e:
        logger.error(f"NIM Vision API request failed: {e}")
        return {}

    if response.status_code != 200:
        logger.error(f"NIM Vision API error {response.status_code}: {response.text}")
        return {}

    content = response.json()["choices"][0]["message"]["content"].strip()
    result = _extract_json_object(content)
    if result and isinstance(result, dict):
        return result

    logger.error(f"NIM Vision returned non-dict or unparseable JSON. Raw: {content[:300]}")
    return {}


def run_lab_scan_ocr(image_path: str = None) -> dict:
    """
    Main entry point for lab OCR.
    If `image_path` is provided, uses it directly (for testing).
    Otherwise, triggers the hardware scanner.
    Returns the structured lab report dict, or empty dict on failure.
    """
    if image_path:
        logger.info(f"Using provided image path: {image_path}")
    else:
        logger.info("Triggering hardware scanner...")
        image_path = scan_document()

    if not image_path:
        logger.error("No image available for OCR (scanner failed and no path provided).")
        return {}

    return extract_lab_results_with_nim(image_path)
