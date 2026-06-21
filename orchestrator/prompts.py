# Medical History Questionnaire configuration
# Per screen flow step 3: questionnaire dynamically rendered from this schema.

MEDICAL_HISTORY_QUESTIONS_AR = [
    {
        "id": "hypertension",
        "type": "segmented",
        "question": "هل تعاني من ارتفاع ضغط الدم؟",
        "options": ["نعم", "لا"]
    },
    {
        "id": "diabetes",
        "type": "segmented",
        "question": "هل تعاني من مرض السكري؟",
        "options": ["نعم", "لا"]
    },
    {
        "id": "heart_disease",
        "type": "segmented",
        "question": "هل تعاني من أي أمراض في القلب؟",
        "options": ["نعم", "لا"]
    },
    {
        "id": "allergies",
        "type": "chips",
        "question": "هل لديك حساسية من أي من الأطعمة أو الأدوية التالية؟",
        "options": ["البنسلين", "القمح", "المكسرات", "اللاكتوز", "لا يوجد حساسية"]
    },
    {
        "id": "notes",
        "type": "text",
        "question": "اكتب أي ملاحظات طبية أو أمراض أخرى تعاني منها هنا:"
    }
]

MEDICAL_HISTORY_QUESTIONS_EN = [
    {
        "id": "hypertension",
        "type": "segmented",
        "question": "Do you have high blood pressure?",
        "options": ["Yes", "No"]
    },
    {
        "id": "diabetes",
        "type": "segmented",
        "question": "Do you have diabetes?",
        "options": ["Yes", "No"]
    },
    {
        "id": "heart_disease",
        "type": "segmented",
        "question": "Do you have any heart diseases?",
        "options": ["Yes", "No"]
    },
    {
        "id": "allergies",
        "type": "chips",
        "question": "Do you have allergies to any of the following?",
        "options": ["Penicillin", "Wheat", "Nuts", "Lactose", "No allergies"]
    },
    {
        "id": "notes",
        "type": "text",
        "question": "Write any other medical notes or conditions here:"
    }
]

AGENT_SYSTEM_PROMPT = """أنت دكتورة حورية، مساعدة طبية ذكية.
القواعد:
1. اسألي المريض باختصار شديد.
2. إذا احتجت لفحص، اطلبي العلامات الحيوية.
3. يجب أن يكون الرد JSON فقط. "response" جملة أو جملتين كحد أقصى.

صيغة JSON المطلوبة:
{{
  "response": "ردك القصير جداً بالعربية",
  "options": ["خيار1", "خيار2"],
  "next_action": "CONTINUE_CHAT" أو "GO_TO_VITALS_SCREEN" أو "SHOW_EMERGENCY_ALERT" أو "SHOW_DIAGNOSES",
  "control_command": "START_LEPU_BP" (إذا طلبت فحص الضغط) أو "NONE",
  "theme_state": "normal" أو "emergency",
  "urgency": "normal" أو "high",
  "differential_diagnoses": [
    {{
      "condition": "اسم المرض",
      "probability_text": "احتمالية عالية",
      "percentage": 90,
      "symptoms": ["أعراض مطابقة"],
      "recommendations": [
        {{"title": "العيادة", "items": ["الباطنة"], "type": "clinic"}},
        {{"title": "تحاليل", "items": ["CBC"], "type": "labtests"}},
        {{"title": "أشعة", "items": ["ECG"], "type": "measurements"}}
      ]
    }}
  ]
}}

معلومات المريض:
الاسم: {name}، العمر: {age}، الجنس: {sex}
التاريخ الطبي: {medical_history}
العلامات الحيوية الحالية: {vitals_context}
السياق الطبي الإرشادي: {aha_guidelines_context}
"""
