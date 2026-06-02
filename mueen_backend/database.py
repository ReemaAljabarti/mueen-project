import sqlite3

DB_NAME = "mueen.db"


def get_connection():
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    return conn

def ensure_column(cursor, table_name: str, column_name: str, column_definition: str):
    cursor.execute(f"PRAGMA table_info({table_name})")
    columns = [row[1] for row in cursor.fetchall()]

    if column_name not in columns:
        cursor.execute(f"""
            ALTER TABLE {table_name}
            ADD COLUMN {column_name} {column_definition}
        """)

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

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS medications_catalog (
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
        CREATE TABLE IF NOT EXISTS elder_medications (
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
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (elder_id) REFERENCES elders (id),
            FOREIGN KEY (catalog_medication_id) REFERENCES medications_catalog (id)
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS drug_interactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            drug_id TEXT NOT NULL,
            interacts_with_drug_id TEXT NOT NULL,
            severity TEXT NOT NULL,
            note_ar TEXT
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS medication_doses (
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
            FOREIGN KEY (elder_medication_id) REFERENCES elder_medications (id),
            FOREIGN KEY (elder_id) REFERENCES elders (id),
            UNIQUE (elder_medication_id, elder_id, scheduled_time, dose_date)
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS adherence_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            dose_id INTEGER NOT NULL,
            elder_id INTEGER NOT NULL,
            elder_medication_id INTEGER NOT NULL,
            status TEXT NOT NULL,
            event_type TEXT,
            event_time TEXT DEFAULT CURRENT_TIMESTAMP,
            snooze_minutes INTEGER,
            note TEXT,
            FOREIGN KEY (dose_id) REFERENCES medication_doses (id)
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS caregiver_alerts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            caregiver_id INTEGER NOT NULL,
            elder_id INTEGER NOT NULL,
            dose_id INTEGER NOT NULL,
            alert_type TEXT NOT NULL,
            message TEXT NOT NULL,
            is_read INTEGER DEFAULT 0,
            source TEXT DEFAULT 'system',
            resolved_at TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (caregiver_id) REFERENCES caregivers (id),
            FOREIGN KEY (elder_id) REFERENCES elders (id),
            FOREIGN KEY (dose_id) REFERENCES medication_doses (id)
        )
    """)
    ensure_column(cursor, "medication_doses", "taken_at", "TEXT")
    ensure_column(cursor, "medication_doses", "missed_at", "TEXT")
    ensure_column(cursor, "medication_doses", "last_updated_at", "TEXT")

    ensure_column(cursor, "adherence_logs", "event_type", "TEXT")

    ensure_column(cursor, "caregiver_alerts", "source", "TEXT DEFAULT 'system'")
    ensure_column(cursor, "caregiver_alerts", "resolved_at", "TEXT")

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


def get_all_caregivers():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM caregivers")
    caregivers = cursor.fetchall()
    conn.close()
    return caregivers


def insert_elder(caregiver_id, full_name, phone_number, gender, password, age, weight, health_conditions):
    import json

    conn = get_connection()
    cursor = conn.cursor()

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
    elder_id = cursor.lastrowid
    conn.close()

    return elder_id

def get_all_elders():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM elders")
    elders = cursor.fetchall()
    conn.close()
    return elders


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


def search_medications(query: str):
    conn = get_connection()
    cursor = conn.cursor()

    like_query = f"%{query}%"

    cursor.execute("""
        SELECT * FROM medications_catalog
        WHERE brand_name_ar LIKE ?
        OR generic_name_en LIKE ?
        LIMIT 10
    """, (like_query, like_query))

    results = cursor.fetchall()
    conn.close()
    return results


def insert_elder_medication(
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
    days_pattern,
):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        INSERT INTO elder_medications (
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
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
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
        days_pattern,
    ))

    conn.commit()
    conn.close()


def get_elder_medications(elder_id):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT 
            em.*,
            mc.brand_name_ar,
            mc.dosage_form,
            mc.dosage_strength,
            mc.route_ar,
            mc.food_guide_ar,
            mc.gtin,
            mc.med_category
        FROM elder_medications em
        JOIN medications_catalog mc
        ON em.catalog_medication_id = mc.id
        WHERE em.elder_id = ?
        ORDER BY em.id DESC
    """, (elder_id,))

    results = cursor.fetchall()
    conn.close()
    return results


def delete_elder_medication(elder_medication_id: int):
    conn = get_connection()
    cursor = conn.cursor()

    # Delete doses for this medication first
    cursor.execute("""
        DELETE FROM medication_doses
        WHERE elder_medication_id = ?
    """, (elder_medication_id,))

    # Delete the medication plan
    cursor.execute("""
        DELETE FROM elder_medications
        WHERE id = ?
    """, (elder_medication_id,))

    conn.commit()
    deleted_count = cursor.rowcount
    conn.close()

    return deleted_count


def update_elder_medication(
    elder_medication_id: int,
    display_name_for_elder,
    dosage_amount: int,
    dosage_unit: str,
    first_reminder_time: str,
):
    from datetime import datetime

    conn = get_connection()
    cursor = conn.cursor()

    # 1) Update the medication plan in elder_medications
    cursor.execute("""
        UPDATE elder_medications
        SET
            display_name_for_elder = ?,
            dosage_amount = ?,
            dosage_unit = ?,
            first_reminder_time = ?
        WHERE id = ?
    """, (
        display_name_for_elder,
        dosage_amount,
        dosage_unit,
        first_reminder_time,
        elder_medication_id,
    ))

    updated_count = cursor.rowcount

    if updated_count > 0:
        today = datetime.now().strftime("%Y-%m-%d")

        first_time = normalize_time_for_db(first_reminder_time)

        # 2) Get elder_id and times_per_day for this medication
        cursor.execute("""
            SELECT
                elder_id,
                times_per_day
            FROM elder_medications
            WHERE id = ?
            LIMIT 1
        """, (elder_medication_id,))

        med = cursor.fetchone()

        if first_time and med:
            elder_id = med["elder_id"]
            times_per_day = med["times_per_day"] or 1

            # 3) Generate the new dose times based on the updated first time
            new_times = generate_dose_times_for_day(
                first_time,
                times_per_day,
            )

            # 4) Delete today's old doses for this medication
            cursor.execute("""
                DELETE FROM medication_doses
                WHERE elder_medication_id = ?
                  AND dose_date = ?
            """, (
                elder_medication_id,
                today,
            ))

            # 5) Insert today's new doses
            for scheduled_time in new_times:
                cursor.execute("""
                    INSERT OR IGNORE INTO medication_doses (
                        elder_medication_id,
                        elder_id,
                        scheduled_time,
                        dose_date,
                        status,
                        snooze_count,
                        created_at,
                        last_updated_at
                    )
                    VALUES (?, ?, ?, ?, 'pending', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, (
                    elder_medication_id,
                    elder_id,
                    scheduled_time,
                    today,
                ))

    conn.commit()
    conn.close()

    return updated_count

def normalize_gtin_for_lookup(gtin: str) -> str:
    digits = ''.join(ch for ch in gtin if ch.isdigit())

    if not digits:
        return ''

    if len(digits) > 14 and '01' in digits:
        idx = digits.find('01')
        candidate = digits[idx + 2: idx + 16]
        if len(candidate) == 14:
            digits = candidate

    if len(digits) == 14 and digits.startswith('0'):
        digits = digits[1:]

    return digits


def get_medication_by_gtin(gtin: str):
    normalized = normalize_gtin_for_lookup(gtin)

    print("NORMALIZED GTIN:", normalized)

    if not normalized:
        return None

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            id,
            drug_id,
            brand_name_ar,
            generic_name_en,
            dosage_strength,
            dosage_form,
            route_ar,
            gtin,
            uses_ar,
            food_guide_ar
        FROM medications_catalog
        WHERE REPLACE(REPLACE(REPLACE(IFNULL(gtin, ''), ' ', ''), '-', ''), '''', '') = ?
        LIMIT 1
    """, (normalized,))

    row = cursor.fetchone()
    print("DB ROW:", row)

    conn.close()
    return row


def normalize_drug_id(drug_id: str | None) -> str:
    if not drug_id:
        return ''

    value = str(drug_id).strip().upper()

    if not value.startswith('MU'):
        return value

    numeric = ''.join(ch for ch in value[2:] if ch.isdigit())
    if not numeric:
        return value

    return f"MU{int(numeric):03d}"


def get_catalog_medication_by_id(catalog_medication_id: int):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            id,
            drug_id,
            brand_name_ar,
            generic_name_en,
            dosage_strength,
            dosage_form,
            route_ar,
            gtin,
            uses_ar,
            food_guide_ar
        FROM medications_catalog
        WHERE id = ?
        LIMIT 1
    """, (catalog_medication_id,))

    row = cursor.fetchone()
    conn.close()
    return row


def get_drug_interaction_with_existing_medications(elder_id: int, new_catalog_medication_id: int):
    new_med = get_catalog_medication_by_id(new_catalog_medication_id)
    if not new_med:
        return None

    new_drug_id = normalize_drug_id(new_med[1])
    new_brand_name = new_med[2]

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            em.id,
            mc.drug_id,
            mc.brand_name_ar
        FROM elder_medications em
        JOIN medications_catalog mc
          ON em.catalog_medication_id = mc.id
        WHERE em.elder_id = ?
    """, (elder_id,))

    existing_rows = cursor.fetchall()

    severity_rank = {
        "HIGH": 3,
        "MODERATE": 2,
        "LOW": 1,
    }

    best_match = None

    for row in existing_rows:
        existing_drug_id = normalize_drug_id(row[1])
        existing_brand_name = row[2]

        cursor.execute("""
            SELECT
                drug_id,
                interacts_with_drug_id,
                severity,
                note_ar
            FROM drug_interactions
            WHERE
                (
                    UPPER(drug_id) = UPPER(?)
                    AND UPPER(interacts_with_drug_id) = UPPER(?)
                )
                OR
                (
                    UPPER(drug_id) = UPPER(?)
                    AND UPPER(interacts_with_drug_id) = UPPER(?)
                )
            LIMIT 1
        """, (
            new_drug_id, existing_drug_id,
            existing_drug_id, new_drug_id,
        ))

        interaction = cursor.fetchone()
        if not interaction:
            continue

        severity = (interaction[2] or '').strip().upper()
        note_ar = interaction[3] or ''

        candidate = {
            "new_drug_id": new_drug_id,
            "new_brand_name": new_brand_name,
            "existing_drug_id": existing_drug_id,
            "existing_brand_name": existing_brand_name,
            "severity": severity,
            "note_ar": note_ar,
        }

        if best_match is None:
            best_match = candidate
        else:
            if severity_rank.get(severity, 0) > severity_rank.get(best_match["severity"], 0):
                best_match = candidate

    conn.close()
    return best_match
