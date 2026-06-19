import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), "horria.db")

def migrate():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    try:
        cursor.execute("ALTER TABLE vitals ADD COLUMN ecg_wave TEXT;")
        conn.commit()
        print("Successfully added ecg_wave column to vitals table.")
    except sqlite3.OperationalError as e:
        if "duplicate column name" in str(e).lower():
            print("Column ecg_wave already exists.")
        else:
            print(f"Error during migration: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    migrate()
