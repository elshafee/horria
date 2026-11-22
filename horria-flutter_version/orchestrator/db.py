"""
SQLite database layer for Dr. Horria.
Handles all CRUD for: users, sessions, vitals, lab_results, medical_history, chat_history.
"""
import sqlite3
import os
from datetime import datetime

DB_PATH = os.path.join(os.path.dirname(__file__), "horria.db")


def get_db_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            age INTEGER NOT NULL,
            sex TEXT NOT NULL,
            face_encoding TEXT,
            preferred_language TEXT DEFAULT 'ar'
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS medical_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            question_id TEXT NOT NULL,
            answer TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id)
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS sessions (
            id TEXT PRIMARY KEY,
            user_id INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            resumed INTEGER DEFAULT 0,
            current_step TEXT,
            FOREIGN KEY (user_id) REFERENCES users (id)
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS vitals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            session_id TEXT NOT NULL,
            hr INTEGER,
            spo2 INTEGER,
            sys INTEGER,
            dia INTEGER,
            temp REAL,
            is_critical INTEGER DEFAULT 0,
            ecg_wave TEXT,
            timestamp TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id),
            FOREIGN KEY (session_id) REFERENCES sessions (id)
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS lab_results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            session_id TEXT NOT NULL,
            test_name TEXT NOT NULL,
            value TEXT NOT NULL,
            flag TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id),
            FOREIGN KEY (session_id) REFERENCES sessions (id)
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS chat_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id TEXT NOT NULL,
            sender TEXT NOT NULL,
            message TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            FOREIGN KEY (session_id) REFERENCES sessions (id)
        )
    """)

    conn.commit()
    conn.close()


# ── Users ──────────────────────────────────────────────────────────────────────

def create_user(name, phone, password_hash, age, sex,
                face_encoding=None, preferred_language="ar"):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            INSERT INTO users (name, phone, password_hash, age, sex, face_encoding, preferred_language)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (name, phone, password_hash, age, sex, face_encoding, preferred_language))
        conn.commit()
        return cursor.lastrowid
    except sqlite3.IntegrityError:
        return None
    finally:
        conn.close()


def get_user_by_phone(phone: str) -> dict | None:
    conn = get_db_connection()
    row = conn.execute("SELECT * FROM users WHERE phone = ?", (phone,)).fetchone()
    conn.close()
    return dict(row) if row else None


def get_user_by_id(user_id: int) -> dict | None:
    conn = get_db_connection()
    row = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    conn.close()
    return dict(row) if row else None


def update_user_language(user_id: int, language: str):
    conn = get_db_connection()
    conn.execute("UPDATE users SET preferred_language = ? WHERE id = ?", (language, user_id))
    conn.commit()
    conn.close()


# ── Medical History ────────────────────────────────────────────────────────────

def save_medical_history(user_id: int, question_id: str, answer: str):
    conn = get_db_connection()
    conn.execute(
        "INSERT INTO medical_history (user_id, question_id, answer) VALUES (?, ?, ?)",
        (user_id, question_id, answer),
    )
    conn.commit()
    conn.close()


def update_medical_history(user_id: int, question_id: str, answer: str):
    conn = get_db_connection()
    conn.execute(
        "DELETE FROM medical_history WHERE user_id = ? AND question_id = ?",
        (user_id, question_id),
    )
    if answer and str(answer).strip():
        conn.execute(
            "INSERT INTO medical_history (user_id, question_id, answer) VALUES (?, ?, ?)",
            (user_id, question_id, str(answer).strip()),
        )
    conn.commit()
    conn.close()


def get_medical_history(user_id: int) -> list:
    conn = get_db_connection()
    rows = conn.execute(
        "SELECT question_id, answer FROM medical_history WHERE user_id = ?", (user_id,)
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


# ── Sessions ───────────────────────────────────────────────────────────────────

def create_session(session_id: str, user_id: int,
                   resumed: bool = False, current_step: str = ""):
    conn = get_db_connection()
    conn.execute(
        "INSERT INTO sessions (id, user_id, created_at, resumed, current_step) VALUES (?, ?, ?, ?, ?)",
        (session_id, user_id, datetime.now().isoformat(), 1 if resumed else 0, current_step),
    )
    conn.commit()
    conn.close()


def get_session(session_id: str) -> dict | None:
    conn = get_db_connection()
    row = conn.execute("SELECT * FROM sessions WHERE id = ?", (session_id,)).fetchone()
    conn.close()
    return dict(row) if row else None


def update_session_step(session_id: str, current_step: str):
    conn = get_db_connection()
    conn.execute(
        "UPDATE sessions SET current_step = ? WHERE id = ?", (current_step, session_id)
    )
    conn.commit()
    conn.close()


# ── Vitals ─────────────────────────────────────────────────────────────────────

def save_vitals(user_id, session_id, hr, spo2, sys, dia, temp,
                is_critical, ecg_wave=None):
    import json as _json
    conn = get_db_connection()
    conn.execute(
        """INSERT INTO vitals
           (user_id, session_id, hr, spo2, sys, dia, temp, is_critical, ecg_wave, timestamp)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            user_id, session_id, hr, spo2, sys, dia, temp,
            1 if is_critical else 0,
            _json.dumps(ecg_wave) if ecg_wave else None,
            datetime.now().isoformat(),
        ),
    )
    conn.commit()
    conn.close()