def get_elder_current_interactions(elder_id: int):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            em.id,
            mc.drug_id,
            mc.brand_name_ar
        FROM elder_medications em
        JOIN medications_catalog mc
        ON em.catalog_medication_id = mc.id
        WHERE em.elder_id = ?
    """, (elder_id,))

    meds = cursor.fetchall()
    interactions = []

    for i in range(len(meds)):
        for j in range(i + 1, len(meds)):
            drug_a = normalize_drug_id(meds[i][1])
            drug_b = normalize_drug_id(meds[j][1])

            cursor.execute("""
                SELECT severity, note_ar
                FROM drug_interactions
                WHERE
                    (
                        UPPER(drug_id) = UPPER(?)
                        AND UPPER(interacts_with_drug_id) = UPPER(?)
                    )
                    OR
                    (
                        UPPER(drug_id) = UPPER(?)
                        AND UPPER(interacts_with_drug_id) = UPPER(?)
                    )
                LIMIT 1
            """, (drug_a, drug_b, drug_b, drug_a))

            row = cursor.fetchone()

            if row:
                interactions.append({
                    "medication_a": meds[i][2],
                    "medication_b": meds[j][2],
                    "severity": row[0],
                    "note_ar": row[1],
                })
    

    conn.close()
    return interactions



# ═══════════════════════════════════════════════════════════════════════
# Dose Reminder & Adherence Tracking Helper Functions
# ═══════════════════════════════════════════════════════════════════════
def get_today_doses_for_elder(elder_id: int):
    """Return all dose records for today, not only due-now doses."""
    from datetime import datetime

    today = datetime.now().strftime("%Y-%m-%d")

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            md.id,
            md.elder_medication_id,
            md.elder_id,
            md.scheduled_time,
            md.dose_date,
            md.status,
            md.snooze_count,
            md.snoozed_until,
            md.taken_at,
            md.missed_at,
            md.last_updated_at,
            em.display_name_for_elder,
            em.dosage_amount,
            em.dosage_unit,
            em.usage_instruction,
            mc.brand_name_ar,
            mc.generic_name_en,
            mc.dosage_form,
            mc.dosage_strength,
            mc.route_ar,
            mc.food_guide_ar,
            mc.med_category,
            mc.gtin
        FROM medication_doses md
        JOIN elder_medications em ON md.elder_medication_id = em.id
        JOIN medications_catalog mc ON em.catalog_medication_id = mc.id
        WHERE md.elder_id = ?
          AND md.dose_date = ?
        ORDER BY md.scheduled_time ASC
    """, (elder_id, today))

    rows = cursor.fetchall()
    conn.close()
    return rows

