def evaluate_vitals(hr: int = None, spo2: int = None, sys: int = None, dia: int = None, temp: float = None) -> bool:
    """
    Evaluates vitals indicators and determines if the state is critical.
    Allows fields to be None if not all sensors were used in the reading.
    """
    is_critical = False

    # 1. Blood Oxygen (SpO2) Check: Critical if below 90%
    if spo2 is not None and spo2 < 90:
        is_critical = True

    # 2. Heart Rate (HR) Check: Critical if extremely low (< 45) or high (> 140)
    if hr is not None and (hr < 45 or hr > 140):
        is_critical = True

    # 3. Body Temperature Check: Critical if very low (< 35.0) or high (> 39.5)
    if temp is not None and (temp < 35.0 or temp > 39.5):
        is_critical = True

    # 4. Systolic Blood Pressure Check: Critical if sys > 180 (hypertensive crisis) or sys < 80
    if sys is not None and (sys > 180 or sys < 80):
        is_critical = True

    # 5. Diastolic Blood Pressure Check: Critical if dia > 110 or dia < 50
    if dia is not None and (dia > 110 or dia < 50):
        is_critical = True

    return is_critical
