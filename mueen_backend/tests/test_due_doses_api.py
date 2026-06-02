# Import sqlite3 to create and use a temporary SQLite database for testing.
import sqlite3

# Import datetime to generate today's date and current time for test data.
from datetime import datetime

# Import pytest because we use pytest fixtures such as monkeypatch and tmp_path.
import pytest

# Import TestClient to test FastAPI endpoints without running the server manually.
from fastapi.testclient import TestClient

# Import the database module so we can replace database.get_connection during the test.
import database

# Import the FastAPI app from main.py.
from main import app


# Create a TestClient object for the FastAPI app.
# This allows the test to call API endpoints like client.get(...).
client = TestClient(app)


# This helper function creates a temporary database connection.
# It uses tmp_path so the test does not touch the real project database.
def create_test_connection(test_db_path):
    # Open a connection to the temporary SQLite database file.
    conn = sqlite3.connect(test_db_path)

    # Make rows behave like dictionaries, so we can access row["column_name"].
    conn.row_factory = sqlite3.Row

    # Return the temporary database connection.
    return conn


# This helper function creates only the tables needed for the due dose endpoint.
def create_required_tables(conn):
    # Create a cursor to execute SQL commands.
    cursor = conn.cursor()

    # Create elders table because get_due_doses_for_elder joins medication_doses with elders.
    cursor.execute("""
        CREATE TABLE elders (
            id INTEGER PRIMARY KEY,
            caregiver_id INTEGER
        )
    """)

    # Create medications_catalog table because the due dose query returns medication details from it.
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

    # Create elder_medications table because medication_doses links to it.
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

    # Create medication_doses table because this is the main table checked by the endpoint.
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

    # Create adherence_logs table because expired doses may be auto-marked and logged.
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

    # Create caregiver_alerts table because expired missed doses may create caregiver alerts.
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

    # Save all table creation changes.
    conn.commit()


# This helper function inserts basic elder and medication records needed by the due dose query.
def insert_base_records(conn):
    # Create a cursor to execute SQL commands.
    cursor = conn.cursor()

    # Insert one elder with id = 1.
    cursor.execute("""
        INSERT INTO elders (id, caregiver_id)
        VALUES (?, ?)
    """, (1, 10))

    # Insert one medication catalog record.
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

    # Insert one elder medication plan connected to elder id = 1 and catalog id = 1.
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

    # Save inserted base records.
    conn.commit()


# This helper function inserts one dose row into medication_doses.
def insert_dose(conn, scheduled_time, status="pending"):
    # Create a cursor to execute SQL commands.
    cursor = conn.cursor()

    # Get today's date in YYYY-MM-DD format because the endpoint checks only today's doses.
    today = datetime.now().strftime("%Y-%m-%d")

    # Insert one dose for elder id = 1.
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

    # Save the inserted dose.
    conn.commit()


# This fixture prepares a temporary test database for each test case.
@pytest.fixture
def test_database(monkeypatch, tmp_path):
    # Create a temporary database file path.
    test_db_path = tmp_path / "test_mueen.db"

    # Define a replacement get_connection function for tests.
    def get_test_connection():
        # Return a connection to the temporary test database.
        return create_test_connection(test_db_path)

    # Replace database.get_connection with get_test_connection.
    # This prevents the test from using the real mueen.db database.
    monkeypatch.setattr(database, "get_connection", get_test_connection)

    # Open a connection to the temporary database.
    conn = get_test_connection()

    # Create the required tables.
    create_required_tables(conn)

    # Insert the basic elder and medication records.
    insert_base_records(conn)

    # Close the setup connection.
    conn.close()

    # Return the temporary database path if the test needs it.
    return test_db_path


# Integration Test Case 1:
# This test checks that the API returns a due dose when a pending dose is scheduled now.
def test_due_now_endpoint_returns_due_dose(test_database):
    # Open a connection to the temporary database.
    conn = create_test_connection(test_database)

    # Get the current time in HH:MM format.
    now_time = datetime.now().strftime("%H:%M")

    # Insert a pending dose scheduled for the current time.
    insert_dose(conn, scheduled_time=now_time, status="pending")

    # Close the database connection.
    conn.close()

    # Call the real FastAPI endpoint.
    response = client.get("/reminders/due-now/1")

    # Assert that the HTTP response is successful.
    assert response.status_code == 200

    # Convert the response body to JSON.
    data = response.json()

    # Assert that one due dose was returned.
    assert data["count"] == 1

    # Assert that the due_doses list contains exactly one item.
    assert len(data["due_doses"]) == 1

    # Assert that the returned dose belongs to elder id = 1.
    assert data["due_doses"][0]["elder_id"] == 1

    # Assert that the returned dose status is pending.
    assert data["due_doses"][0]["status"] == "pending"


# Integration Test Case 2:
# This test checks that the API returns no due doses when the dose is scheduled in the future.
def test_due_now_endpoint_returns_empty_when_no_due_dose(test_database):
    # Open a connection to the temporary database.
    conn = create_test_connection(test_database)

    # Create a future time that should not be due now.
    future_time = "23:59"

    # Insert a pending dose scheduled for a future time.
    insert_dose(conn, scheduled_time=future_time, status="pending")

    # Close the database connection.
    conn.close()

    # Call the real FastAPI endpoint.
    response = client.get("/reminders/due-now/1")

    # Assert that the HTTP response is successful.
    assert response.status_code == 200

    # Convert the response body to JSON.
    data = response.json()

    # Assert that no due doses were returned.
    assert data["count"] == 0

    # Assert that the due_doses list is empty.
    assert data["due_doses"] == []