#============================================================================================
def generate_today_doses(elder_id: int):
    """
    Generate today's actual dose records for a specific elder.

    The function reads the elder's medication schedule from elder_medications,
    including first_reminder_time, times_per_day, and days_pattern.
    It normalizes the first reminder time, calculates all dose times for today,
    and inserts the generated dose records into medication_doses.

    These generated records are later used to display today's doses
    and detect due doses for dose alerts.
    """

    # Import datetime inside the function to get the current date and weekday.
    from datetime import datetime

    # Get today's date in YYYY-MM-DD format.
    # This value will be stored in medication_doses.dose_date.
    today = datetime.now().strftime("%Y-%m-%d")

    # Map Python weekday numbers to the same text format used in days_pattern.
    # Python weekday(): Monday = 0, Sunday = 6.
    # Match the format used in days_pattern, such as: sun,tue
    weekday_map = {
        0: "mon",
        1: "tue",
        2: "wed",
        3: "thu",
        4: "fri",
        5: "sat",
        6: "sun",
    }
    # Get today's day name, such as "mon", "tue", or "sun".
    # This is used to check if a medication is scheduled for today.
    today_day = weekday_map[datetime.now().weekday()]

    # Open a connection to the database.
    conn = get_connection()
    # Create a cursor to execute SQL queries.
    cursor = conn.cursor()

    # Select all medication schedules for the given elder.
    # These records come from elder_medications, which stores the medication plan.
    cursor.execute("""
        SELECT
            id,
            elder_id,
            first_reminder_time,
            times_per_day,
            days_pattern
        FROM elder_medications
        WHERE elder_id = ?
    """, (elder_id,))

    # Fetch all medication schedule rows for this elder.
    medications = cursor.fetchall()
    # Count how many new dose records are created.
    created_count = 0
     # Count how many medications or dose records are skipped.
    skipped_count = 0

 # Loop through each medication schedule for this elder.

        # Get the elder_medications row id.
        # This links each generated dose back to its medication schedule.
    for med in medications:
        elder_medication_id = med["id"]

        # Clean the days_pattern value.
        # Example: " Daily " becomes "daily".
        days_pattern = (med["days_pattern"] or "").strip().lower()
         # Get how many times this medication should be taken per day.
        # If the value is missing, default to 1.
        times_per_day = med["times_per_day"] or 1

        # Only generate doses if the medication is scheduled for today.
        if days_pattern != "daily":
            scheduled_days = [
                day.strip()
                for day in days_pattern.split(",")
                if day.strip()
            ]

            # If today is not included in the medication schedule, skip it.

            if today_day not in scheduled_days:
                skipped_count += 1
                continue
