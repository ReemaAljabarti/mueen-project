# Unit-level Backend Test Description:
# This test file validates the backend helper function:
# get_due_doses_for_elder()
#
# This function was selected because it contains the main backend logic
# for detecting whether a dose is due now before opening the dose alert.
#
# These tests use a temporary SQLite database and do not call FastAPI endpoints.
# Therefore, they are backend function tests, not integration API tests.

import sqlite3
from datetime import datetime

import pytest

import database
from database import get_due_doses_for_elder


# Create a connection to the temporary SQLite database.
def create_test_connection(test_db_path):
    conn = sqlite3.connect(test_db_path)
    conn.row_factory = sqlite3.Row
    return conn


# Create only the tables needed by get_due_doses_for_elder().
def create_required_tables(conn):
    cursor = conn.cursor()

    cursor.execute("""
        CREATE TABLE elders (
            id INTEGER PRIMARY KEY,
            caregiver_id INTEGER
        )
    """)

    cursor.execute("""
        CREATE TABLE medications_catalog (
            id INTEGER PRIMARY KEY,
            brand_name_ar TEXT,
            generic_name_en TEXT,
            med_category TEXT,
            dosage_form TEXT,
            dosage_strength TEXT,
            route_ar TEXT,
            food_guide_ar TEXT,
            uses_ar TEXT,
            gtin TEXT
        )
    """)

    cursor.execute("""
        CREATE TABLE elder_medications (
            id INTEGER PRIMARY KEY,
            elder_id INTEGER,
            catalog_medication_id INTEGER,
            display_name_for_elder TEXT,
            dosage_amount INTEGER,
            dosage_unit TEXT,
            usage_instruction TEXT
        )
    """)

    cursor.execute("""
        CREATE TABLE medication_doses (
            id INTEGER PRIMARY KEY,
            elder_medication_id INTEGER,
            elder_id INTEGER,
            scheduled_time TEXT,
            dose_date TEXT,
            status TEXT,
            snooze_count INTEGER,
            snoozed_until TEXT,
            missed_at TEXT,
            last_updated_at TEXT
        )
    """)

    cursor.execute("""
        CREATE TABLE adherence_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            dose_id INTEGER,
            elder_id INTEGER,
            elder_medication_id INTEGER,
            status TEXT,
            event_type TEXT,
            event_time TEXT DEFAULT CURRENT_TIMESTAMP,
            snooze_minutes INTEGER,
            note TEXT
        )
    """)

    cursor.execute("""
        CREATE TABLE caregiver_alerts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            caregiver_id INTEGER,
            elder_id INTEGER,
            dose_id INTEGER,
            alert_type TEXT,
            message TEXT,
            source TEXT
        )
    """)

    conn.commit()


# Insert the basic elder and medication records needed for the test.
def insert_base_records(conn):
    cursor = conn.cursor()

    cursor.execute("""
        INSERT INTO elders (id, caregiver_id)
        VALUES (?, ?)
    """, (1, 10))

    cursor.execute("""
        INSERT INTO medications_catalog (
            id,
            brand_name_ar,
            generic_name_en,
            med_category,
            dosage_form,
            dosage_strength,
            route_ar,
            food_guide_ar,
            uses_ar,
            gtin
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        1,
        "أملوديبين",
        "Amlodipine",
        "ضغط الدم",
        "Tablet",
        "5mg",
        "فموي",
        "يمكن تناوله مع أو بدون طعام",
        "دواء ضغط الدم",
        "123456789",
    ))

    cursor.execute("""
        INSERT INTO elder_medications (
            id,
            elder_id,
            catalog_medication_id,
            display_name_for_elder,
            dosage_amount,
            dosage_unit,
            usage_instruction
        )
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (
        1,
        1,
        1,
        "دواء الضغط",
        1,
        "قرص",
        "بعد الأكل",
    ))

    conn.commit()


# Insert one dose row into medication_doses.
def insert_dose(conn, scheduled_time, status="pending"):
    cursor = conn.cursor()

    today = datetime.now().strftime("%Y-%m-%d")

    cursor.execute("""
        INSERT INTO medication_doses (
            id,
            elder_medication_id,
            elder_id,
            scheduled_time,
            dose_date,
            status,
            snooze_count,
            snoozed_until,
            missed_at,
            last_updated_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
    """, (
        1,
        1,
        1,
        scheduled_time,
        today,
        status,
        0,
        None,
        None,
    ))

    conn.commit()


# Prepare a fresh temporary database for each test case.
@pytest.fixture
def test_database(monkeypatch, tmp_path):
    test_db_path = tmp_path / "test_mueen.db"

    def get_test_connection():
        return create_test_connection(test_db_path)

    # Replace the real database connection with the temporary test database.
    monkeypatch.setattr(database, "get_connection", get_test_connection)

    conn = get_test_connection()
    create_required_tables(conn)
    insert_base_records(conn)
    conn.close()

    return test_db_path


# Unit-level Backend Test Case 1:
# This test checks that get_due_doses_for_elder() returns a due dose
# when a pending dose is scheduled for the current time.
def test_get_due_doses_for_elder_returns_due_dose(test_database):
    conn = create_test_connection(test_database)

    now_time = datetime.now().strftime("%H:%M")

    insert_dose(conn, scheduled_time=now_time, status="pending")

    conn.close()

    results = get_due_doses_for_elder(1)

    assert len(results) == 1
    assert results[0]["elder_id"] == 1
    assert results[0]["status"] == "pending"
    assert results[0]["brand_name_ar"] == "أملوديبين"
    assert results[0]["med_category"] == "ضغط الدم"


# Unit-level Backend Test Case 2:
# This test checks that get_due_doses_for_elder() returns an empty list
# when the pending dose is scheduled in the future.
def test_get_due_doses_for_elder_returns_empty_for_future_dose(test_database):
    conn = create_test_connection(test_database)

    now = datetime.now()

    if now.hour < 23:
        future_time = f"{now.hour + 1:02d}:{now.minute:02d}"
    else:
        future_time = "23:59"

    insert_dose(conn, scheduled_time=future_time, status="pending")

    conn.close()

    results = get_due_doses_for_elder(1)

    assert len(results) == 0