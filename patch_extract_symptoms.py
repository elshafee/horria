import re

with open("orchestrator/main.py", "r") as f:
    content = f.read()

new_endpoint = """
class ExtractSymptomsRequest(BaseModel):
    session_id: str
    text: str

@app.post("/diagnosis/extract-symptoms")
def extract_symptoms(req: ExtractSymptomsRequest):
    # Temporary mock until local LLM extraction is added
    logger.info(f"Extracting symptoms from: {req.text}")
    # Mock behavior: if patient says something containing 'ألم في الصدر' it adds it.
    found_symptoms = []
    if "صدر" in req.text:
        found_symptoms.append("ألم في الصدر")
    if "دوار" in req.text or "دوخة" in req.text:
        found_symptoms.append("دوخة ودوار")
    if "كحة" in req.text or "سعال" in req.text:
        found_symptoms.append("سعال")
    
    if not found_symptoms:
        # Just echo a dummy symptom to show it works
        found_symptoms.append("أعراض مخصصة (من الصوت)")
        
    return {"symptoms": found_symptoms}
"""

if "ExtractSymptomsRequest" not in content:
    content = content.replace("class StartDiagnosisRequest", new_endpoint + "\nclass StartDiagnosisRequest")
    with open("orchestrator/main.py", "w") as f:
        f.write(content)
    print("Extract endpoint added.")
else:
    print("Endpoint already exists.")