# Normalize the first reminder time into HH:MM format.
        # Example: "9:00 ص" becomes "09:00".
        first_time = normalize_time_for_db(med["first_reminder_time"])
        # If the reminder time is invalid or missing, skip this medication.

        if not first_time:
            skipped_count += 1
            continue

        # Generate all dose times for today based on the first time
        # and the number of doses per day.
        # Example: first_time="09:00", times_per_day=2 -> ["09:00", "21:00"].
        dose_times = generate_dose_times_for_day(first_time, times_per_day)
        # Loop through each generated dose time.

        for scheduled_time in dose_times:
            # Check if this exact dose already exists for today.
            # This prevents duplicate dose records if the function runs more than once.
            cursor.execute("""
                SELECT id
                FROM medication_doses
                WHERE elder_medication_id = ?
                  AND elder_id = ?
                  AND scheduled_time = ?
                  AND dose_date = ?
                LIMIT 1
            """, (
                elder_medication_id,
                elder_id,
                scheduled_time,
                today,
            ))
            # Fetch one existing dose record if it exists.

            existing = cursor.fetchone()

            if existing:
                skipped_count += 1
                continue
 # Insert a new dose record into medication_doses.
            # New doses start with status "pending" and snooze_count 0.
            cursor.execute("""
                INSERT INTO medication_doses (
                    elder_medication_id,
                    elder_id,
                    scheduled_time,
                    dose_date,
                    status,
                    snooze_count,
                    created_at,
                    last_updated_at
                )
                VALUES (?, ?, ?, ?, 'pending', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            """, (
                elder_medication_id,
                elder_id,
                scheduled_time,
                today,
            ))
            # Increase the count of newly created dose records.

            created_count += 1
    # Save all inserted dose records to the database.

    conn.commit()
    # Close the database connection.
    conn.close()
    # Return a summary of what happened.
    return {
        "elder_id": elder_id,
        "dose_date": today,
        "created_count": created_count,
        "skipped_count": skipped_count,
        "total_checked": len(medications),
    }




# This function calculates the scheduled dose times for a
#  day based on the first reminder time and the number of doses per day.
# ريما
def generate_dose_times_for_day(first_time: str, times_per_day: int):
    """
    Generate dose times in HH:MM format based on:
    - first_time: first dose time in HH:MM
    - times_per_day: number of doses per day

    Examples:
    09:00 + 2 doses -> 09:00, 21:00
    08:00 + 3 doses -> 08:00, 16:00, 00:00
    """
    try:
        hour, minute = first_time.split(":")
        start_hour = int(hour)
        start_minute = int(minute)
    except ValueError:
        return [first_time]

    if times_per_day <= 1:
        return [f"{start_hour:02d}:{start_minute:02d}"]

    interval_hours = 24 // times_per_day

    dose_times = []

    for index in range(times_per_day):
        dose_hour = (start_hour + (index * interval_hours)) % 24
        dose_times.append(f"{dose_hour:02d}:{start_minute:02d}")

    return dose_times

#normalize_time_for_db() is a small helper function, but it is important because dose scheduling depends on consistent time format.
# The caregiver selects the first reminder time in a 12-hour Arabic format from Flutter.
# This value is stored in elder_medications.
# When today's doses are generated, the backend uses normalize_time_for_db()
# to convert it into a consistent 24-hour format before saving the actual dose records
# in medication_doses.
def normalize_time_for_db(time_value: str | None):
    """
    Convert different time formats to HH:MM.

    Supported examples:
    - 14:30
    - 14:30:00
    - 2:30 م
    - 8:00 ص
    """
    # If the value is empty or None, return None
    if not time_value:
        return None
    
    # Convert the input to string and remove extra spaces
    value = str(time_value).strip()

    # Import regex to search for time patterns
    import re

    # Check if the time is written in Arabic AM/PM format
    # Examples: 8:00 ص , 2:30 م
    arabic_match = re.search(r"(\d{1,2}):(\d{2})\s*([صم])", value)

    # If Arabic time format is found
    if arabic_match:

    # Extract the hour part
        hour = int(arabic_match.group(1))

    # Extract the minute part
        minute = int(arabic_match.group(2))

    # Extract the period: ص or م
        period = arabic_match.group(3)

        # If the period is PM and the hour is not 12,
        # convert it to 24-hour format
        # Example: 2:30 م becomes 14:30
        if period == "م" and hour != 12:
            hour += 12

        # If the period is AM and the hour is 12,
        # convert midnight to 00
        # Example: 12:00 ص becomes 00:00
        if period == "ص" and hour == 12:
            hour = 0

        # Return the time in HH:MM format
        return f"{hour:02d}:{minute:02d}"
    
    # Check if the time is already in normal format
    # Examples: 14:30 or 14:30:00
    iso_match = re.search(r"^(\d{1,2}):(\d{2})", value)
    if iso_match:

    # Extract the hour part
        hour = int(iso_match.group(1))
    # Extract the minute part    
        minute = int(iso_match.group(2))
    # If the input does not match any supported time format,
    # return None
        return f"{hour:02d}:{minute:02d}"

    return None

