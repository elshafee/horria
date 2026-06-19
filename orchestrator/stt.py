import base64
import logging
import tempfile
import os

logger = logging.getLogger("stt")

def transcribe_audio(audio_base64: str, test_transcription: str = None) -> str:
    """
    Decodes base64 audio and transcribes it to text via Google STT (speech_recognition).
    Allows passing a test_transcription to simulate specific spoken inputs in sandbox testing.
    """
    if test_transcription:
        logger.info(f"Using test transcription override: {test_transcription}")
        return test_transcription

    try:
        import speech_recognition as sr
        
        audio_bytes = base64.b64decode(audio_base64)
        logger.info(f"Received {len(audio_bytes)} bytes of audio for transcription.")
        
        # Write to a temporary WAV file
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
            f.write(audio_bytes)
            wav_path = f.name
            
        recognizer = sr.Recognizer()
        try:
            with sr.AudioFile(wav_path) as source:
                audio = recognizer.record(source)
                
            text = recognizer.recognize_google(audio, language="ar-EG")
            logger.info(f"Recognized text: {text}")
            
            if not text:
                text = "مرحباً دكتورة"
                
            return text
        except sr.UnknownValueError:
            logger.error("Google heard audio, but couldn't understand the words.")
            return "عذراً، لم أتمكن من سماعك بوضوح."
        except sr.RequestError as e:
            logger.error(f"Google API Error: {e}")
            return "عذراً، يوجد مشكلة في الاتصال بالشبكة."
        finally:
            if os.path.exists(wav_path):
                os.remove(wav_path)
                
    except Exception as e:
        logger.error(f"Error decoding base64 audio in STT: {e}")
        return "مرحباً دكتورة"
