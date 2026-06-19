import logging
import tempfile
import os
import asyncio
import subprocess
import threading
import base64

logger = logging.getLogger("tts")

VOICE_AR = "ar-EG-SalmaNeural"
VOICE_EN = "en-US-AriaNeural"
ALSA_DEVICE = "plughw:0,3"


async def _generate_speech_async(text: str, voice: str, output_path: str):
    import edge_tts
    communicate = edge_tts.Communicate(text, voice)
    await communicate.save(output_path)


def _generate_blocking(text: str, voice: str, output_path: str):
    try:
        loop = asyncio.get_running_loop()
        import concurrent.futures
        with concurrent.futures.ThreadPoolExecutor() as pool:
            future = pool.submit(asyncio.run, _generate_speech_async(text, voice, output_path))
            future.result(timeout=30)
    except RuntimeError:
        asyncio.run(_generate_speech_async(text, voice, output_path))


_play_lock = threading.Lock()

def _play_blocking(file_path: str):
    with _play_lock:
        try:
            cmd = f"ffmpeg -i '{file_path}' -f wav - 2>/dev/null | aplay -D {ALSA_DEVICE}"
            subprocess.run(cmd, shell=True)
        except Exception as e:
            logger.error(f"Playback error: {e}")
        finally:
            if os.path.exists(file_path):
                os.remove(file_path)


def synthesize_and_play(text: str, lang: str = "ar") -> str:
    if not text or not text.strip():
        return ""
    logger.info(f"TTS: lang={lang}, text={text[:60]}")
    voice = VOICE_AR if lang == "ar" else VOICE_EN
    with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as f:
        output_path = f.name
    def run():
        try:
            _generate_blocking(text, voice, output_path)
            _play_blocking(output_path)
        except Exception as e:
            logger.error(f"TTS thread error: {e}")
            if os.path.exists(output_path):
                os.remove(output_path)
    threading.Thread(target=run, daemon=False).start()
    return ""


def synthesize_speech(text: str, lang: str = "ar") -> str:
    return synthesize_and_play(text, lang)


def synthesize_to_base64(text: str, lang: str = "ar") -> str:
    if not text or not text.strip():
        return ""
    voice = VOICE_AR if lang == "ar" else VOICE_EN
    with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as f:
        output_path = f.name
    try:
        _generate_blocking(text, voice, output_path)
        if not os.path.exists(output_path) or os.path.getsize(output_path) == 0:
            return ""
        with open(output_path, "rb") as f:
            audio_bytes = f.read()
        return base64.b64encode(audio_bytes).decode("utf-8")
    except Exception as e:
        logger.error(f"TTS base64 error: {e}")
        return ""
    finally:
        if os.path.exists(output_path):
            os.remove(output_path)