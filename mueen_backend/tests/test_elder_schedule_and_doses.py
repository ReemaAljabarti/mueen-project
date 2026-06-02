import sqlite3# لعمل قاعدة بيانات مؤقتة للاختبار
import database # Import the database module so monkeypatch can replace database.get_connection
                # with a temporary test database connection during the test.
from datetime import datetime
from fastapi.testclient import TestClient # Import TestClient to test the FastAPI endpoints.
from main import app  # Imports the FastAPI app instance from main.py.

# Import the function that we want to test.
from database import normalize_time_for_db
from database import generate_dose_times_for_day
from database import generate_today_doses
from database import get_today_doses_for_elder



# ======================================================================================================================================
#                            unit  testing for normalize_time_for_db, generate_dose_times_for_day
# ===============================================================================================================================



# =========================
# Normal cases
# =========================
# These tests cover typical time formats that the function should handle correctly.
#the first case is moring time in Arabic.
def test_normalize_arabic_am_time():
    result = normalize_time_for_db("8:00 ص")
    assert result == "08:00"

#the second case is afternoon time in Arabic
def test_normalize_arabic_pm_time():
    result = normalize_time_for_db("2:30 م")
    assert result == "14:30"

#the third case is already in 24-hour format
def test_normalize_24_hour_time():
    result = normalize_time_for_db("14:30")
    assert result == "14:30"

#the fourth case includes seconds which should be stripped off
def test_normalize_24_hour_time_with_seconds():
    result = normalize_time_for_db("14:30:00")
    assert result == "14:30"


# =========================
# Edge cases
# =========================

# the first case the value is None, which should be handled gracefully and return None.
def test_normalize_none_value():
    result = normalize_time_for_db(None)
    assert result is None

# the second case is an empty string, which should also return None.
def test_normalize_empty_string():
    result = normalize_time_for_db("")
    assert result is None

# the third case is an invalid time format, which should return None as well.
def test_normalize_invalid_text():
    result = normalize_time_for_db("abc")
    assert result is None

# the fourth case is midnight in Arabic, which should be normalized to "00:00".
def test_normalize_arabic_midnight():
    result = normalize_time_for_db("12:00 ص")
    assert result == "00:00"

# the fifth case is noon in Arabic, which should be normalized to "12:00".
def test_normalize_arabic_noon():
    result = normalize_time_for_db("12:00 م")
    assert result == "12:00"

#the fourth case includes spaces which should be stripped off
def test_normalize_time_with_extra_spaces():
    result = normalize_time_for_db(" 8:00 ص ")
    assert result == "08:00"





# =========================
# Normal cases
# =========================
# the first case is one dose per day, which should return the first reminder time as the only dose time.
def test_generate_one_dose_per_day():
    result = generate_dose_times_for_day("09:00", 1)
    assert result == ["09:00"]

# the second case is two doses per day, which should return the first reminder time and a second time 12 hours later.
def test_generate_two_doses_per_day():
    result = generate_dose_times_for_day("09:00", 2)
    assert result == ["09:00", "21:00"]

# the third case is three doses per day, which should return the first reminder time and two additional times 8 hours apart.
def test_generate_three_doses_per_day():
    result = generate_dose_times_for_day("08:00", 3)
    assert result == ["08:00", "16:00", "00:00"]

# the fourth case is four doses per day, which should return the first reminder time and three additional times 6 hours apart.
def test_generate_four_doses_per_day():
    result = generate_dose_times_for_day("06:00", 4)
    assert result == ["06:00", "12:00", "18:00", "00:00"]


# =========================
# Edge cases
# =========================

# the first case is when the first reminder time is late in the day and the second dose time wraps around to the next day.
def test_generate_dose_time_wraps_after_midnight():
    result = generate_dose_times_for_day("20:00", 2)
    assert result == ["20:00", "08:00"]

# the second case is when times_per_day is zero, which should return only the first reminder time as a dose time.

