# Integration Test Description:
# This test file validates Reema's Medication Management and Safety Checks APIs.
#
# The tested functionalities are:
# 1. Barcode / GTIN medication lookup
# 2. Drug interaction detection
# 3. Add medication
# 4. Delete medication
#
# These tests are integration tests because they call real FastAPI endpoints
# using TestClient, and the endpoints connect to database functions using
# a temporary SQLite database.

import sqlite3

import pytest
from fastapi.testclient import TestClient

import database
from main import app


# Create a FastAPI test client.
# This lets us call API endpoints without manually running uvicorn.
client = TestClient(app)


# Create a connection to the temporary SQLite database.
def create_test_connection(test_db_path):
    conn = sqlite3.connect(test_db_path)
    conn.row_factory = sqlite3.Row
    return conn


# Create only the tables needed for Reema's integration tests.
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
        CREATE TABLE drug_interactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            drug_id TEXT NOT NULL,
            interacts_with_drug_id TEXT NOT NULL,
            severity TEXT NOT NULL,
            note_ar TEXT
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

    conn.commit()


# Insert base data used by the integration tests.
def insert_base_data(conn):
    cursor = conn.cursor()

    # Insert one caregiver.
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

    # Insert one elder.
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

    # Insert medication 1: existing medication for the elder.
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
        "يستخدم لعلاج ارتفاع ضغط الدم",
        "يمكن تناوله مع أو بدون طعام",
        "1234567890123",
    ))

    # Insert medication 2: medication that has an interaction with medication 1.
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
        2,
        "MU002",
        "دواء القلب",
        "CardioMed",
        "القلب",
        "10mg",
        "Tablet",
        "فموي",
        "يستخدم لعلاج مشاكل القلب",
        "يفضل تناوله بعد الطعام",
        "2222222222222",
    ))

    # Insert medication 3: medication with no interaction.
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
        3,
        "MU003",
        "فيتامين",
        "Vitamin",
        "مكمل",
        "1000mg",
        "Tablet",
        "فموي",
        "يستخدم كمكمل غذائي",
        "يمكن تناوله بعد الوجبة",
        "3333333333333",
    ))

    # Insert an existing elder medication.
    # This is needed so the interaction check can compare the new medication with existing ones.
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

    # Insert one drug interaction between MU001 and MU002.
    cursor.execute("""
        INSERT INTO drug_interactions (
            drug_id,
            interacts_with_drug_id,
            severity,
            note_ar
        )
        VALUES (?, ?, ?, ?)
    """, (
        "MU001",
        "MU002",
        "HIGH",
        "يوجد تفاعل دوائي محتمل ويجب مراجعة الطبيب.",
    ))

    conn.commit()


# This fixture prepares a fresh temporary database for each test case.
@pytest.fixture
def test_database(monkeypatch, tmp_path):
    test_db_path = tmp_path / "test_mueen.db"

    def get_test_connection():
        return create_test_connection(test_db_path)

    # Replace the real database connection with the temporary test database.
    monkeypatch.setattr(database, "get_connection", get_test_connection)

    conn = get_test_connection()
    create_required_tables(conn)
    insert_base_data(conn)
    conn.close()

    return test_db_path


# Integration Test Case 1:
# Existing GTIN should return medication details.
def test_medication_lookup_by_existing_gtin(test_database):
    response = client.get("/medications/by-gtin/01234567890123")

    assert response.status_code == 200

    data = response.json()

    assert data["found"] is True
    assert data["medication"]["brand_name_ar"] == "دواء الضغط"
    assert data["medication"]["food_guide_ar"] == "يمكن تناوله مع أو بدون طعام"


# Integration Test Case 2:
# Unknown GTIN should return not found.
def test_medication_lookup_by_unknown_gtin(test_database):
    response = client.get("/medications/by-gtin/9999999999999")

    assert response.status_code == 200

    data = response.json()

    assert data["found"] is False
    assert data["message"] == "Medication not found"


# Integration Test Case 3:
# New medication should show a drug interaction with an existing medication.
def test_drug_interaction_detection_returns_interaction(test_database):
    response = client.post(
        "/drug-interactions/check",
        json={
            "elder_id": 1,
            "catalog_medication_id": 2,
        },
    )

    assert response.status_code == 200

    data = response.json()

    assert data["has_interaction"] is True
    assert data["severity"] == "HIGH"
    assert data["existing_medication_name"] == "دواء الضغط"
    assert data["new_medication_name"] == "دواء القلب"


# Integration Test Case 4:
# New medication with no interaction should return has_interaction = false.
def test_drug_interaction_detection_returns_no_interaction(test_database):
    response = client.post(
        "/drug-interactions/check",
        json={
            "elder_id": 1,
            "catalog_medication_id": 3,
        },
    )

    assert response.status_code == 200

    data = response.json()

    assert data["has_interaction"] is False
    assert data["severity"] is None
    assert data["note_ar"] is None


# Integration Test Case 5:
# Add medication endpoint should save a new elder medication.
def test_add_elder_medication_success(test_database):
    response = client.post(
        "/elder-medications",
        json={
            "elder_id": 1,
            "catalog_medication_id": 3,
            "display_name_for_elder": "فيتامين يومي",
            "dosage_amount": 1,
            "dosage_unit": "حبة",
            "usage_instruction": "بعد الفطور",
            "short_description": "مكمل غذائي يومي",
            "treatment_duration_type": None,
            "start_date": None,
            "end_date": None,
            "times_per_day": 1,
            "first_reminder_time": "9:00 ص",
            "days_pattern": "daily",
        },
    )

    assert response.status_code == 200

    data = response.json()

    assert data["success"] is True
    assert data["message"] == "Elder medication saved successfully"


# Integration Test Case 6:
# Delete medication endpoint should remove an elder medication.
def test_delete_elder_medication_success(test_database):
    response = client.delete("/elder-medications/1")

    assert response.status_code == 200

    data = response.json()

    assert data["success"] is True
    assert data["message"] == "Elder medication deleted successfully"