import sqlite3

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
    conn.close()


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
            mc.gtin
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
    conn = get_connection()
    cursor = conn.cursor()

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

    conn.commit()
    updated_count = cursor.rowcount
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