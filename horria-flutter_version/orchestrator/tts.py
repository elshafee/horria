import platform
import logging
import tempfile
import os
import asyncio
import subprocess
import threading
import base64
import qalsadi.analex as qala
from pyarabic import araby

logger = logging.getLogger("tts")

VOICE_AR = "ar-EG-SalmaNeural"
VOICE_EN = "en-US-AriaNeural"


def _find_alsa_device():
    if platform.system() == "Darwin":
        return "default"
    try:
        output = subprocess.check_output(["aplay", "-l"], text=True, stderr=subprocess.DEVNULL)
        lines = output.split('\n')
        cards = []
        for line in lines:
            if line.startswith("card "):
                parts = line.split(',')
                card_part = parts[0]
                device_part = parts[1] if len(parts) > 1 else ""
                card_num = card_part.split(':')[0].replace("card ", "").strip()
                device_num = device_part.split(':')[0].replace("device ", "").strip()
                cards.append({'card': card_num, 'device': device_num, 'desc': line.lower()})

        if not cards:
            return "default"

        usb_cards = [c for c in cards if 'usb' in c['desc']]
        if usb_cards:
            return f"plughw:{usb_cards[0]['card']},{usb_cards[0]['device']}"

        analog_cards = [c for c in cards if 'hdmi' not in c['desc']]
        if analog_cards:
            return f"plughw:{analog_cards[0]['card']},{analog_cards[0]['device']}"

        return f"plughw:{cards[0]['card']},{cards[0]['device']}"
    except Exception as e:
        logger.error(f"Error finding ALSA device: {e}")
        return "default"


ALSA_DEVICE = _find_alsa_device()


async def _generate_speech_async(text: str, voice: str, output_path: str):
    import edge_tts
    communicate = edge_tts.Communicate(text, voice)
    await communicate.save(output_path)


def _generate_blocking(text: str, voice: str, output_path: str):
    import threading

    def _run_in_thread():
        asyncio.run(_generate_speech_async(text, voice, output_path))

    try:
        loop = asyncio.get_running_loop()
        t = threading.Thread(target=_run_in_thread)
        t.start()
        t.join(timeout=30)
    except RuntimeError:
        asyncio.run(_generate_speech_async(text, voice, output_path))


_play_lock = threading.Lock()
_latest_tts_id = 0
_latest_tts_lock = threading.Lock()

def _play_blocking(file_path: str, tts_id: int):
    # Quick check before acquiring the lock
    with _latest_tts_lock:
        if tts_id != _latest_tts_id:
            if os.path.exists(file_path):
                os.remove(file_path)
            return

    with _play_lock:
        # Check again after acquiring lock
        with _latest_tts_lock:
            if tts_id != _latest_tts_id:
                if os.path.exists(file_path):
                    os.remove(file_path)
                return
        try:
            if platform.system() == "Darwin":
                subprocess.run(["afplay", file_path])
            else:
                cmd = f"ffmpeg -i '{file_path}' -f wav - 2>/dev/null | aplay -D {ALSA_DEVICE}"
                subprocess.run(cmd, shell=True)
        except Exception as e:
            logger.error(f"Playback error: {e}")
        finally:
            if os.path.exists(file_path):
                os.remove(file_path)


def _add_tashkeel(text: str) -> str:
    """Generates diacritics/harakat for plain Arabic text using Qalsadi."""
    try:
        analyzer = qala.Analex()
        # check_text returns a list of objects containing vocalized/analyzed words
        analysis_results = analyzer.check_text(text)

        vocalized_words = []
        for word_list in analysis_results:
            if word_list:
                # Take the vocalized form from the analyzed object
                vocalized_words.append(word_list[0].vocalized)
            else:
                # Fallback to unvocalized if analysis fails
                vocalized_words.append(word_list)
        return " ".join(vocalized_words)
    except Exception as e:
        logger.warning(f"Failed to generate tashkeel, falling back to original text: {e}")
        return text


def synthesize_and_play(text: str, lang: str = "ar") -> str:
    if not text or not text.strip():
        return ""

    # Edge TTS (SalmaNeural) sounds much more natural and human-like 
    # when it reads plain Arabic without forced diacritics (tashkeel).
    # Removed _add_tashkeel to prevent robotic pronunciation.

    logger.info(f"TTS: lang={lang}, text={text[:60]}")
    voice = VOICE_AR if lang == "ar" else VOICE_EN

    with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as f:
        output_path = f.name

    global _latest_tts_id
    with _latest_tts_lock:
        _latest_tts_id += 1
        current_tts_id = _latest_tts_id

    # Preemptively stop currently playing TTS
    try:
        kill_cmd = ["pkill", "-9", "afplay"] if platform.system() == "Darwin" else ["pkill", "-9", "aplay"]
        subprocess.run(kill_cmd, stderr=subprocess.DEVNULL)
    except Exception:
        pass

    def run():
        try:
            # Check if outdated before generating
            with _latest_tts_lock:
                if current_tts_id != _latest_tts_id:
                    if os.path.exists(output_path):
                        os.remove(output_path)
                    return
                    
            _generate_blocking(text, voice, output_path)
            _play_blocking(output_path, current_tts_id)
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

    # Removed forced tashkeel here as well for natural voice

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