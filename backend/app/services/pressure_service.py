from app.database.db import get_connection
from datetime import datetime, timedelta


# -----------------------------
# CREATE READING
# -----------------------------
def create_pressure_reading(patient_id, value_mmhg, recorded_at):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        INSERT INTO PressureReadings (patient_id, timestamp, value)
        VALUES (?, ?, ?)
    """, (patient_id, recorded_at, value_mmhg))

    conn.commit()

    reading_id = cursor.lastrowid

    cursor.execute("""
        SELECT * FROM PressureReadings
        WHERE reading_id = ?
    """, (reading_id,))

    row = cursor.fetchone()
    conn.close()

    return row


# -----------------------------
# GET READINGS
# -----------------------------
def get_pressure_readings(patient_id, limit=20, offset=0):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT *
        FROM PressureReadings
        WHERE patient_id = ?
        ORDER BY timestamp DESC
        LIMIT ? OFFSET ?
    """, (patient_id, limit, offset))

    rows = cursor.fetchall()
    conn.close()

    return rows


# -----------------------------
# SUMMARY (HOME + CHART)
# -----------------------------
def get_pressure_summary(patient_id):
    conn = get_connection()
    cursor = conn.cursor()

    # last 7 days
    cursor.execute("""
        SELECT *
        FROM PressureReadings
        WHERE patient_id = ?
          AND date(timestamp) >= date('now', '-7 day')
        ORDER BY timestamp ASC
    """, (patient_id,))

    rows = cursor.fetchall()

    if not rows:
        return None

    values = [r["value"] for r in rows]

    latest = rows[-1]
    avg = sum(values) / len(values)

    # percent change (simple baseline vs first value)
    first = values[0]
    change = ((latest["value"] - first) / first) * 100 if first else 0

    daily = {}
    for r in rows:
        day = r["timestamp"][:10]
        daily.setdefault(day, []).append(r["value"])

    daily_values = [
        {"date": d, "avg_mmhg": sum(v)/len(v)}
        for d, v in sorted(daily.items())
    ]

    conn.close()

    return {
        "latest": {
            "value_mmhg": latest["value"],
            "recorded_at": latest["timestamp"],
            "status": "high" if latest["value"] > 21 else "normal"
        },
        "seven_day_avg_mmhg": round(avg, 2),
        "seven_day_change_percent": round(change, 2),
        "daily_values": daily_values
    }
