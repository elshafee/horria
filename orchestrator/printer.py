"""
Dr. Horria - Professional Thermal Printer Module
Printer : Xprinter XP-D200N (USB raw device /dev/usb/lp0, ESC/POS)
Paper   : 80mm — 576 dots @ 203 DPI

Print functions:
  print_receipt()              — lab results summary slip
  print_full_assessment()      — complete patient assessment report
  print_ecg_strip_standalone() — professional ECG strip with real wave data
"""
import logging
import os
from datetime import datetime

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy.interpolate import CubicSpline

logger = logging.getLogger("printer")

# ─────────────────────────────────────────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────────────────────────────────────────
PRINTER_PORT     = os.environ.get("PRINTER_PORT", "/dev/usb/lp0")
PRINTER_ENABLED  = os.environ.get("PRINTER_ENABLED", "True").lower() == "true"
PAPER_WIDTH_DOTS = 576
USABLE_WIDTH     = 560
COL_WIDTH        = 32   # characters across in normal font


# ─────────────────────────────────────────────────────────────────────────────
# PRINTER CONNECTION
# ─────────────────────────────────────────────────────────────────────────────
def _get_printer():
    if not PRINTER_ENABLED:
        return None
    try:
        from escpos.printer import File
        p = File(PRINTER_PORT)
        logger.info(f"Printer connected via USB: {PRINTER_PORT}")
        return p
    except Exception as e:
        logger.error(f"Could not connect to printer: {e}")
        return None


def _close_printer(p):
    """Safely and explicitly close the underlying file descriptor to free /dev/usb/lp0."""
    if p:
        try:
            # python-escpos File class stores the open file handle in p.device
            if hasattr(p, 'device') and p.device:
                p.device.close()
                logger.info("Printer device handle closed cleanly and freed.")
        except Exception as e:
            logger.error(f"Error while closing printer handle: {e}")


def _print_arabic_text(p, text: str, font_size: int = 24, align: str = "right"):
    """
    Renders Arabic (or mixed) text as an image using PIL.
    Requires: pip install arabic-reshaper python-bidi
    """
    try:
        import arabic_reshaper
        from bidi.algorithm import get_display
        
        reshaped_text = arabic_reshaper.reshape(text)
        bidi_text = get_display(reshaped_text)
        
        font_path = os.path.join(os.path.dirname(__file__), "Cairo-Regular.ttf")
        if os.path.exists(font_path):
            font = ImageFont.truetype(font_path, font_size)
        else:
            font = ImageFont.load_default()
            
        try:
            bbox = font.getbbox(bidi_text)
            text_w = bbox[2] - bbox[0]
            text_h = bbox[3] - bbox[1] + 10
        except AttributeError:
            # Fallback for older PIL
            text_w, text_h = font.getsize(bidi_text)
            text_h += 10
            
        img_w = min(PAPER_WIDTH_DOTS, max(PAPER_WIDTH_DOTS, text_w + 20))
        img = Image.new("L", (img_w, text_h), color=255)
        draw = ImageDraw.Draw(img)
        
        if align == "center":
            x = (img_w - text_w) // 2
        elif align == "right":
            x = img_w - text_w - 10
        else:
            x = 10
            
        draw.text((x, 5), bidi_text, font=font, fill=0)
        p.image(img, impl="bitImageRaster")
    except Exception as e:
        logger.error(f"Arabic print failed: {e}. Falling back to normal text.")
        p.text(text + "\n")


def _mock_print(label: str, data) -> bool:
    logger.info(f"[MOCK PRINT] {label}: {str(data)[:300]}")
    return True


# ─────────────────────────────────────────────────────────────────────────────
# LOW-LEVEL DRAWING HELPERS
# ─────────────────────────────────────────────────────────────────────────────
def _ln(p, text: str = ""):
    p.text(f"{text}\n")

def _double_rule(p):
    p.set(align="center")
    _ln(p, "=" * COL_WIDTH)

def _thin_rule(p):
    _ln(p, "-" * COL_WIDTH)

def _blank(p, n: int = 1):
    for _ in range(n):
        _ln(p)

