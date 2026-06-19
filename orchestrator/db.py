import sqlite3
import os
from datetime import datetime

DB_PATH = os.path.join(os.path.dirname(__file__), "horria.db")

def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Create Users table
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
    
    # Create Medical History table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS medical_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            question_id TEXT NOT NULL,
            answer TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id)
        )
    """)
    
    # Create Sessions table
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
    
    # Create Vitals table
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
    
    # Create Lab Results table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS lab_results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            session_id TEXT NOT NULL,
            test_name TEXT NOT NULL,
            value TEXT NOT NULL,
            flag TEXT NOT NULL, -- 'green', 'amber', 'red'
            timestamp TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id),
            FOREIGN KEY (session_id) REFERENCES sessions (id)
        )
    """)
    
    # Create Chat History table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS chat_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id TEXT NOT NULL,
            sender TEXT NOT NULL, -- 'user' or 'agent'
            message TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            FOREIGN KEY (session_id) REFERENCES sessions (id)
        )
    """)
    
    conn.commit()
    conn.close()

# CRUD operations

def create_user(name, phone, password_hash, age, sex, face_encoding=None, preferred_language='ar'):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            INSERT INTO users (name, phone, password_hash, age, sex, face_encoding, preferred_language)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (name, phone, password_hash, age, sex, face_encoding, preferred_language))
        conn.commit()
        user_id = cursor.lastrowid
        return user_id
    except sqlite3.IntegrityError:
        return None
    finally:
        conn.close()

def get_user_by_phone(phone):
    conn = get_db_connection()
    row = conn.execute("SELECT * FROM users WHERE phone = ?", (phone,)).fetchone()
    conn.close()
    return dict(row) if row else None

def get_user_by_id(user_id):
    conn = get_db_connection()
    row = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    conn.close()
    return dict(row) if row else None

def update_user_language(user_id, language):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("UPDATE users SET preferred_language = ? WHERE id = ?", (language, user_id))
    conn.commit()
    conn.close()

def save_medical_history(user_id, question_id, answer):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO medical_history (user_id, question_id, answer)
        VALUES (?, ?, ?)
    """, (user_id, question_id, answer))
    conn.commit()
    conn.close()

def update_medical_history(user_id, question_id, answer):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM medical_history WHERE user_id = ? AND question_id = ?", (user_id, question_id))
    if answer and str(answer).strip():
        cursor.execute("""
            INSERT INTO medical_history (user_id, question_id, answer)
            VALUES (?, ?, ?)
        """, (user_id, question_id, str(answer).strip()))
    conn.commit()
    conn.close()

def get_medical_history(user_id):
    conn = get_db_connection()
    rows = conn.execute("SELECT question_id, answer FROM medical_history WHERE user_id = ?", (user_id,)).fetchall()
    conn.close()
    return [dict(row) for row in rows]

def create_session(session_id, user_id, resumed=False, current_step=''):
    conn = get_db_connection()
    cursor = conn.cursor()
    created_at = datetime.now().isoformat()
    resumed_val = 1 if resumed else 0
    cursor.execute("""
        INSERT INTO sessions (id, user_id, created_at, resumed, current_step)
        VALUES (?, ?, ?, ?, ?)
    """, (session_id, user_id, created_at, resumed_val, current_step))
    conn.commit()
    conn.close()

def get_session(session_id):
    conn = get_db_connection()
    row = conn.execute("SELECT * FROM sessions WHERE id = ?", (session_id,)).fetchone()
    conn.close()
    return dict(row) if row else None

def update_session_step(session_id, current_step):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("UPDATE sessions SET current_step = ? WHERE id = ?", (current_step, session_id))
    conn.commit()
    conn.close()

def save_vitals(user_id, session_id, hr, spo2, sys, dia, temp, is_critical, ecg_wave=None):
    import json
    conn = get_db_connection()
    cursor = conn.cursor()
    timestamp = datetime.now().isoformat()
    ecg_wave_json = json.dumps(ecg_wave) if ecg_wave else None
    cursor.execute("""
        INSERT INTO vitals (user_id, session_id, hr, spo2, sys, dia, temp, is_critical, ecg_wave, timestamp)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (user_id, session_id, hr, spo2, sys, dia, temp, 1 if is_critical else 0, ecg_wave_json, timestamp))
    conn.commit()
    conn.close()

def get_vitals_history(user_id, limit=20):
    import json
    conn = get_db_connection()
    rows = conn.execute("""
        SELECT hr, spo2, sys, dia, temp, is_critical, ecg_wave, timestamp 
        FROM vitals 
        WHERE user_id = ? 
        ORDER BY timestamp DESC 
        LIMIT ?
    """, (user_id, limit)).fetchall()
    conn.close()
    
    result = []
    for row in rows:
        row_dict = dict(row)
        if row_dict.get('ecg_wave'):
            try:
                row_dict['ecg_wave'] = json.loads(row_dict['ecg_wave'])
            except:
                row_dict['ecg_wave'] = None
        result.append(row_dict)
    return result

def get_vitals_by_session(session_id):
    import json
    conn = get_db_connection()
    row = conn.execute("""
        SELECT hr, spo2, sys, dia, temp, is_critical, ecg_wave, timestamp 
        FROM vitals 
        WHERE session_id = ? 
        ORDER BY timestamp DESC 
        LIMIT 1
    """, (session_id,)).fetchone()
    conn.close()
    
    if not row:
        return None
        
    row_dict = dict(row)
    if row_dict.get('ecg_wave'):
        try:
            row_dict['ecg_wave'] = json.loads(row_dict['ecg_wave'])
        except:
            row_dict['ecg_wave'] = None
    return row_dict

def save_lab_result(user_id, session_id, test_name, value, flag):
    conn = get_db_connection()
    cursor = conn.cursor()
    timestamp = datetime.now().isoformat()
    cursor.execute("""
        INSERT INTO lab_results (user_id, session_id, test_name, value, flag, timestamp)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (user_id, session_id, test_name, value, flag, timestamp))
    conn.commit()
    conn.close()

def get_lab_history(user_id, limit=20):
    conn = get_db_connection()
    rows = conn.execute("""
        SELECT test_name, value, flag, timestamp 
        FROM lab_results 
        WHERE user_id = ? 
        ORDER BY timestamp DESC 
        LIMIT ?
    """, (user_id, limit)).fetchall()
    conn.close()
    return [dict(row) for row in rows]

def save_chat_message(session_id, sender, message):
    conn = get_db_connection()
    cursor = conn.cursor()
    timestamp = datetime.now().isoformat()
    cursor.execute("""
        INSERT INTO chat_history (session_id, sender, message, timestamp)
        VALUES (?, ?, ?, ?)
    """, (session_id, sender, message, timestamp))
    conn.commit()
    conn.close()

def get_chat_history(session_id):
    conn = get_db_connection()
    rows = conn.execute("""
        SELECT sender, message, timestamp 
        FROM chat_history 
        WHERE session_id = ? 
        ORDER BY timestamp ASC
    """, (session_id,)).fetchall()
    conn.close()
    return [dict(row) for row in rows]

# Initialize tables on import
init_db()