#عرض كل جرعات اليوم

def get_today_doses_for_elder(elder_id: int):
        """Return all dose records for today, not only due-now doses."""
        from datetime import datetime # Import datetime to get the current date

        today = datetime.now().strftime("%Y-%m-%d")# Get today's date in YYYY-MM-DD format to match the dose_date field

        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT
                md.id,
                md.elder_medication_id,
                md.elder_id,
                md.scheduled_time,
                md.dose_date,
                md.status,
                md.snooze_count,
                md.snoozed_until,
                md.taken_at,
                md.missed_at,
                md.last_updated_at,
                em.display_name_for_elder,
                em.dosage_amount,
                em.dosage_unit,
                em.usage_instruction,
                mc.brand_name_ar,
                mc.generic_name_en,
                mc.dosage_form,
                mc.dosage_strength,
                mc.route_ar,
                mc.food_guide_ar,
                mc.med_category,
                mc.gtin
            FROM medication_doses md
            JOIN elder_medications em ON md.elder_medication_id = em.id
            JOIN medications_catalog mc ON em.catalog_medication_id = mc.id
            WHERE md.elder_id = ?
            AND md.dose_date = ?
            ORDER BY md.scheduled_time ASC
        """, (elder_id, today))

        rows = cursor.fetchall()
        conn.close()
        return rows

#الجرعة القادمة
def get_next_dose_for_elder(elder_id: int):
    """Return the next pending or snoozed dose for today."""
    from datetime import datetime

    today = datetime.now().strftime("%Y-%m-%d")
    now_str = datetime.now().strftime("%H:%M")

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            md.id,
            md.elder_medication_id,
            md.elder_id,
            md.scheduled_time,
            md.dose_date,
            md.status,
            md.snooze_count,
            md.snoozed_until,
            em.display_name_for_elder,
            em.dosage_amount,
            em.dosage_unit,
            em.usage_instruction,
            mc.brand_name_ar,
            mc.generic_name_en,
            mc.dosage_form,
            mc.dosage_strength,
            mc.route_ar,
            mc.food_guide_ar,
            mc.med_category,
            mc.gtin
        FROM medication_doses md
        JOIN elder_medications em ON md.elder_medication_id = em.id
        JOIN medications_catalog mc ON em.catalog_medication_id = mc.id
        WHERE md.elder_id = ?
          AND md.dose_date = ?
          AND md.status IN ('pending', 'snoozed')
          AND COALESCE(md.snoozed_until, md.scheduled_time) >= ?
        ORDER BY COALESCE(md.snoozed_until, md.scheduled_time) ASC
        LIMIT 1
    """, (elder_id, today, now_str))

    row = cursor.fetchone()
    conn.close()
    return row

#



def get_due_doses_for_elder(elder_id: int):
    """Return doses that are due now and auto-mark expired doses as missed.
    
    This function is used by the dose alert service.
    It checks medication_doses and returns only doses that should trigger
    the full-screen dose alert now.
    It also checks for any doses that have expired (pending or snoozed doses that are past their scheduled or snoozed time) 
    and auto-marks them as missed.
    
    """
    # Import datetime to work with current date and time.
    from datetime import datetime, timedelta
