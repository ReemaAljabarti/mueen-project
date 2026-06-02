# Unit Test Description:
# This test file validates adherence helper functions from database.py.
#
# The tested functions are:
# 1. mark_dose_taken()
# 2. mark_dose_missed()
# 3. snooze_dose()
#
# These helper functions were selected because they support Sara's
# Adherence Outcomes and Caregiver Follow-up functionality.
#
# mark_dose_taken() updates a dose status to "taken".
# mark_dose_missed() updates a dose status to "missed".
# snooze_dose() updates a dose status to "snoozed" for the first snooze,
# but if the dose was already snoozed before, it marks the dose as "missed".
#
# Five test cases are included:
# 1. A pending dose can be marked as taken.
# 2. A pending dose can be marked as missed.
# 3. A pending dose can be snoozed successfully.
# 4. A repeated snooze attempt marks the dose as missed.
# 5. A taken dose cannot be snoozed again because it is already final.

# Import sqlite3 to create a temporary SQLite database for testing.
import sqlite3

# Import pytest to use fixtures such as monkeypatch and tmp_path.
import pytest

# Import the database module so we can replace database.get_connection during tests.
import database

# Import the functions that will be tested.
from database import mark_dose_taken, mark_dose_missed, snooze_dose


# Create a connection to the temporary SQLite database.
def create_test_connection(test_db_path):
    # Open a connection to the temporary database file.
    conn = sqlite3.connect(test_db_path)

    # Make rows accessible by column name, such as row["status"].
    conn.row_factory = sqlite3.Row

    # Return the database connection.
    return conn