def test_generate_invalid_time_without_colon_returns_original_value():
    result = generate_dose_times_for_day("abc", 2)
    assert result == ["abc"]


def test_generate_invalid_time_with_non_numeric_values_returns_original_value():
    result = generate_dose_times_for_day("aa:bb", 2)
    assert result == ["aa:bb"]



# ======================================================================================================================================
#               Component testing for generate_today_doses, get_today_doses_for_elder
# ===============================================================================================================================


# =========================
# Helper: Create test tables
# =========================
def create_test_tables(conn):
    # Create a cursor to execute SQL commands in the test database.
    cursor = conn.cursor()

    # Create a simplified elder_medications table for the test.
    # This table stores the elder's medication schedule.
    cursor.execute("""
        CREATE TABLE elder_medications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            elder_id INTEGER NOT NULL,
            first_reminder_time TEXT NOT NULL,
            times_per_day INTEGER NOT NULL,
            days_pattern TEXT NOT NULL
        )
    """)

    # Create a simplified medication_doses table for the test.
    # This table stores the actual generated dose records.
    cursor.execute("""
        CREATE TABLE medication_doses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            elder_medication_id INTEGER NOT NULL,
            elder_id INTEGER NOT NULL,
            scheduled_time TEXT NOT NULL,
            dose_date TEXT NOT NULL,
            status TEXT DEFAULT 'pending',
            snooze_count INTEGER DEFAULT 0,
            created_at TEXT,
            last_updated_at TEXT,
            UNIQUE (elder_medication_id, elder_id, scheduled_time, dose_date)
        )
    """)

    # Save the created tables in the temporary database.
    conn.commit()