# Open a connection to the database.
    conn = get_connection()
      # Create a cursor to execute SQL commands.
    cursor = conn.cursor()
    # Get the current date and time.
    now = datetime.now()
    # Format today's date as YYYY-MM-DD.
    # This is used to check only today's dose records.
    today = now.strftime("%Y-%m-%d")
     # Format the current time as HH:MM.
    # This is used to compare with scheduled_time and snoozed_until.
    now_str = now.strftime("%H:%M")

       # Calculate the start of the response window.
    # Doses older than this window are considered expired.
    ten_mins_ago_str = (now - timedelta(minutes=10)).strftime("%H:%M")
 # Find expired doses.
    # A pending dose is expired if its scheduled_time is older than 10 minutes ago.
    # A snoozed dose is expired if its snoozed_until time is older than 10 minutes ago.
    cursor.execute("""
        SELECT
            md.id,
            md.elder_id,
            md.elder_medication_id,
            md.status,
            md.scheduled_time,
            md.snoozed_until,
            e.caregiver_id
        FROM medication_doses md
        JOIN elders e ON md.elder_id = e.id
        WHERE md.elder_id = ?
          AND md.dose_date = ?
          AND (
              (md.status = 'pending' AND md.scheduled_time < ?)
              OR
              (md.status = 'snoozed' AND md.snoozed_until IS NOT NULL AND md.snoozed_until < ?)
          )
    """, (elder_id, today, ten_mins_ago_str, ten_mins_ago_str))
    # Get all expired dose rows.

    expired_doses = cursor.fetchall()
  # Loop through each expired dose and mark it as missed.
    for dose in expired_doses:
                # Update the expired dose status to missed.

        cursor.execute("""
            UPDATE medication_doses
            SET
                status = 'missed',
                missed_at = CURRENT_TIMESTAMP,
                last_updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
              AND status IN ('pending', 'snoozed')
        """, (dose["id"],))
        # If a row was actually updated, add logs and caregiver alert.

        if cursor.rowcount > 0:
                        # Insert an adherence log to record that the dose was auto-marked as missed.

            cursor.execute("""
                INSERT INTO adherence_logs (
                    dose_id,
                    elder_id,
                    elder_medication_id,
                    status,
                    event_type,
                    event_time,
                    snooze_minutes,
                    note
                )
                VALUES (?, ?, ?, 'missed', 'missed', CURRENT_TIMESTAMP, NULL, ?)
            """, (
                dose["id"],
                dose["elder_id"],
                dose["elder_medication_id"],
                "Auto marked as missed after no response window.",
            ))
            # If the elder has a caregiver, create an alert for the caregiver.

            if dose["caregiver_id"]:
                cursor.execute("""
                    INSERT INTO caregiver_alerts (
                        caregiver_id,
                        elder_id,
                        dose_id,
                        alert_type,
                        message,
                        source
                    )
                    VALUES (?, ?, ?, 'missed_dose', ?, 'system')
                """, (
                    dose["caregiver_id"],
                    dose["elder_id"],
                    dose["id"],
                    "كبير السن لم يتناول الجرعة بعد انتهاء مهلة الاستجابة",
                ))
    # Save the updates, logs, and caregiver alerts.

    conn.commit()
 # Find doses that are due now.
    # These are the doses that should open the full-screen dose alert.
    cursor.execute("""
        SELECT
            md.id,
            md.elder_medication_id,
            md.elder_id,
            md.scheduled_time,
            md.dose_date,
            md.status,
            md.snooze_count,
            md.snoozed_until,

            em.display_name_for_elder,
            em.dosage_amount,
            em.dosage_unit,
            em.usage_instruction,

            mc.brand_name_ar,
            mc.generic_name_en,
            mc.dosage_form,
            mc.dosage_strength,
            mc.route_ar,
            mc.food_guide_ar,
            mc.uses_ar,
            mc.med_category,
            mc.gtin

        FROM medication_doses md
        JOIN elder_medications em ON md.elder_medication_id = em.id
        JOIN medications_catalog mc ON em.catalog_medication_id = mc.id
        WHERE md.elder_id = ?
          AND md.dose_date = ?
          AND (
              (
                  md.status = 'pending'
                  AND md.scheduled_time <= ?
                  AND md.scheduled_time >= ?
              )
              OR
              (
                  md.status = 'snoozed'
                  AND md.snoozed_until IS NOT NULL
                  AND md.snoozed_until <= ?
                  AND md.snoozed_until >= ?
              )
          )
        ORDER BY md.scheduled_time ASC
    """, (
        elder_id,
        today,
        now_str,
        ten_mins_ago_str,
        now_str,
        ten_mins_ago_str,
    ))
    # Get all due dose rows.

    results = cursor.fetchall()
        # Close the database connection.

    conn.close()
        # Return the due doses to the API.

    return results



#===========================================================
def create_dose_for_elder(elder_medication_id: int, elder_id: int, scheduled_time: str, dose_date: str):
    """Insert a new pending dose record."""
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO medication_doses (elder_medication_id, elder_id, scheduled_time, dose_date)
        VALUES (?, ?, ?, ?)
    """, (elder_medication_id, elder_id, scheduled_time, dose_date))
    conn.commit()
    dose_id = cursor.lastrowid
    conn.close()
    return dose_id

#دوال taken / missed / snooze

def mark_dose_taken(dose_id: int):
    """Mark a dose as taken and save the taken time."""
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        UPDATE medication_doses
        SET
            status = 'taken',
            taken_at = CURRENT_TIMESTAMP,
            last_updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
    """, (dose_id,))

    conn.commit()
    updated_count = cursor.rowcount
    conn.close()
    return updated_count


def mark_dose_missed(dose_id: int):
    """Mark a dose as missed and save the missed time."""
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        UPDATE medication_doses
        SET
            status = 'missed',
            missed_at = CURRENT_TIMESTAMP,
            last_updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
    """, (dose_id,))

    conn.commit()
    updated_count = cursor.rowcount
    conn.close()
    return updated_count


def snooze_dose(dose_id: int, snooze_minutes: int):
    """
    Snooze a dose once.
    If already snoozed, mark it as missed.
    """
    from datetime import datetime, timedelta

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT snooze_count, status
        FROM medication_doses
        WHERE id = ?
    """, (dose_id,))

    row = cursor.fetchone()

    if not row:
        conn.close()
        return {"action": "not_found"}

    snooze_count = row["snooze_count"] or 0
    status = row["status"]

    if status in ("taken", "missed", "no_response"):
        conn.close()
        return {
            "action": "already_final",
            "status": status,
        }

    if snooze_count >= 1:
        conn.close()
        mark_dose_missed(dose_id)
        return {
            "action": "missed",
            "reason": "repeated_snooze_attempt",
        }

    snoozed_until = (datetime.now() + timedelta(minutes=snooze_minutes)).strftime("%H:%M")

    cursor.execute("""
        UPDATE medication_doses
        SET
            status = 'snoozed',
            snooze_count = snooze_count + 1,
            snoozed_until = ?,
            last_updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
          AND status IN ('pending', 'snoozed')
    """, (snoozed_until, dose_id))

    if cursor.rowcount == 0:
        conn.close()
        return {
            "action": "not_updated",
        }

    conn.commit()
    conn.close()

    return {
        "action": "snoozed",
        "snoozed_until": snoozed_until,
    }