# Create the medication_doses table needed by the tested functions.
def create_required_tables(conn):
    # Create a cursor to execute SQL commands.
    cursor = conn.cursor()

    # Create only the table needed for these unit tests.
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
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    """)

    # Save the table creation.
    conn.commit()


# Insert one test dose with a selected status and snooze count.
def insert_test_dose(conn, status="pending", snooze_count=0):
    # Create a cursor to execute SQL commands.
    cursor = conn.cursor()

    # Insert one dose row into medication_doses.
    cursor.execute("""
        INSERT INTO medication_doses (
            elder_medication_id,
            elder_id,
            scheduled_time,
            dose_date,
            status,
            snooze_count
        )
        VALUES (?, ?, ?, ?, ?, ?)
    """, (
        1,
        1,
        "09:00",
        "2026-05-24",
        status,
        snooze_count,
    ))

    # Save the inserted row.
    conn.commit()

    # Return the inserted dose id.
    return cursor.lastrowid


# Read one dose from the temporary database by dose id.
def get_dose(conn, dose_id):
    # Create a cursor to execute SQL commands.
    cursor = conn.cursor()

    # Select the dose row by id.
    cursor.execute("""
        SELECT *
        FROM medication_doses
        WHERE id = ?
    """, (dose_id,))

    # Return the selected dose row.
    return cursor.fetchone()


# Prepare a fresh temporary database for every test case.
@pytest.fixture
def test_database(monkeypatch, tmp_path):
    # Create a temporary database file path.
    test_db_path = tmp_path / "test_mueen.db"

    # Define a test replacement for database.get_connection().
    def get_test_connection():
        # Return a connection to the temporary test database.
        return create_test_connection(test_db_path)

    # Replace the real database connection with the temporary one.
    monkeypatch.setattr(database, "get_connection", get_test_connection)

    # Open a connection to create the required table.
    conn = get_test_connection()

    # Create the medication_doses table.
    create_required_tables(conn)

    # Close the setup connection.
    conn.close()

    # Return the temporary database path so tests can use it.
    return test_db_path


# Test case 1:
# This test checks that mark_dose_taken() updates a pending dose to taken.
def test_mark_dose_taken_updates_status_to_taken(test_database):
    # Open a connection to the temporary database.
    conn = create_test_connection(test_database)

    # Insert a pending dose.
    dose_id = insert_test_dose(conn, status="pending")

    # Close the connection before calling the tested function.
    conn.close()

    # Call the tested function.
    updated_count = mark_dose_taken(dose_id)

    # Reopen the temporary database to check the result.
    conn = create_test_connection(test_database)

    # Read the updated dose.
    dose = get_dose(conn, dose_id)

    # Close the connection.
    conn.close()

    # Assert that one row was updated.
    assert updated_count == 1

    # Assert that the dose status became taken.
    assert dose["status"] == "taken"

    # Assert that taken_at was saved.
    assert dose["taken_at"] is not None


# Test case 2:
# This test checks that mark_dose_missed() updates a pending dose to missed.
def test_mark_dose_missed_updates_status_to_missed(test_database):
    # Open a connection to the temporary database.
    conn = create_test_connection(test_database)

    # Insert a pending dose.
    dose_id = insert_test_dose(conn, status="pending")

    # Close the connection before calling the tested function.
    conn.close()

    # Call the tested function.
    updated_count = mark_dose_missed(dose_id)

    # Reopen the temporary database to check the result.
    conn = create_test_connection(test_database)

    # Read the updated dose.
    dose = get_dose(conn, dose_id)

    # Close the connection.
    conn.close()

    # Assert that one row was updated.
    assert updated_count == 1

    # Assert that the dose status became missed.
    assert dose["status"] == "missed"

    # Assert that missed_at was saved.
    assert dose["missed_at"] is not None


# Test case 3:
# This test checks that snooze_dose() snoozes a pending dose successfully.
def test_snooze_pending_dose_returns_snoozed(test_database):
    # Open a connection to the temporary database.
    conn = create_test_connection(test_database)

    # Insert a pending dose with no previous snooze.
    dose_id = insert_test_dose(conn, status="pending", snooze_count=0)

    # Close the connection before calling the tested function.
    conn.close()

    # Call the tested function with 15 minutes.
    result = snooze_dose(dose_id, 15)

    # Reopen the temporary database to check the result.
    conn = create_test_connection(test_database)

    # Read the updated dose.
    dose = get_dose(conn, dose_id)

    # Close the connection.
    conn.close()

    # Assert that the function returned snoozed action.
    assert result["action"] == "snoozed"

    # Assert that the dose status became snoozed.
    assert dose["status"] == "snoozed"

    # Assert that snooze_count increased to 1.
    assert dose["snooze_count"] == 1

    # Assert that snoozed_until was saved.
    assert dose["snoozed_until"] is not None


# Test case 4:
# This test checks that a repeated snooze attempt marks the dose as missed.
def test_repeated_snooze_marks_dose_as_missed(test_database):
    # Open a connection to the temporary database.
    conn = create_test_connection(test_database)

    # Insert a snoozed dose with snooze_count = 1.
    dose_id = insert_test_dose(conn, status="snoozed", snooze_count=1)

    # Close the connection before calling the tested function.
    conn.close()

    # Call snooze_dose again.
    result = snooze_dose(dose_id, 15)

    # Reopen the temporary database to check the result.
    conn = create_test_connection(test_database)

    # Read the updated dose.
    dose = get_dose(conn, dose_id)

    # Close the connection.
    conn.close()

    # Assert that the function returned missed action.
    assert result["action"] == "missed"

    # Assert that the reason is repeated snooze attempt.
    assert result["reason"] == "repeated_snooze_attempt"

    # Assert that the dose status became missed.
    assert dose["status"] == "missed"


# Test case 5:
# This test checks that a final taken dose cannot be snoozed again.
def test_snooze_taken_dose_returns_already_final(test_database):
    # Open a connection to the temporary database.
    conn = create_test_connection(test_database)

    # Insert a dose that is already taken.
    dose_id = insert_test_dose(conn, status="taken", snooze_count=0)

    # Close the connection before calling the tested function.
    conn.close()

    # Try to snooze a taken dose.
    result = snooze_dose(dose_id, 15)

    # Assert that the function blocks the update.
    assert result["action"] == "already_final"

    # Assert that the final status is still taken.
    assert result["status"] == "taken"