import re

with open("orchestrator/main.py", "r") as f:
    content = f.read()

new_endpoint = """
class SpeakRequest(BaseModel):
    text: str

@app.post("/diagnosis/speak")
def speak_text(req: SpeakRequest):
    logger.info(f"Speaking text via TTS: {req.text}")
    from tts import synthesize_speech
    synthesize_speech(req.text, lang="ar")
    return {"status": "ok"}
"""

if "SpeakRequest" not in content:
    content = content.replace("class StartDiagnosisRequest", new_endpoint + "\nclass StartDiagnosisRequest")
    with open("orchestrator/main.py", "w") as f:
        f.write(content)
    print("Speak endpoint added.")
else:
    print("Speak endpoint already exists.")