#==============================================================================================
def insert_adherence_log(
    dose_id: int,
    elder_id: int,
    elder_medication_id: int,
    status: str,
    snooze_minutes: int = None,
    note: str = None,
):
    """Insert a record into adherence_logs."""
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        INSERT INTO adherence_logs (
            dose_id,
            elder_id,
            elder_medication_id,
            status,
            event_type,
            snooze_minutes,
            note
        )
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (
        dose_id,
        elder_id,
        elder_medication_id,
        status,
        status,
        snooze_minutes,
        note,
    ))

    conn.commit()
    log_id = cursor.lastrowid
    conn.close()
    return log_id


def create_caregiver_alert(
    caregiver_id: int,
    elder_id: int,
    dose_id: int,
    alert_type: str,
    message: str,
    source: str = "system",
):
    """Insert a caregiver alert."""
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        INSERT INTO caregiver_alerts (
            caregiver_id,
            elder_id,
            dose_id,
            alert_type,
            message,
            source
        )
        VALUES (?, ?, ?, ?, ?, ?)
    """, (
        caregiver_id,
        elder_id,
        dose_id,
        alert_type,
        message,
        source,
    ))

    conn.commit()
    alert_id = cursor.lastrowid
    conn.close()
    return alert_id


def get_elder_caregiver_id(elder_id: int):
    """Return the caregiver_id for a given elder."""
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT caregiver_id FROM elders WHERE id = ?", (elder_id,))
    row = cursor.fetchone()
    conn.close()
    return row["caregiver_id"] if row else None



def auto_mark_expired_doses_for_caregiver(caregiver_id: int):
    """
    Auto-mark old pending/snoozed doses as missed for all elders under a caregiver.

    This covers the case where the elder did not open the app or did not reach
    the Dose Alert screen, so /adherence/no-response was never called.
    """
    from datetime import datetime, timedelta

    conn = get_connection()
    cursor = conn.cursor()

    now = datetime.now()
    today = now.strftime("%Y-%m-%d")
    cutoff_time = (now - timedelta(minutes=10)).strftime("%H:%M")

    cursor.execute("""
        SELECT
            md.id,
            md.elder_id,
            md.elder_medication_id,
            md.status,
            md.scheduled_time,
            md.snoozed_until,
            e.caregiver_id
        FROM medication_doses md
        JOIN elders e ON md.elder_id = e.id
        WHERE e.caregiver_id = ?
          AND md.dose_date = ?
          AND (
              (md.status = 'pending' AND md.scheduled_time < ?)
              OR
              (md.status = 'snoozed'
               AND md.snoozed_until IS NOT NULL
               AND md.snoozed_until < ?)
          )
    """, (caregiver_id, today, cutoff_time, cutoff_time))

    expired_doses = cursor.fetchall()
    updated_count = 0

    for dose in expired_doses:
        cursor.execute("""
            UPDATE medication_doses
            SET
                status = 'missed',
                missed_at = CURRENT_TIMESTAMP,
                last_updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
              AND status IN ('pending', 'snoozed')
        """, (dose["id"],))

        if cursor.rowcount <= 0:
            continue

        updated_count += 1

        cursor.execute("""
            INSERT INTO adherence_logs (
                dose_id,
                elder_id,
                elder_medication_id,
                status,
                event_type,
                event_time,
                snooze_minutes,
                note
            )
            VALUES (?, ?, ?, 'missed', 'missed', CURRENT_TIMESTAMP, NULL, ?)
        """, (
            dose["id"],
            dose["elder_id"],
            dose["elder_medication_id"],
            "Auto marked as missed when caregiver checked missed doses.",
        ))

        cursor.execute("""
            SELECT id
            FROM caregiver_alerts
            WHERE caregiver_id = ?
              AND elder_id = ?
              AND dose_id = ?
              AND alert_type = 'missed_dose'
            LIMIT 1
        """, (
            dose["caregiver_id"],
            dose["elder_id"],
            dose["id"],
        ))

        existing_alert = cursor.fetchone()

        if existing_alert is None:
            cursor.execute("""
                INSERT INTO caregiver_alerts (
                    caregiver_id,
                    elder_id,
                    dose_id,
                    alert_type,
                    message,
                    source
                )
                VALUES (?, ?, ?, 'missed_dose', ?, 'system')
            """, (
                dose["caregiver_id"],
                dose["elder_id"],
                dose["id"],
                "كبير السن لم يتناول الجرعة بعد انتهاء مهلة الاستجابة",
            ))

    conn.commit()
    conn.close()

    return updated_count

#تعديل بسيط على الجرعات المتأخرة
def get_missed_doses_for_caregiver(caregiver_id: int):
    """Return today's missed/no_response doses for all elders under this caregiver."""
    from datetime import datetime
    conn = get_connection()
    cursor = conn.cursor()
    today = datetime.now().strftime("%Y-%m-%d")

    cursor.execute("""
        SELECT
                   
            md.id AS dose_id,
            md.elder_id,
            md.scheduled_time,
            md.status,
            e.full_name AS elder_name,
            em.dosage_amount,
            em.dosage_unit,
            em.display_name_for_elder,
            mc.brand_name_ar,
            mc.med_category
        FROM medication_doses md
        JOIN elders e ON md.elder_id = e.id
        JOIN elder_medications em ON md.elder_medication_id = em.id
        JOIN medications_catalog mc ON em.catalog_medication_id = mc.id
        WHERE e.caregiver_id = ?
          AND md.dose_date = ?
          AND md.status IN ('missed', 'no_response')
        ORDER BY md.scheduled_time ASC
    """, (caregiver_id, today))

    rows = cursor.fetchall()
    conn.close()
    return rows


