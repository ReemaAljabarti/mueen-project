# Integration Test Description:
# This test file validates Sara's Adherence Outcomes and Caregiver Follow-up APIs.
#
# The tested functionalities are:
# 1. Taken dose API
# 2. Missed dose API and caregiver alert
# 3. Snooze dose API
# 4. No-response dose API
# 5. Caregiver missed-dose follow-up
# 6. Weekly adherence report
#
# These are integration tests because they call real FastAPI endpoints
# using TestClient, and the endpoints connect to database helper functions
# using a temporary SQLite database.

import sqlite3
from datetime import datetime

import pytest
from fastapi.testclient import TestClient

import database
from main import app


# Create a FastAPI test client.
client = TestClient(app)


# Create a connection to the temporary SQLite database.
def create_test_connection(test_db_path):
    conn = sqlite3.connect(test_db_path)
    conn.row_factory = sqlite3.Row
    return conn


# Create all tables needed for Sara's API integration tests.
def create_required_tables(conn):
    cursor = conn.cursor()

    cursor.execute("""
        CREATE TABLE caregivers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            full_name TEXT NOT NULL,
            phone_number TEXT NOT NULL UNIQUE,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL
        )
    """)

    cursor.execute("""
        CREATE TABLE elders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            caregiver_id INTEGER NOT NULL,
            full_name TEXT NOT NULL,
            phone_number TEXT NOT NULL UNIQUE,
            gender TEXT NOT NULL,
            password TEXT NOT NULL,
            age TEXT,
            weight TEXT,
            health_conditions TEXT
        )
    """)

    cursor.execute("""
        CREATE TABLE medications_catalog (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            drug_id TEXT UNIQUE NOT NULL,
            brand_name_ar TEXT NOT NULL,
            generic_name_en TEXT,
            med_category TEXT,
            dosage_strength TEXT,
            dosage_form TEXT,
            route_ar TEXT,
            uses_ar TEXT,
            food_guide_ar TEXT,
            gtin TEXT
        )
    """)

    cursor.execute("""
        CREATE TABLE elder_medications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            elder_id INTEGER NOT NULL,
            catalog_medication_id INTEGER NOT NULL,
            display_name_for_elder TEXT,
            dosage_amount INTEGER NOT NULL,
            dosage_unit TEXT NOT NULL,
            usage_instruction TEXT,
            short_description TEXT,
            treatment_duration_type TEXT,
            start_date TEXT,
            end_date TEXT,
            times_per_day INTEGER NOT NULL,
            first_reminder_time TEXT NOT NULL,
            days_pattern TEXT NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    """)

    cursor.execute("""
        CREATE TABLE medication_doses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            elder_medication_id INTEGER NOT NULL,
            elder_id INTEGER NOT NULL,
            scheduled_time TEXT NOT NULL,
            dose_date TEXT NOT NULL,
            status TEXT DEFAULT 'pending',
            snooze_count INTEGER DEFAULT 0,
            snoozed_until TEXT,
            taken_at TEXT,
            missed_at TEXT,
            last_updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            UNIQUE (elder_medication_id, elder_id, scheduled_time, dose_date)
        )
    """)

    cursor.execute("""
        CREATE TABLE adherence_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            dose_id INTEGER NOT NULL,
            elder_id INTEGER NOT NULL,
            elder_medication_id INTEGER NOT NULL,
            status TEXT NOT NULL,
            event_type TEXT,
            event_time TEXT DEFAULT CURRENT_TIMESTAMP,
            snooze_minutes INTEGER,
            note TEXT
        )
    """)

    cursor.execute("""
        CREATE TABLE caregiver_alerts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            caregiver_id INTEGER NOT NULL,
            elder_id INTEGER NOT NULL,
            dose_id INTEGER NOT NULL,
            alert_type TEXT NOT NULL,
            message TEXT NOT NULL,
            is_read INTEGER DEFAULT 0,
            source TEXT DEFAULT 'system',
            resolved_at TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    """)

    conn.commit()