# =========================
# Normal Case
# =========================
# This test checks that a daily medication taken twice per day
# creates two dose records for today.
def test_generate_today_doses_creates_two_doses(monkeypatch, tmp_path):
    # Create a temporary database file for this test only.
    test_db = tmp_path / "test_mueen.db"# This creates a temporary file path like /tmp/pytest-1234/test_mueen.db that is unique for this test run.

    # Create a function that connects to the temporary test database.
    def get_test_connection():
        conn = sqlite3.connect(test_db)

        # Make database rows accessible by column name.
        # Example: row["scheduled_time"]
        conn.row_factory = sqlite3.Row
        return conn

    # Replace the real database connection with the test database connection.
    # This prevents the test from changing the real mueen.db database.
    monkeypatch.setattr(database, "get_connection", get_test_connection)

    # Open the temporary test database.
    conn = get_test_connection()

    # Create the required test tables.
    create_test_tables(conn)

    # Insert mock medication schedule into elder_medications.
    # This means:
    # elder_id = 1
    # first reminder time = 9:00 AM
    # times_per_day = 2
    # days_pattern = daily
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO elder_medications (
            elder_id,
            first_reminder_time,
            times_per_day,
            days_pattern
        )
        VALUES (?, ?, ?, ?)
    """, (1, "9:00 ص", 2, "daily"))

    # Save the mock medication schedule.
    conn.commit()

    # Close the setup connection before running the function.
    conn.close()

    # Run the real function being tested.
    result = generate_today_doses(1)

    # Check the summary returned by the function.
    assert result["elder_id"] == 1
    assert result["created_count"] == 2
    assert result["skipped_count"] == 0
    assert result["total_checked"] == 1

    # Reopen the temporary database to check what was inserted.
    conn = get_test_connection()
    cursor = conn.cursor()

    # Read the generated doses for elder_id = 1.
    cursor.execute("""
        SELECT scheduled_time, status, snooze_count
        FROM medication_doses
        WHERE elder_id = ?
        ORDER BY scheduled_time ASC
    """, (1,))

    # Get all generated dose rows.
    rows = cursor.fetchall()

    # Close the test database connection.
    conn.close()

    # Extract only the scheduled_time values from the rows.
    times = [row["scheduled_time"] for row in rows]

    # Check that exactly two doses were created.
    assert len(rows) == 2

    # Check that the expected dose times were created.
    assert "09:00" in times
    assert "21:00" in times

    # Check that all generated doses start as pending.
    assert all(row["status"] == "pending" for row in rows)

    # Check that all generated doses have not been snoozed yet.
    assert all(row["snooze_count"] == 0 for row in rows)

# =========================
# Edge Case
# =========================

# This test checks that running generate_today_doses twice
# does not create duplicate dose records.
def test_generate_today_doses_does_not_create_duplicates(monkeypatch, tmp_path):
    test_db = tmp_path / "test_mueen.db"

    def get_test_connection():
        conn = sqlite3.connect(test_db)
        conn.row_factory = sqlite3.Row
        return conn

    monkeypatch.setattr(database, "get_connection", get_test_connection)

    conn = get_test_connection()
    create_test_tables(conn)

    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO elder_medications (
            elder_id,
            first_reminder_time,
            times_per_day,
            days_pattern
        )
        VALUES (?, ?, ?, ?)
    """, (1, "9:00 ص", 2, "daily"))

    conn.commit()
    conn.close()

    first_result = generate_today_doses(1)
    second_result = generate_today_doses(1)

    conn = get_test_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT scheduled_time
        FROM medication_doses
        WHERE elder_id = ?
    """, (1,))

    rows = cursor.fetchall()
    conn.close()

    assert first_result["created_count"] == 2
    assert second_result["created_count"] == 0
    assert second_result["skipped_count"] == 2
    assert len(rows) == 2


# This test checks that invalid reminder time is skipped
# and no dose records are created.
def test_generate_today_doses_skips_invalid_time(monkeypatch, tmp_path):
    test_db = tmp_path / "test_mueen.db"

    def get_test_connection():
        conn = sqlite3.connect(test_db)
        conn.row_factory = sqlite3.Row
        return conn

    monkeypatch.setattr(database, "get_connection", get_test_connection)

    conn = get_test_connection()
    create_test_tables(conn)

    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO elder_medications (
            elder_id,
            first_reminder_time,
            times_per_day,
            days_pattern
        )
        VALUES (?, ?, ?, ?)
    """, (1, "not-a-time", 2, "daily"))

    conn.commit()
    conn.close()

    result = generate_today_doses(1)

    conn = get_test_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT scheduled_time
        FROM medication_doses
        WHERE elder_id = ?
    """, (1,))

    rows = cursor.fetchall()
    conn.close()

    assert result["created_count"] == 0
    assert result["skipped_count"] == 1
    assert result["total_checked"] == 1
    assert len(rows) == 0


# This test checks that the function handles an elder
# with no medication schedules.
def test_generate_today_doses_no_medications(monkeypatch, tmp_path):
    test_db = tmp_path / "test_mueen.db"

    def get_test_connection():
        conn = sqlite3.connect(test_db)
        conn.row_factory = sqlite3.Row
        return conn

    monkeypatch.setattr(database, "get_connection", get_test_connection)

    conn = get_test_connection()
    create_test_tables(conn)
    conn.close()

    result = generate_today_doses(1)

    assert result["elder_id"] == 1
    assert result["created_count"] == 0
    assert result["skipped_count"] == 0
    assert result["total_checked"] == 0
from datetime import datetime


# ======================================================================================================================================
#                                             Component testing for get_today_doses_for_elder
# ===============================================================================================================================


# =========================
# Helper: Create tables for get_today_doses_for_elder
# =========================
def create_today_doses_tables(conn):
    cursor = conn.cursor()

    # This table stores the medication catalog details.
    cursor.execute("""
        CREATE TABLE medications_catalog (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            brand_name_ar TEXT NOT NULL,
            generic_name_en TEXT,
            dosage_form TEXT,
            dosage_strength TEXT,
            route_ar TEXT,
            food_guide_ar TEXT,
            med_category TEXT,
            gtin TEXT
        )
    """)

    # This table stores the elder's medication schedule.
    cursor.execute("""
        CREATE TABLE elder_medications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            elder_id INTEGER NOT NULL,
            catalog_medication_id INTEGER NOT NULL,
            display_name_for_elder TEXT,
            dosage_amount INTEGER NOT NULL,
            dosage_unit TEXT NOT NULL,
            usage_instruction TEXT
        )
    """)

    # This table stores the actual dose records for each day.
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
            last_updated_at TEXT
        )
    """)

    conn.commit()