def get_weekly_adherence_summary(elder_id: int):
    """Return current week adherence data from Sunday to Saturday."""
    from datetime import datetime, timedelta

    conn = get_connection()
    cursor = conn.cursor()

    today = datetime.now().date()

    # Python weekday:
    # Monday = 0, Tuesday = 1, ..., Sunday = 6
    # We want the week to start on Sunday.
    days_since_sunday = (today.weekday() + 1) % 7

    week_start = today - timedelta(days=days_since_sunday)
    week_end = week_start + timedelta(days=6)

    week_start_str = week_start.strftime("%Y-%m-%d")
    week_end_str = week_end.strftime("%Y-%m-%d")

    cursor.execute("""
        WITH latest_logs AS (
            SELECT al.*
            FROM adherence_logs al
            JOIN (
                SELECT dose_id, MAX(id) AS latest_log_id
                FROM adherence_logs
                GROUP BY dose_id
            ) latest
            ON al.id = latest.latest_log_id
        )
        SELECT
            md.id AS dose_id,
            md.dose_date,
            md.scheduled_time,
            COALESCE(latest_logs.status, md.status) AS effective_status,
            mc.brand_name_ar,
            mc.med_category
        FROM medication_doses md
        LEFT JOIN latest_logs
            ON latest_logs.dose_id = md.id
        JOIN elder_medications em
            ON md.elder_medication_id = em.id
        JOIN medications_catalog mc
            ON em.catalog_medication_id = mc.id
        WHERE md.elder_id = ?
          AND md.dose_date BETWEEN ? AND ?
        ORDER BY md.dose_date ASC, md.scheduled_time ASC
    """, (elder_id, week_start_str, week_end_str))

    rows = cursor.fetchall()
    conn.close()

    counts = {
        "taken": 0,
        "missed": 0,
        "snoozed": 0,
        "no_response": 0,
        "pending": 0,
    }

    daily_map = {}

    for i in range(7):
        day = (week_start + timedelta(days=i)).strftime("%Y-%m-%d")
        daily_map[day] = {
            "date": day,
            "taken": 0,
            "missed": 0,
            "snoozed": 0,
            "no_response": 0,
            "pending": 0,
        }

    missed_map = {}
    missed_doses = []

    for row in rows:
        status = row["effective_status"] or "pending"
        dose_date = row["dose_date"]

        if status in counts:
            counts[status] += 1

        if dose_date in daily_map and status in daily_map[dose_date]:
            daily_map[dose_date][status] += 1

        if status in ("missed", "no_response"):
            brand_name = row["brand_name_ar"] or "دواء"
            med_category = row["med_category"] or ""

            key = (brand_name, med_category)

            if key not in missed_map:
                missed_map[key] = {
                    "brand_name_ar": brand_name,
                    "med_category": med_category,
                    "miss_count": 0,
                }

            missed_map[key]["miss_count"] += 1

            missed_doses.append({
                "brand_name_ar": brand_name,
                "med_category": med_category,
                "dose_date": row["dose_date"],
                "scheduled_time": row["scheduled_time"],
                "status": status,
            })

    total = sum(counts.values())
    taken = counts["taken"]
    adherence_pct = round((taken / total * 100), 1) if total > 0 else 0.0

    most_missed = sorted(
        missed_map.values(),
        key=lambda item: item["miss_count"],
        reverse=True,
    )[:5]

    daily_overview = list(daily_map.values())

    return {
        "elder_id": elder_id,
        "week_start": week_start_str,
        "week_end": week_end_str,
        "total_doses": total,
        "taken": taken,
        "missed": counts["missed"],
        "snoozed": counts["snoozed"],
        "no_response": counts["no_response"],
        "pending": counts["pending"],
        "adherence_percentage": adherence_pct,
        "most_missed_medications": most_missed,
        "daily_overview": daily_overview,
        "missed_doses": missed_doses,
    }