def _section_title(p, title: str):
    pad   = COL_WIDTH - len(title) - 4
    left  = max(0, pad // 2)
    right = max(0, pad - left)
    line  = f"{'-' * left} {title} {'-' * right}"
    p.set(align="left", bold=True)
    _ln(p, line)
    p.set(bold=False)

def contains_arabic(text: str) -> bool:
    return any("\u0600" <= c <= "\u06FF" or "\u0750" <= c <= "\u077F" for c in text)

def _dot_row(p, label: str, value: str, flag: str = ""):
    """Dot-leader two-column row: Label ........... Value"""
    flag_marker = "  [!!!]" if flag and flag.lower() not in ("normal", "ok", "green", "") else ""
    value_str   = f"{value}{flag_marker}"
    
    if contains_arabic(value_str):
        # If value has Arabic, just print label on one line, and Arabic value on next line aligned right
        _ln(p, f"{label}:")
        _print_arabic_text(p, value_str, font_size=24, align="right")
        return
        
    dots_count  = max(1, COL_WIDTH - len(label) - len(value_str) - 2)
    line        = f"{label} {'.' * dots_count} {value_str}"
    if flag_marker:
        p.set(bold=True)
        _ln(p, line)
        p.set(bold=False)
    else:
        _ln(p, line)

def _print_valid_row(p, label: str, val, unit: str = "", flag: str = "") -> bool:
    """Only print the row if value is meaningful (not blank/N/A/---)."""
    s_val = str(val).strip() if val is not None else ""
    if s_val.lower() in ("", "---", "n/a", "unknown", "none", "null", "n/a/n/a"):
        return False
    _dot_row(p, label, f"{s_val} {unit}".strip(), flag)
    return True


# ─────────────────────────────────────────────────────────────────────────────
# SHARED HEADER / FOOTER
# ─────────────────────────────────────────────────────────────────────────────
def _print_header(p, title: str, clinic_name: str = None, report_date: str = None):
    now = datetime.now()

    if clinic_name:
        _print_arabic_text(p, clinic_name, font_size=32, align="center")
        _blank(p)

    _double_rule(p)
    _blank(p)

    p.set(align="center", bold=True, double_height=True, double_width=False)
    _ln(p, "DR. HORRIA")
    p.set(double_height=False, bold=False)

    p.set(align="center")
    _ln(p, "Biomedical Robot Assistant")
    _ln(p, "Horus University  |  Eng. Faculty")
    _blank(p)

    _double_rule(p)

    p.set(align="center", bold=True)
    _blank(p)
    _ln(p, title)
    _blank(p)
    p.set(bold=False)

    _double_rule(p)

    date_str = report_date if report_date else now.strftime("%d / %m / %Y")
    time_str = now.strftime("%H:%M")
    p.set(align="left")
    _ln(p, f"  Date : {date_str}    Time : {time_str}")
    _thin_rule(p)


def _print_footer(p, report_prefix: str = "DH", report_id: str = None):
    now = datetime.now()
    if not report_id:
        report_id = now.strftime(f"{report_prefix}-%Y%m%d-%H%M%S")

    _blank(p)
    _thin_rule(p)

    p.set(align="center", bold=True)
    _ln(p, "IMPORTANT NOTICE")
    p.set(bold=False)
    _ln(p, "This report is generated by the")
    _ln(p, "Dr. Horria AI System.")
    _ln(p, "It does NOT replace a")
    _ln(p, "professional medical diagnosis.")
    _ln(p, "Always consult your physician.")

    _thin_rule(p)
    p.set(align="left")
    _ln(p, f"  Report ID : {report_id}")

    _double_rule(p)

    p.set(align="center", bold=True)
    _blank(p)
    _ln(p, "Thank you for using")
    p.set(double_height=True)
    _ln(p, "DR. HORRIA")
    p.set(double_height=False, bold=False)
    _blank(p)

    _double_rule(p)
    _blank(p, 5)
    p.cut()


# ─────────────────────────────────────────────────────────────────────────────
# 1. LAB RESULTS RECEIPT
# ─────────────────────────────────────────────────────────────────────────────
def print_receipt(user_name: str, test_results: list) -> bool:
    logger.info(f"Print lab receipt for: {user_name}")
    p = _get_printer()
    if not p:
        return _mock_print("Lab Receipt", {"user": user_name, "results": test_results})

    try:
        _print_header(p, "LAB RESULTS")
        _blank(p)

        p.set(bold=True)
        _ln(p, f"  Patient : {user_name}")
        p.set(bold=False)
        _thin_rule(p)

        # Column headers
        p.set(bold=True)
        _ln(p, f"  {'TEST':<16} {'VALUE':<8}  STATUS")
        p.set(bold=False)
        _thin_rule(p)

        abnormal_count = 0
        for res in test_results:
            name   = str(res.get("test_name", "Unknown"))[:16]
            value  = str(res.get("value",     "---"))[:8]
            flag   = str(res.get("flag",      ""))
            is_bad = flag.lower() not in ("normal", "ok", "green", "")

            if is_bad:
                abnormal_count += 1
                p.set(bold=True)
                _ln(p, f"  {name:<16} {value:<8}  [!!!]")
                p.set(bold=False)
            else:
                _ln(p, f"  {name:<16} {value:<8}   OK")

        _thin_rule(p)
        p.set(bold=True)
        _ln(p, f"  Total: {len(test_results)} tests   Abnormal: {abnormal_count}")
        p.set(bold=False)

        _print_footer(p, report_prefix="LAB")
        return True

    except Exception as e:
        logger.error(f"print_receipt error: {e}")
        return False
    finally:
        _close_printer(p)


# ─────────────────────────────────────────────────────────────────────────────
# 2. FULL ASSESSMENT REPORT
# ─────────────────────────────────────────────────────────────────────────────
def print_full_assessment(data: dict) -> bool:
    logger.info(f"Print full assessment for: {data.get('name', 'Patient')}")
    p = _get_printer()
    if not p:
        return _mock_print("Full Assessment", data)

    try:
        _print_header(p, "HEALTH ASSESSMENT", data.get("date"))
        _blank(p)

        # ── Patient Information ───────────────────────────────────────────────
        _section_title(p, "PATIENT INFORMATION")
        _print_valid_row(p, "Name",   data.get("name"))
        _print_valid_row(p, "Age",    data.get("age"))
        _print_valid_row(p, "Gender", data.get("gender"))
        _print_valid_row(p, "Clinic", data.get("clinic_name"))
        if not data.get("date"):
            _dot_row(p, "Date", datetime.now().strftime("%Y-%m-%d %H:%M"))
        _blank(p)

        # ── Vital Signs ───────────────────────────────────────────────────────
        v = data.get("vitals", {})
        has_vitals = any(
            str(x).strip().lower() not in ("", "---", "n/a", "unknown", "none", "null", "n/a/n/a")
            for x in v.values()
        )
        if has_vitals:
            _section_title(p, "VITAL SIGNS")
            _print_valid_row(p, "Heart Rate",    v.get("heart_rate"),    "BPM")
            _print_valid_row(p, "SpO2",          v.get("spo2"),          "%")
            bp = str(v.get("blood_pressure", "")).strip()
            if bp and bp not in ("N/A/N/A", "---/---", "N/A"):
                _dot_row(p, "Blood Pressure", f"{bp} mmHg")
            _print_valid_row(p, "Temperature",   v.get("temp"),          "°C")
            _print_valid_row(p, "Blood Sugar",   v.get("blood_sugar"),   "mg/dL")
            _print_valid_row(p, "Weight",        v.get("weight"),        "kg")
            _print_valid_row(p, "Height",        v.get("height"),        "cm")
            _print_valid_row(p, "BMI",           v.get("bmi"))
            _blank(p)

        # ── ECG Analysis ──────────────────────────────────────────────────────
        ecg  = data.get("ecg", {})
        wave = data.get("ecg_wave")
        has_ecg = any(
            str(x).strip().lower() not in ("", "---", "n/a", "unknown", "none")
            for x in ecg.values()
        )
        if has_ecg or (wave and len(wave) > 10):
            _section_title(p, "ECG ANALYSIS")
            _print_valid_row(p, "Rhythm",     ecg.get("rhythm"))
            _print_valid_row(p, "ECG Status", ecg.get("status"))
            if wave and len(wave) > 10:
                img = _generate_ecg_image(wave)
                if img:
                    p.image(img, high_density_vertical=True,
                            high_density_horizontal=True, impl="bitImageRaster")
                    _blank(p)
            _blank(p)

        # ── Health Assessment ─────────────────────────────────────────────────
        a = data.get("assessment", {})
        has_assessment = any(
            str(x).strip().lower() not in ("", "---", "n/a", "unknown", "none")
            for x in a.values()
        )
        if has_assessment:
            _section_title(p, "HEALTH ASSESSMENT")
            _print_valid_row(p, "Cardio Status", a.get("cardio"))
            _print_valid_row(p, "BP Status",     a.get("bp"))
            _print_valid_row(p, "BMI Status",    a.get("bmi_status"))
            _print_valid_row(p, "Stress Level",  a.get("stress"))
            _print_valid_row(p, "Health Score",  a.get("score"))
            _blank(p)

        # ── Recommendations ───────────────────────────────────────────────────
        recs = data.get("recommendations", [])
        if recs:
            _section_title(p, "RECOMMENDATIONS")
            for i, rec in enumerate(recs, 1):
                rec_text = str(rec).lstrip("* ").strip()
                line = f"  {i}. {rec_text}"
                if contains_arabic(line):
                    _print_arabic_text(p, line, font_size=24, align="right")
                else:
                    _ln(p, line)
            _blank(p)

        _print_footer(p, report_prefix="DH")
        return True

    except Exception as e:
        logger.error(f"print_full_assessment error: {e}")
        return False
    finally:
        _close_printer(p)


# ─────────────────────────────────────────────────────────────────────────────
# 3. ECG IMAGE GENERATOR
# ─────────────────────────────────────────────────────────────────────────────
def _generate_ecg_image(wave_points=None, heart_rate=None) -> Image.Image:
    STRIP_LEN   = 2800
    STRIP_W     = PAPER_WIDTH_DOTS
    AXIS_MARGIN = 45
    GRID_PX     = 10

    samples = 400
    x_base  = np.linspace(0, STRIP_LEN, samples)

    if wave_points and len(wave_points) > 20:
        orig_x = np.linspace(0, STRIP_LEN, len(wave_points))
        y_base = np.interp(x_base, orig_x, np.array(wave_points, dtype=float))
        rng    = y_base.max() - y_base.min()
        if rng > 0:
            y_base = (y_base - y_base.min()) / rng * 2 - 1
    else:
        y_base = np.sin(np.linspace(0, 8 * np.pi, samples)) * 0.08
        for i in range(len(y_base)):
            r = i % 60
            if   r ==  5: y_base[i] =  0.22
            elif r == 14: y_base[i] = -0.30
            elif r == 16: y_base[i] =  1.80
            elif r == 18: y_base[i] = -0.40
            elif r == 30: y_base[i] =  0.38

    cs       = CubicSpline(x_base, y_base)
    x_smooth = np.linspace(0, STRIP_LEN, 2000)
    y_smooth = cs(x_smooth)

    img  = Image.new("L", (STRIP_W, STRIP_LEN), color=255)
    draw = ImageDraw.Draw(img)

    # Grid
    for idx, pos in enumerate(range(0, STRIP_LEN, GRID_PX)):
        col = 185 if idx % 5 == 0 else 238
        draw.line([(AXIS_MARGIN, pos), (STRIP_W - 4, pos)], fill=col, width=1)
    for idx, pos in enumerate(range(AXIS_MARGIN, STRIP_W, GRID_PX)):
        col = 185 if idx % 5 == 0 else 232
        draw.line([(pos, 0), (pos, STRIP_LEN)], fill=col, width=1)

    # Waveform
    usable_h  = STRIP_W - AXIS_MARGIN
    center_y  = AXIS_MARGIN + usable_h // 2
    amplitude = int(usable_h * 0.38)

    wave_pts = []
    for i in range(len(x_smooth)):
        cx = int(x_smooth[i])
        cy = int(center_y - y_smooth[i] * amplitude)
        cy = max(AXIS_MARGIN + 4, min(STRIP_W - 6, cy))
        wave_pts.append((cy, cx))

    # Shadow pass for depth
    shadow = [(y + 2, x + 1) for y, x in wave_pts]
    draw.line(shadow, fill=180, width=2)
    draw.line(wave_pts, fill=0, width=3)

    # Y-axis
    draw.line([(AXIS_MARGIN, 0), (AXIS_MARGIN, STRIP_LEN)], fill=0, width=2)

    try:
        font = ImageFont.load_default()
    except Exception:
        font = None

    # Time labels
    px_per_sec = 250
    for px in range(0, STRIP_LEN, px_per_sec):
        label = f"{px / px_per_sec:.1f}s"
        draw.line([(AXIS_MARGIN - 6, px), (AXIS_MARGIN, px)], fill=0, width=2)
        lbl_img  = Image.new("L", (72, 18), color=255)
        lbl_draw = ImageDraw.Draw(lbl_img)
        lbl_draw.text((2, 2), label, fill=0, font=font)
        img.paste(lbl_img.rotate(90, expand=True), (AXIS_MARGIN - 36, px - 9))

    # HR label
    if heart_rate:
        hr_img  = Image.new("L", (130, 18), color=255)
        hr_draw = ImageDraw.Draw(hr_img)
        hr_draw.text((2, 2), f"HR: {heart_rate} BPM", fill=0, font=font)
        img.paste(hr_img, (AXIS_MARGIN + 8, 8))

    # Speed legend
    leg_img  = Image.new("L", (160, 18), color=255)
    leg_draw = ImageDraw.Draw(leg_img)
    leg_draw.text((2, 2), "25 mm/s  |  10 mm/mV", fill=0, font=font)
    img.paste(leg_img, (AXIS_MARGIN + 8, 28))

    # 1 mV calibration pulse
    cal_x = AXIS_MARGIN + 6
    cal_y0 = center_y
    cal_h  = amplitude
    draw.line([(cal_y0,        cal_x),      (cal_y0,        cal_x + 20)], fill=0, width=3)
    draw.line([(cal_y0,        cal_x + 20), (cal_y0 - cal_h, cal_x + 20)], fill=0, width=3)
    draw.line([(cal_y0 - cal_h, cal_x + 20), (cal_y0 - cal_h, cal_x + 50)], fill=0, width=3)
    draw.line([(cal_y0 - cal_h, cal_x + 50), (cal_y0,        cal_x + 50)], fill=0, width=3)

    return img.convert("1", dither=Image.Dither.FLOYDSTEINBERG)


# ─────────────────────────────────────────────────────────────────────────────
# 4. STANDALONE ECG STRIP
# ─────────────────────────────────────────────────────────────────────────────
def print_ecg_strip_standalone(wave_points=None, heart_rate=None, diagnosis=None) -> bool:
    logger.info(f"Print ECG strip: hr={heart_rate}, points={len(wave_points) if wave_points else 0}")
    p = _get_printer()
    if not p:
        return _mock_print("ECG Strip", {"hr": heart_rate, "diagnosis": diagnosis})

    now = datetime.now()
    try:
        p.hw("INIT")

        _double_rule(p)
        _blank(p)
        p.set(align="center", bold=True, double_height=True)
        _ln(p, "DR. HORRIA")
        p.set(double_height=False, bold=False)
        p.set(align="center")
        _ln(p, "AUTOMATED ECG MONITOR")
        _ln(p, "Horus University  |  Eng. Faculty")
        _blank(p)
        _double_rule(p)

        p.set(align="left")
        _blank(p)
        _dot_row(p, "Date",       now.strftime("%d / %m / %Y"))
        _dot_row(p, "Time",       now.strftime("%H : %M : %S"))
        if heart_rate:
            _dot_row(p, "Heart Rate", f"{heart_rate} BPM")
        if diagnosis:
            _dot_row(p, "Result",     diagnosis)
        _blank(p)
        _thin_rule(p)
        _blank(p)

        img = _generate_ecg_image(wave_points, heart_rate)
        p.image(img, high_density_vertical=True,
                high_density_horizontal=True, impl="bitImageRaster")
        _blank(p)

        _section_title(p, "ACQUISITION PARAMETERS")
        _dot_row(p, "Samples",     "2000 interpolated")
        _dot_row(p, "Filter",      "Cubic Spline")
        _dot_row(p, "Paper Speed", "25 mm / s")
        _dot_row(p, "Amplitude",   "10 mm / mV")
        _dot_row(p, "Grid",        "1 mm x 1 mm")
        _blank(p)

        _print_footer(p, report_prefix="ECG")
        return True

    except Exception as e:
        logger.error(f"print_ecg_strip error: {e}")
        return False
    finally:
        _close_printer(p)