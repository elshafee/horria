# Speech and Diacritization APIs Used in Horria

Here is the information regarding the TTS, STT, and Harakat (diacritization) APIs used in this project, which you can use in another app.

## 1. Speech-to-Text (STT)
- **Library:** `SpeechRecognition` (`speech_recognition`)
- **API Engine:** Google Web Speech API (`recognizer.recognize_google`)
- **Language Configured:** Arabic (Egypt) - `"ar-EG"`
- **Python Package:** `SpeechRecognition`
- **Reference File:** `orchestrator/stt.py`

### Code Example (STT)
```python
import base64
import tempfile
import speech_recognition as sr
import os

def transcribe_audio_base64(audio_base64: str) -> str:
    # Decode base64 to audio bytes
    audio_bytes = base64.b64decode(audio_base64)
    
    # Write to a temporary WAV file
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
        f.write(audio_bytes)
        wav_path = f.name
        
    recognizer = sr.Recognizer()
    try:
        with sr.AudioFile(wav_path) as source:
            audio = recognizer.record(source)
            
        # Recognize speech using Google Web Speech API
        text = recognizer.recognize_google(audio, language="ar-EG")
        return text
    except sr.UnknownValueError:
        return "Could not understand audio"
    except sr.RequestError as e:
        return f"Could not request results; {e}"
    finally:
        # Clean up temp file
        if os.path.exists(wav_path):
            os.remove(wav_path)
```

## 2. Text-to-Speech (TTS)
- **Library:** `edge-tts` (`edge_tts`)
- **API Engine:** Microsoft Edge TTS
- **Voices Configured:** 
  - Arabic: `"ar-EG-SalmaNeural"`
  - English: `"en-US-AriaNeural"`
- **Python Package:** `edge-tts`
- **Reference File:** `orchestrator/tts.py`

### Code Example (TTS)
```python
import asyncio
import edge_tts

async def generate_speech_async(text: str, output_path: str, lang: str = "ar"):
    # Select voice based on language
    voice = "ar-EG-SalmaNeural" if lang == "ar" else "en-US-AriaNeural"
    
    # Initialize communicate object and save to file
    communicate = edge_tts.Communicate(text, voice)
    await communicate.save(output_path)

# To run it synchronously in your app:
# asyncio.run(generate_speech_async("مرحباً بك", "output.mp3"))
```

## 3. Harakat / Diacritization (Tashkeel)
- **Library:** `Qalsadi` and `PyArabic`
- **Usage:** Uses `qalsadi.analex` to analyze Arabic text and add diacritics/tashkeel to plain text.
- **Python Packages:** `qalsadi`, `PyArabic`
- **Reference File:** `orchestrator/tts.py` (inside the `_add_tashkeel` function)

### Code Example (Harakat)
```python
import qalsadi.analex as qala

def add_tashkeel(text: str) -> str:
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
        print(f"Failed to generate tashkeel: {e}")
        return text

# Example Usage:
# print(add_tashkeel("مرحبا بك يا صديقي")) 
# Output: مَرْحَبًا بِكَ يَا صَدِيقِي
```

### Note on TTS and Harakat:
The codebase has a note mentioning that `edge-tts` (SalmaNeural voice) actually sounds much more natural and human-like when reading plain Arabic *without* forced diacritics. In `orchestrator/tts.py`, the `_add_tashkeel` function is defined but its usage is currently disabled/bypassed to prevent robotic pronunciation. Keep this in mind when implementing it in your new app!