# Insert base records used by the API tests.
def insert_base_data(conn):
    cursor = conn.cursor()
    today = datetime.now().strftime("%Y-%m-%d")

    cursor.execute("""
        INSERT INTO caregivers (
            id,
            full_name,
            phone_number,
            email,
            password
        )
        VALUES (?, ?, ?, ?, ?)
    """, (
        1,
        "Caregiver Test",
        "0500000001",
        "caregiver@test.com",
        "123456",
    ))

    cursor.execute("""
        INSERT INTO elders (
            id,
            caregiver_id,
            full_name,
            phone_number,
            gender,
            password,
            age,
            weight,
            health_conditions
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        1,
        1,
        "Elder Test",
        "0500000002",
        "female",
        "123456",
        "70",
        "60",
        "[]",
    ))

    cursor.execute("""
        INSERT INTO medications_catalog (
            id,
            drug_id,
            brand_name_ar,
            generic_name_en,
            med_category,
            dosage_strength,
            dosage_form,
            route_ar,
            uses_ar,
            food_guide_ar,
            gtin
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        1,
        "MU001",
        "دواء الضغط",
        "Amlodipine",
        "ضغط الدم",
        "5mg",
        "Tablet",
        "فموي",
        "يستخدم لعلاج ضغط الدم",
        "يمكن تناوله مع أو بدون طعام",
        "1234567890123",
    ))

    cursor.execute("""
        INSERT INTO elder_medications (
            id,
            elder_id,
            catalog_medication_id,
            display_name_for_elder,
            dosage_amount,
            dosage_unit,
            usage_instruction,
            short_description,
            treatment_duration_type,
            start_date,
            end_date,
            times_per_day,
            first_reminder_time,
            days_pattern
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        1,
        1,
        1,
        "دواء الضغط",
        1,
        "حبة",
        "بعد الأكل",
        None,
        None,
        None,
        None,
        1,
        "9:00 ص",
        "daily",
    ))

    # Dose 1: used for taken test.
    cursor.execute("""
        INSERT INTO medication_doses (
            id,
            elder_medication_id,
            elder_id,
            scheduled_time,
            dose_date,
            status,
            snooze_count
        )
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (1, 1, 1, "09:00", today, "pending", 0))

    # Dose 2: used for missed test.
    cursor.execute("""
        INSERT INTO medication_doses (
            id,
            elder_medication_id,
            elder_id,
            scheduled_time,
            dose_date,
            status,
            snooze_count
        )
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (2, 1, 1, "10:00", today, "pending", 0))

    # Dose 3: used for snooze test.
    cursor.execute("""
        INSERT INTO medication_doses (
            id,
            elder_medication_id,
            elder_id,
            scheduled_time,
            dose_date,
            status,
            snooze_count
        )
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (3, 1, 1, "11:00", today, "pending", 0))

    # Dose 4: used for no-response test.
    cursor.execute("""
        INSERT INTO medication_doses (
            id,
            elder_medication_id,
            elder_id,
            scheduled_time,
            dose_date,
            status,
            snooze_count
        )
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (4, 1, 1, "12:00", today, "pending", 0))

    # Dose 5: already missed, used for caregiver missed-dose follow-up.
    cursor.execute("""
        INSERT INTO medication_doses (
            id,
            elder_medication_id,
            elder_id,
            scheduled_time,
            dose_date,
            status,
            snooze_count
        )
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (5, 1, 1, "13:00", today, "missed", 0))

    conn.commit()


# Read a dose status from the temporary database.
def get_dose_status(conn, dose_id):
    cursor = conn.cursor()
    cursor.execute("""
        SELECT status
        FROM medication_doses
        WHERE id = ?
    """, (dose_id,))
    row = cursor.fetchone()
    return row["status"] if row else None


# Count caregiver alerts.
def count_caregiver_alerts(conn):
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) AS count FROM caregiver_alerts")
    row = cursor.fetchone()
    return row["count"]


