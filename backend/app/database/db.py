import sqlite3
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent

DATABASE_PATH = BASE_DIR / "resolve.db"

print(DATABASE_PATH)


def get_connection():
    conn = sqlite3.connect(str(DATABASE_PATH))

    conn.row_factory = sqlite3.Row

    return conn