def get_vitals_history(user_id: int, limit: int = 20) -> list:
    import json as _json
    conn = get_db_connection()
    rows = conn.execute(
        """SELECT hr, spo2, sys, dia, temp, is_critical, ecg_wave, timestamp
           FROM vitals WHERE user_id = ? ORDER BY timestamp DESC LIMIT ?""",
        (user_id, limit),
    ).fetchall()
    conn.close()
    result = []
    for row in rows:
        d = dict(row)
        if d.get("ecg_wave"):
            try:
                d["ecg_wave"] = _json.loads(d["ecg_wave"])
            except Exception:
                d["ecg_wave"] = None
        result.append(d)
    return result


def get_vitals_by_session(session_id: str) -> dict | None:
    import json as _json
    conn = get_db_connection()
    rows = conn.execute(
        """SELECT hr, spo2, sys, dia, temp, is_critical, ecg_wave, timestamp
           FROM vitals WHERE session_id = ? ORDER BY timestamp ASC""",
        (session_id,),
    ).fetchall()
    conn.close()
    if not rows:
        return None

    agg = {"hr": None, "spo2": None, "sys": None, "dia": None,
           "temp": None, "is_critical": 0, "ecg_wave": None, "timestamp": None}
    for row in rows:
        d = dict(row)
        for key in ("hr", "spo2", "sys", "dia", "temp", "timestamp"):
            if d.get(key) is not None:
                agg[key] = d[key]
        if d.get("is_critical"):
            agg["is_critical"] = 1
        if d.get("ecg_wave"):
            try:
                agg["ecg_wave"] = _json.loads(d["ecg_wave"])
            except Exception:
                pass
    return agg


# ── Lab Results ────────────────────────────────────────────────────────────────

def save_lab_result(user_id: int, session_id: str, test_name: str,
                    value: str, flag: str, timestamp: str = None):
    """
    Save a single lab test result.
    `timestamp` is the specimen collection date extracted from the OCR report.
    Falls back to now() if not provided.
    flag values: 'Normal', 'High', 'Low', 'Insufficient', or 'unknown'.
    """
    conn = get_db_connection()
    conn.execute(
        """INSERT INTO lab_results (user_id, session_id, test_name, value, flag, timestamp)
           VALUES (?, ?, ?, ?, ?, ?)""",
        (user_id, session_id, test_name, value, flag,
         timestamp if timestamp else datetime.now().isoformat()),
    )
    conn.commit()
    conn.close()


def get_lab_history(user_id: int, limit: int = 50) -> list:
    conn = get_db_connection()
    rows = conn.execute(
        """SELECT test_name, value, flag, timestamp
           FROM lab_results WHERE user_id = ? ORDER BY timestamp DESC LIMIT ?""",
        (user_id, limit),
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


# ── Chat History ───────────────────────────────────────────────────────────────

def save_chat_message(session_id: str, sender: str, message: str):
    conn = get_db_connection()
    conn.execute(
        "INSERT INTO chat_history (session_id, sender, message, timestamp) VALUES (?, ?, ?, ?)",
        (session_id, sender, message, datetime.now().isoformat()),
    )
    conn.commit()
    conn.close()


def get_chat_history(session_id: str) -> list:
    conn = get_db_connection()
    rows = conn.execute(
        """SELECT sender, message, timestamp FROM chat_history
           WHERE session_id = ? ORDER BY timestamp ASC""",
        (session_id,),
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


# ── Initialize tables on first import ─────────────────────────────────────────
init_db()
