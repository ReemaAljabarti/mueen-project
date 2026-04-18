import sqlite3
import json

DB_NAME = "mueen.db"


def get_connection():
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS caregivers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            full_name TEXT NOT NULL,
            phone_number TEXT NOT NULL UNIQUE,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL
        )
    """)

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS elders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        caregiver_id INTEGER NOT NULL,
        full_name TEXT NOT NULL,
        phone_number TEXT NOT NULL UNIQUE,
        gender TEXT NOT NULL,
        password TEXT NOT NULL,
        age TEXT,
        weight TEXT,
        health_conditions TEXT,
        FOREIGN KEY (caregiver_id) REFERENCES caregivers (id)
    )
""")

    conn.commit()
    conn.close()


def get_caregiver_by_email_or_phone(email, phone_number):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT * FROM caregivers
        WHERE email = ? OR phone_number = ?
    """, (email, phone_number))

    caregiver = cursor.fetchone()
    conn.close()
    return caregiver


def insert_caregiver(full_name, phone_number, email, password):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        INSERT INTO caregivers (full_name, phone_number, email, password)
        VALUES (?, ?, ?, ?)
    """, (full_name, phone_number, email, password))

    conn.commit()
    conn.close()


def get_caregiver_by_login(email, phone_number):
    conn = get_connection()
    cursor = conn.cursor()

    if email:
        cursor.execute("""
            SELECT * FROM caregivers
            WHERE email = ?
        """, (email,))
    else:
        cursor.execute("""
            SELECT * FROM caregivers
            WHERE phone_number = ?
        """, (phone_number,))

    caregiver = cursor.fetchone()
    conn.close()
    return caregiver


def insert_elder(caregiver_id, full_name, phone_number, gender, password, age, weight, health_conditions):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        INSERT INTO elders (caregiver_id, full_name, phone_number, gender, password, age, weight, health_conditions)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        caregiver_id,
        full_name,
        phone_number,
        gender,
        password,
        age,
        weight,
        json.dumps(health_conditions, ensure_ascii=False)
    ))

    conn.commit()
    conn.close()

def get_all_elders():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM elders")
    elders = cursor.fetchall()
    conn.close()
    return elders


def get_elder_by_login(phone_number):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT * FROM elders
        WHERE phone_number = ?
    """, (phone_number,))

    elder = cursor.fetchone()
    conn.close()
    return elder

def get_all_caregivers():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM caregivers")
    caregivers = cursor.fetchall()
    conn.close()
    return caregivers

def get_elders_by_caregiver_id(caregiver_id):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT * FROM elders
        WHERE caregiver_id = ?
    """, (caregiver_id,))

    elders = cursor.fetchall()
    conn.close()
    return elders