# Unit-level Backend Test Description:
# This test file validates authentication and caregiver-elder database helper functions.
#
# The tested functions are:
# 1. get_caregiver_by_email_or_phone()
# 2. insert_caregiver()
# 3. get_caregiver_by_login()
# 4. insert_elder()
# 5. get_elders_by_caregiver_id()
# 6. get_elder_by_login()
#
# These tests support the User Authentication and Role-Based Workflow functionality.
# They use a temporary SQLite database and do not call FastAPI endpoints.
# Therefore, they are backend function tests, not API integration tests.

import sqlite3
import json

import pytest

import database
from database import (
    get_caregiver_by_email_or_phone,
    insert_caregiver,
    get_caregiver_by_login,
    insert_elder,
    get_elders_by_caregiver_id,
    get_elder_by_login,
)


# Create a connection to the temporary SQLite database.
def create_test_connection(test_db_path):
    conn = sqlite3.connect(test_db_path)
    conn.row_factory = sqlite3.Row
    return conn


# Create only the tables needed for authentication helper tests.
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

    conn.commit()


# Insert one caregiver directly into the temporary database.
def insert_base_caregiver(conn):
    cursor = conn.cursor()

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
        "Strong@123",
    ))

    conn.commit()


# Insert one elder directly into the temporary database.
def insert_base_elder(conn):
    cursor = conn.cursor()

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
        "Elder@123",
        "70",
        "60",
        json.dumps(["diabetes"], ensure_ascii=False),
    ))

    conn.commit()


# Prepare a fresh temporary database for each test case.
@pytest.fixture
def test_database(monkeypatch, tmp_path):
    test_db_path = tmp_path / "test_mueen_auth.db"

    def get_test_connection():
        return create_test_connection(test_db_path)

    # Replace the real database connection with the temporary test database.
    monkeypatch.setattr(database, "get_connection", get_test_connection)

    conn = get_test_connection()
    create_required_tables(conn)
    conn.close()

    return test_db_path


# Test Case 1:
# This test checks that an existing caregiver can be found by email.
def test_get_caregiver_by_email_finds_existing_caregiver(test_database):
    conn = create_test_connection(test_database)
    insert_base_caregiver(conn)
    conn.close()

    caregiver = get_caregiver_by_email_or_phone(
        "caregiver@test.com",
        "9999999999",
    )

    assert caregiver is not None
    assert caregiver["email"] == "caregiver@test.com"
    assert caregiver["phone_number"] == "0500000001"


# Test Case 2:
# This test checks that an existing caregiver can be found by phone number.
def test_get_caregiver_by_phone_finds_existing_caregiver(test_database):
    conn = create_test_connection(test_database)
    insert_base_caregiver(conn)
    conn.close()

    caregiver = get_caregiver_by_email_or_phone(
        "unknown@test.com",
        "0500000001",
    )

    assert caregiver is not None
    assert caregiver["full_name"] == "Caregiver Test"
    assert caregiver["phone_number"] == "0500000001"


# Test Case 3:
# This test checks that insert_caregiver() saves a caregiver record.
def test_insert_caregiver_saves_record(test_database):
    insert_caregiver(
        "New Caregiver",
        "0500000003",
        "newcaregiver@test.com",
        "Strong@123",
    )

    caregiver = get_caregiver_by_email_or_phone(
        "newcaregiver@test.com",
        "0500000003",
    )

    assert caregiver is not None
    assert caregiver["full_name"] == "New Caregiver"
    assert caregiver["email"] == "newcaregiver@test.com"


# Test Case 4:
# This test checks that get_caregiver_by_login() can retrieve caregiver by email.
def test_get_caregiver_by_login_with_email(test_database):
    conn = create_test_connection(test_database)
    insert_base_caregiver(conn)
    conn.close()

    caregiver = get_caregiver_by_login(
        email="caregiver@test.com",
        phone_number=None,
    )

    assert caregiver is not None
    assert caregiver["email"] == "caregiver@test.com"
    assert caregiver["password"] == "Strong@123"


# Test Case 5:
# This test checks that get_caregiver_by_login() can retrieve caregiver by phone number.
def test_get_caregiver_by_login_with_phone_number(test_database):
    conn = create_test_connection(test_database)
    insert_base_caregiver(conn)
    conn.close()

    caregiver = get_caregiver_by_login(
        email=None,
        phone_number="0500000001",
    )

    assert caregiver is not None
    assert caregiver["phone_number"] == "0500000001"
    assert caregiver["password"] == "Strong@123"


# Test Case 6:
# This test checks that insert_elder() saves an elder and links the elder to caregiver.
def test_insert_elder_saves_record_and_links_to_caregiver(test_database):
    conn = create_test_connection(test_database)
    insert_base_caregiver(conn)
    conn.close()

    elder_id = insert_elder(
        caregiver_id=1,
        full_name="Khaled Ali",
        phone_number="0500000004",
        gender="male",
        password="Elder@123",
        age="75",
        weight="70",
        health_conditions=["hypertension"],
    )

    assert elder_id is not None

    elders = get_elders_by_caregiver_id(1)

    assert len(elders) == 1
    assert elders[0]["id"] == elder_id
    assert elders[0]["caregiver_id"] == 1
    assert elders[0]["full_name"] == "Khaled Ali"


# Test Case 7:
# This test checks that get_elders_by_caregiver_id() returns only elders linked to the selected caregiver.
def test_get_elders_by_caregiver_id_returns_only_selected_caregiver_elders(test_database):
    conn = create_test_connection(test_database)

    insert_base_caregiver(conn)

    cursor = conn.cursor()

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
        2,
        "Second Caregiver",
        "0500000005",
        "second@test.com",
        "Strong@123",
    ))

    cursor.execute("""
        INSERT INTO elders (
            caregiver_id,
            full_name,
            phone_number,
            gender,
            password,
            age,
            weight,
            health_conditions
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        1,
        "Elder For Caregiver 1",
        "0500000006",
        "male",
        "Elder@123",
        "70",
        "60",
        json.dumps(["diabetes"], ensure_ascii=False),
    ))

    cursor.execute("""
        INSERT INTO elders (
            caregiver_id,
            full_name,
            phone_number,
            gender,
            password,
            age,
            weight,
            health_conditions
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        2,
        "Elder For Caregiver 2",
        "0500000007",
        "female",
        "Elder@123",
        "72",
        "65",
        json.dumps(["asthma"], ensure_ascii=False),
    ))

    conn.commit()
    conn.close()

    elders = get_elders_by_caregiver_id(1)

    assert len(elders) == 1
    assert elders[0]["caregiver_id"] == 1
    assert elders[0]["full_name"] == "Elder For Caregiver 1"


# Test Case 8:
# This test checks that get_elder_by_login() retrieves elder by phone number.
def test_get_elder_by_login_returns_elder_by_phone_number(test_database):
    conn = create_test_connection(test_database)
    insert_base_caregiver(conn)
    insert_base_elder(conn)
    conn.close()

    elder = get_elder_by_login("0500000002")

    assert elder is not None
    assert elder["phone_number"] == "0500000002"
    assert elder["password"] == "Elder@123"
    assert elder["caregiver_id"] == 1


# Test Case 9:
# This test checks that get_elder_by_login() returns None for unknown phone number.
def test_get_elder_by_login_returns_none_for_unknown_phone_number(test_database):
    conn = create_test_connection(test_database)
    insert_base_caregiver(conn)
    insert_base_elder(conn)
    conn.close()

    elder = get_elder_by_login("0599999999")

    assert elder is None