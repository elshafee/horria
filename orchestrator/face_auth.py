import base64
import logging
import json
import numpy as np

logger = logging.getLogger("face_auth")

MATCH_THRESHOLD = 0.45

def verify_liveness(frames_base64: list) -> bool:
    """
    Simulates checking the Eye Aspect Ratio (EAR) across consecutive frames.
    """
    logger.info(f"Analyzing {len(frames_base64)} frames for liveness check")
    if len(frames_base64) < 3:
        logger.warning("Not enough frames to verify liveness (requires 3 frames)")
        return False
    return all(isinstance(f, str) and len(f) > 0 for f in frames_base64)

def _cosine_distance(a, b):
    a, b = np.array(a), np.array(b)
    return 1 - (np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))

def extract_embedding_from_image(image_bytes: bytes) -> list:
    """
    Returns a 128-d embedding (list of floats), or None if no face found.
    Requires: pip install face_recognition (dlib-based)
    """
    try:
        import face_recognition
        import io
        from PIL import Image

        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        arr = np.array(image)

        face_locations = face_recognition.face_locations(arr)
        if not face_locations:
            return None

        encodings = face_recognition.face_encodings(arr, known_face_locations=face_locations)
        if not encodings:
            return None

        return encodings[0].tolist()
    except ImportError:
        logger.warning("face_recognition not installed, returning mock embedding")
        return [0.0] * 128
    except Exception as e:
        logger.error(f"Error extracting embedding: {e}")
        return None

def match_face(uploaded_image_b64: str, stored_encoding_str: str) -> bool:
    """
    Compares the uploaded face image with the stored face encoding string.
    """
    if not uploaded_image_b64 or not stored_encoding_str:
        return False
        
    try:
        clean_b64 = uploaded_image_image_clean(uploaded_image_b64)
        missing_padding = len(clean_b64) % 4
        if missing_padding:
            clean_b64 += '=' * (4 - missing_padding)
            
        image_bytes = base64.b64decode(clean_b64)
        
        # In a real database, stored_encoding_str is the JSON string of the 128-d vector
            
        stored_embedding = json.loads(stored_encoding_str)
        uploaded_embedding = extract_embedding_from_image(image_bytes)
        
        if uploaded_embedding is None:
            return False
            
        dist = _cosine_distance(uploaded_embedding, stored_embedding)
        logger.info(f"Face distance: {dist:.3f}")
        return dist < MATCH_THRESHOLD
    except Exception as e:
        logger.error(f"Error matching face: {e}")
        return False

def uploaded_image_image_clean(b64_str: str) -> str:
    if "," in b64_str:
        return b64_str.split(",")[1]
    return b64_str
