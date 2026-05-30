from app.database.db import get_connection


def get_patient_by_id(patient_id: int):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT patient_id, first_name, last_name, dob, condition
        FROM Patient
        WHERE patient_id = ?
    """, (patient_id,))

    row = cursor.fetchone()
    conn.close()

    return row
