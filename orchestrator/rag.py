import logging

logger = logging.getLogger("rag")

AHA_DATABASE = [
    {
        "stage": "Normal",
        "sys_range": (0, 119),
        "dia_range": (0, 79),
        "classification": "طبيعي (Normal)",
        "advice": "ضغط الدم في المعدل السليم. حافظ على نمط حياة صحي ونظام غذائي متوازن ومارس الرياضة بانتظام.",
        "drugs": "لا توجد دواعي لاستخدام أدوية الضغط حالياً."
    },
    {
        "stage": "Elevated",
        "sys_range": (120, 129),
        "dia_range": (0, 79),
        "classification": "مرتفع قليلاً (Elevated)",
        "advice": "ضغط الدم مرتفع قليلاً عن المعدل الطبيعي. ينصح بالحد من تناول الصوديوم (الملح)، وممارسة التمارين الرياضية بانتظام ومراقبة الضغط.",
        "drugs": "لا ينصح ببدء علاج دوائي في هذه المرحلة عادةً، بل يوصى بتعديل نمط الحياة."
    },
    {
        "stage": "Stage 1 Hypertension",
        "sys_range": (130, 139),
        "dia_range": (80, 89),
        "classification": "ارتفاع ضغط الدم - الدرجة الأولى (Stage 1)",
        "advice": "أنت تعاني من ارتفاع ضغط الدم من الدرجة الأولى وفقاً لجمعية القلب الأمريكية. يرجى استشارة الطبيب وإجراء الفحوصات الدورية.",
        "drugs": "قد يصف الطبيب مدرات البول الثيازيدية (Thiazide Diuretics) أو حاصرات مستقبلات الأنجيوتنسين (ARBs) أو مثبطات الإنزيم المحول للأنجيوتنسين (ACE inhibitors)."
    },
    {
        "stage": "Stage 2 Hypertension",
        "sys_range": (140, 300),
        "dia_range": (90, 200),
        "classification": "ارتفاع ضغط الدم - الدرجة الثانية (Stage 2)",
        "advice": "أنت تعاني من ارتفاع ضغط الدم من الدرجة الثانية. ينصح بحجز موعد مع طبيب القلب فوراً لتقييم الحالة وتعديل العلاج لتفادي المضاعفات.",
        "drugs": "غالباً ما يتم وصف علاج مركب يحتوي على نوعين من الأدوية مثل (Lisinopril + Amlodipine) أو حاصرات بيتا (Beta Blockers)."
    },
    {
        "stage": "Hypertensive Crisis",
        "sys_range": (180, 500),
        "dia_range": (120, 300),
        "classification": "أزمة ارتفاع ضغط الدم الحادة (Hypertensive Crisis)",
        "advice": "تحذير: أنت في مرحلة أزمة ضغط دم حادة وتتطلب تدخل طبي طارئ! التزم الهدوء تاماً، وسنقوم بالاتصال بالإسعاف لمساعدتك فوراً.",
        "drugs": "يتطلب علاجاً فورياً بالأدوية الوريدية داخل المستشفى تحت الرعاية الطبية المركزة (مثل Labetalol أو Nitroprusside)."
    }
]

def search_aha_guideline(query: str, sys: int = None, dia: int = None) -> str:
    """
    Simulates searching the AHA guideline guidelines based on symptoms query and blood pressure parameters.
    """
    logger.info(f"RAG AHA Guidelines search requested. Query: '{query}', BP: {sys}/{dia}")
    
    # Check BP staging directly if parameters are provided
    if sys is not None and dia is not None:
        # Hypertensive Crisis takes highest precedence
        if sys >= 180 or dia >= 120:
            match = AHA_DATABASE[4]
        # Stage 2 Hypertension
        elif sys >= 140 or dia >= 90:
            match = AHA_DATABASE[3]
        # Stage 1 Hypertension
        elif (130 <= sys <= 139) or (80 <= dia <= 89):
            match = AHA_DATABASE[2]
        # Elevated
        elif (120 <= sys <= 129) and dia < 80:
            match = AHA_DATABASE[1]
        # Normal
        else:
            match = AHA_DATABASE[0]
            
        result = (
            f"التصنيف الطبي وفق إرشادات جمعية القلب الأمريكية (AHA):\n"
            f"- التصنيف: {match['classification']}\n"
            f"- التوصية الطبية: {match['advice']}\n"
            f"- الأدوية المقترحة: {match['drugs']}"
        )
        return result

    # Fallback semantic keyword keyword search for general inquiries
    query_lower = query.lower()
    if any(k in query_lower for k in ["أدوية", "علاج", "دواء", "drug", "medicine", "medication"]):
        return (
            "إرشادات جمعية القلب الأمريكية (AHA) للأدوية:\n"
            "- لارتفاع ضغط الدم البسيط: يفضل استخدام مدرات البول أو مثبطات ACE (مثل Lisinopril).\n"
            "- للمرضى الذين يعانون من أمراض شرايين تاجية مصاحبة: ينصح بحاصرات بيتا (Beta Blockers).\n"
            "- يمنع استخدام حاصرات مستقبلات الأنجيوتنسين (ARBs) ومثبطات ACE معاً."
        )
        
    return (
        "إرشادات جمعية القلب الأمريكية العامة:\n"
        "- الحفاظ على وزن صحي وممارسة الرياضة 150 دقيقة أسبوعياً.\n"
        "- اتباع حمية DASH الغذائية (الغنية بالفواكه والخضروات والحبوب الكاملة والمنخفضة الصوديوم)."
    )
