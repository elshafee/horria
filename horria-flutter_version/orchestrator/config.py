"""
Shared configuration constants for the Dr. Horria orchestrator.
All NVIDIA NIM credentials and model identifiers live here.
"""

# NVIDIA NIM API
NIM_API_KEY = "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"
NIM_BASE_URL = "https://integrate.api.nvidia.com/v1"

# Vision model: used by ocr_pipeline for reading lab report images
NIM_VISION_MODEL = "meta/llama-3.2-90b-vision-instruct"

# Chat model: used by llm.py for diagnosis conversation and symptom extraction
NIM_CHAT_MODEL = "openai/gpt-oss-20b"