# This fixture prepares a fresh temporary database for each test case.
@pytest.fixture
def test_database(monkeypatch, tmp_path):
    test_db_path = tmp_path / "test_mueen.db"

    def get_test_connection():
        return create_test_connection(test_db_path)

    # Replace real database connection with temporary test database.
    monkeypatch.setattr(database, "get_connection", get_test_connection)

    conn = get_test_connection()
    create_required_tables(conn)
    insert_base_data(conn)
    conn.close()

    return test_db_path


# Integration Test Case 1:
# Taken dose API should mark the dose as taken and return success.
def test_taken_dose_api_success(test_database):
    response = client.post(
        "/adherence/taken",
        json={
            "dose_id": 1,
            "elder_id": 1,
            "elder_medication_id": 1,
        },
    )

    assert response.status_code == 200

    data = response.json()

    assert data["success"] is True
    assert data["status"] == "taken"

    conn = create_test_connection(test_database)
    status = get_dose_status(conn, 1)
    conn.close()

    assert status == "taken"


# Integration Test Case 2:
# Missed dose API should mark the dose as missed and create caregiver alert.
def test_missed_dose_api_creates_caregiver_alert(test_database):
    response = client.post(
        "/adherence/missed",
        json={
            "dose_id": 2,
            "elder_id": 1,
            "elder_medication_id": 1,
            "note": "missed from test",
        },
    )

    assert response.status_code == 200

    data = response.json()

    assert data["success"] is True
    assert data["status"] == "missed"

    conn = create_test_connection(test_database)
    status = get_dose_status(conn, 2)
    alerts_count = count_caregiver_alerts(conn)
    conn.close()

    assert status == "missed"
    assert alerts_count == 1


# Integration Test Case 3:
# Snooze dose API should snooze a pending dose.
def test_snooze_dose_api_success(test_database):
    response = client.post(
        "/reminders/snooze",
        json={
            "dose_id": 3,
            "elder_id": 1,
            "elder_medication_id": 1,
            "snooze_minutes": 15,
        },
    )

    assert response.status_code == 200

    data = response.json()

    assert data["success"] is True
    assert data["action"] == "snoozed"
    assert data["snoozed_until"] is not None

    conn = create_test_connection(test_database)
    status = get_dose_status(conn, 3)
    conn.close()

    assert status == "snoozed"


# Integration Test Case 4:
# No-response API should count no response as missed and create caregiver alert.
def test_no_response_api_marks_dose_as_missed(test_database):
    response = client.post(
        "/adherence/no-response",
        json={
            "dose_id": 4,
            "elder_id": 1,
            "elder_medication_id": 1,
        },
    )

    assert response.status_code == 200

    data = response.json()

    assert data["success"] is True
    assert data["status"] == "missed"
    assert data["reason"] == "timer_expired_no_response"

    conn = create_test_connection(test_database)
    status = get_dose_status(conn, 4)
    alerts_count = count_caregiver_alerts(conn)
    conn.close()

    assert status == "missed"
    assert alerts_count == 1


# Integration Test Case 5:
# Caregiver missed-dose follow-up API should return today's missed doses.
def test_caregiver_missed_doses_api_returns_missed_doses(test_database):
    response = client.get("/caregiver/missed-doses/1")

    assert response.status_code == 200

    data = response.json()

    assert data["total_missed_today"] >= 1
    assert len(data["missed_doses"]) >= 1
    assert data["missed_doses"][0]["elder_id"] == 1
    assert data["missed_doses"][0]["status"] in ["missed", "no_response"]


# Integration Test Case 6:
# Weekly report API should return adherence summary for the elder.
def test_weekly_report_api_returns_summary(test_database):
    response = client.get("/reports/weekly/1")

    assert response.status_code == 200

    data = response.json()

    assert data["elder_id"] == 1
    assert "total_doses" in data
    assert "taken" in data
    assert "missed" in data
    assert "adherence_percentage" in data
    assert "daily_overview" in data
    assert isinstance(data["daily_overview"], list)