# =========================
# Helper: Insert medication catalog and elder medication
# =========================
def insert_mock_medication_data(conn):
    cursor = conn.cursor()

    # Insert medication catalog data.
    cursor.execute("""
        INSERT INTO medications_catalog (
            id,
            brand_name_ar,
            generic_name_en,
            dosage_form,
            dosage_strength,
            route_ar,
            food_guide_ar,
            med_category,
            gtin
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        1,
        "جلوكوفاج",
        "Metformin",
        "Tablet",
        "500 mg",
        "عن طريق الفم",
        "بعد الأكل",
        "سكري",
        "1234567890123",
    ))

    # Insert elder medication schedule data.
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
        "دواء السكر",
        1,
        "قرص",
        "بعد الأكل",
    ))

    conn.commit()

# =========================
# Normal Case
# =========================
# This test checks that today's doses are returned with medication details
# and ordered by scheduled_time.
def test_get_today_doses_returns_today_doses_with_details(monkeypatch, tmp_path):
    test_db = tmp_path / "test_mueen.db"

    def get_test_connection():
        conn = sqlite3.connect(test_db)
        conn.row_factory = sqlite3.Row
        return conn

    monkeypatch.setattr(database, "get_connection", get_test_connection)

    conn = get_test_connection()
    create_today_doses_tables(conn)
    insert_mock_medication_data(conn)

    today = datetime.now().strftime("%Y-%m-%d")

    cursor = conn.cursor()

    # Insert two dose records for today.
    cursor.execute("""
        INSERT INTO medication_doses (
            elder_medication_id,
            elder_id,
            scheduled_time,
            dose_date,
            status,
            snooze_count,
            last_updated_at
        )
        VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
    """, (1, 1, "21:00", today, "pending", 0))

    cursor.execute("""
        INSERT INTO medication_doses (
            elder_medication_id,
            elder_id,
            scheduled_time,
            dose_date,
            status,
            snooze_count,
            last_updated_at
        )
        VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
    """, (1, 1, "09:00", today, "taken", 0))

    conn.commit()
    conn.close()

    rows = get_today_doses_for_elder(1)

    assert len(rows) == 2

    # Check that doses are ordered by time.
    assert rows[0]["scheduled_time"] == "09:00"
    assert rows[1]["scheduled_time"] == "21:00"

    # Check dose status values.
    assert rows[0]["status"] == "taken"
    assert rows[1]["status"] == "pending"

    # Check joined elder_medications data.
    assert rows[0]["display_name_for_elder"] == "دواء السكر"
    assert rows[0]["dosage_amount"] == 1
    assert rows[0]["dosage_unit"] == "قرص"
    assert rows[0]["usage_instruction"] == "بعد الأكل"

    # Check joined medications_catalog data.
    assert rows[0]["brand_name_ar"] == "جلوكوفاج"
    assert rows[0]["generic_name_en"] == "Metformin"
    assert rows[0]["med_category"] == "سكري"
    assert rows[0]["gtin"] == "1234567890123"




# =========================
# Edge Case
# =========================
# This test checks that the function returns an empty list
# when the elder has no dose records for today.
def test_get_today_doses_returns_empty_when_no_today_doses(monkeypatch, tmp_path):
    test_db = tmp_path / "test_mueen.db"

    def get_test_connection():
        conn = sqlite3.connect(test_db)
        conn.row_factory = sqlite3.Row
        return conn

    monkeypatch.setattr(database, "get_connection", get_test_connection)

    conn = get_test_connection()
    create_today_doses_tables(conn)
    insert_mock_medication_data(conn)
    conn.close()

    rows = get_today_doses_for_elder(1)

    assert len(rows) == 0


# =========================
# Edge Case
# =========================
# This test checks that the function returns doses only for the requested elder.
def test_get_today_doses_ignores_other_elder_doses(monkeypatch, tmp_path):
    test_db = tmp_path / "test_mueen.db"

    def get_test_connection():
        conn = sqlite3.connect(test_db)
        conn.row_factory = sqlite3.Row
        return conn

    monkeypatch.setattr(database, "get_connection", get_test_connection)

    conn = get_test_connection()
    create_today_doses_tables(conn)
    insert_mock_medication_data(conn)

    today = datetime.now().strftime("%Y-%m-%d")
    cursor = conn.cursor()

    # Insert a dose for elder_id = 2, not elder_id = 1.
    cursor.execute("""
        INSERT INTO medication_doses (
            elder_medication_id,
            elder_id,
            scheduled_time,
            dose_date,
            status,
            snooze_count,
            last_updated_at
        )
        VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
    """, (1, 2, "09:00", today, "pending", 0))

    conn.commit()
    conn.close()

    rows = get_today_doses_for_elder(1)

    assert len(rows) == 0


# ======================================================================================================================================
#                                           Integration Test for Today’s Doses API
# ===============================================================================================================================



# ======================================================================================================================================
#                                             Integration testing for /reminders/today/{elder_id}
# ===============================================================================================================================


# =========================
# Integration Normal Case
# =========================
# This test checks the full API path:
# FastAPI endpoint -> database function -> temporary SQLite database -> JSON response.
def test_get_today_doses_api_returns_today_doses(monkeypatch, tmp_path):
    test_db = tmp_path / "test_mueen.db"

    def get_test_connection():
        conn = sqlite3.connect(test_db)
        conn.row_factory = sqlite3.Row
        return conn

    # Replace the real database connection with the temporary test database.
    monkeypatch.setattr(database, "get_connection", get_test_connection)

    # Create the test database tables.
    conn = get_test_connection()
    create_today_doses_tables(conn)
    insert_mock_medication_data(conn)

    today = datetime.now().strftime("%Y-%m-%d")
    cursor = conn.cursor()

    # Insert one dose record for today.
    cursor.execute("""
        INSERT INTO medication_doses (
            elder_medication_id,
            elder_id,
            scheduled_time,
            dose_date,
            status,
            snooze_count,
            last_updated_at
        )
        VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
    """, (1, 1, "09:00", today, "pending", 0))

    conn.commit()
    conn.close()

    # Create a FastAPI test client.
    client = TestClient(app)

    # Call the actual API endpoint.
    response = client.get("/reminders/today/1")

    # Check that the HTTP request succeeded.
    assert response.status_code == 200

    data = response.json()

    # Check the API response structure.
    assert data["elder_id"] == 1
    assert data["count"] == 1
    assert len(data["today_doses"]) == 1

    dose = data["today_doses"][0]

    # Check important fields returned to Flutter.
    assert dose["scheduled_time"] == "09:00"
    assert dose["status"] == "pending"
    assert dose["medication_name"] == "دواء السكر"
    assert dose["brand_name_ar"] == "جلوكوفاج"
    assert dose["dosage_amount"] == 1
    assert dose["dosage_unit"] == "قرص"
    assert dose["med_category"] == "سكري"
    assert dose["gtin"] == "1234567890123"

# =========================
# Integration Edge Case
# =========================
# This test checks that the API returns an empty today_doses list
# when the elder has no dose records for today.
def test_get_today_doses_api_returns_empty_when_no_doses(monkeypatch, tmp_path):
    test_db = tmp_path / "test_mueen.db"

    def get_test_connection():
        conn = sqlite3.connect(test_db)
        conn.row_factory = sqlite3.Row
        return conn

    monkeypatch.setattr(database, "get_connection", get_test_connection)

    conn = get_test_connection()
    create_today_doses_tables(conn)
    insert_mock_medication_data(conn)
    conn.close()

    client = TestClient(app)

    response = client.get("/reminders/today/1")

    assert response.status_code == 200

    data = response.json()

    assert data["elder_id"] == 1
    assert data["count"] == 0
    assert data["today_doses"] == []






# ======================================================================================================================================
#                                             Integration testing for /reminders/next-dose/{elder_id}
# ===============================================================================================================================


# =========================
# Integration Normal Case
# =========================
# This test checks that the next-dose API returns the next pending dose for today.
def test_get_next_dose_api_returns_next_dose(monkeypatch, tmp_path):
    test_db = tmp_path / "test_mueen.db"

    def get_test_connection():
        conn = sqlite3.connect(test_db)
        conn.row_factory = sqlite3.Row
        return conn

    # Replace the real database connection with the temporary test database.
    monkeypatch.setattr(database, "get_connection", get_test_connection)

    # Create the required test tables.
    conn = get_test_connection()
    create_today_doses_tables(conn)
    insert_mock_medication_data(conn)

    today = datetime.now().strftime("%Y-%m-%d")

    # Use a future time so the endpoint can return it as the next dose.
    now = datetime.now()
    future_hour = (now.hour + 1) % 24
    future_time = f"{future_hour:02d}:{now.minute:02d}"

    cursor = conn.cursor()

    # Insert one pending dose for today.
    cursor.execute("""
        INSERT INTO medication_doses (
            elder_medication_id,
            elder_id,
            scheduled_time,
            dose_date,
            status,
            snooze_count,
            last_updated_at
        )
        VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
    """, (1, 1, future_time, today, "pending", 0))

    conn.commit()
    conn.close()

    client = TestClient(app)

    # Call the actual next-dose API endpoint.
    response = client.get("/reminders/next-dose/1")

    assert response.status_code == 200

    data = response.json()

    # Check that a next dose was found.
    assert data["found"] is True
    assert data["next_dose"] is not None

    dose = data["next_dose"]

    # Check important fields returned to Flutter.
    assert dose["elder_id"] == 1
    assert dose["scheduled_time"] == future_time
    assert dose["status"] == "pending"
    assert dose["medication_name"] == "دواء السكر"
    assert dose["brand_name_ar"] == "جلوكوفاج"
    assert dose["dosage_amount"] == 1
    assert dose["dosage_unit"] == "قرص"
    assert dose["med_category"] == "سكري"


# =========================
# Integration Edge Case
# =========================
# This test checks that the next-dose API returns found = false
# when there are no upcoming pending or snoozed doses for today.
def test_get_next_dose_api_returns_not_found_when_no_next_dose(monkeypatch, tmp_path):
    test_db = tmp_path / "test_mueen.db"

    def get_test_connection():
        conn = sqlite3.connect(test_db)
        conn.row_factory = sqlite3.Row
        return conn

    # Replace the real database connection with the temporary test database.
    monkeypatch.setattr(database, "get_connection", get_test_connection)

    # Create the required test tables only, without inserting dose records.
    conn = get_test_connection()
    create_today_doses_tables(conn)
    insert_mock_medication_data(conn)
    conn.close()

    client = TestClient(app)

    # Call the actual next-dose API endpoint.
    response = client.get("/reminders/next-dose/1")

    assert response.status_code == 200

    data = response.json()

    # Check that no next dose was found.
    assert data["found"] is False
    assert data["next_dose"] is None
    assert data["message"] == "No upcoming dose found for today"