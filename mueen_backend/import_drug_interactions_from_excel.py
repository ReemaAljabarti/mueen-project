import sqlite3
import pandas as pd
from database import init_db

DB_NAME = "mueen.db"
EXCEL_PATH = r"C:\mueen\mueen_backend\drug interactions.xlsx"
SHEET_NAME = 0  # أول شيت في الملف


def normalize_drug_id(value):
    if pd.isna(value):
        return None

    value = str(value).strip().upper()

    if not value.startswith("MU"):
        return value

    digits = "".join(ch for ch in value[2:] if ch.isdigit())
    if not digits:
        return value

    return f"MU{int(digits):03d}"


def import_drug_interactions():
    df = pd.read_excel(EXCEL_PATH, sheet_name=SHEET_NAME)

    # تنظيف أسماء الأعمدة
    df.columns = [col.strip() for col in df.columns]

    required_columns = [
        "drug_id",
        "interacts_with_drug_id",
        "severity",
        "note_ar",
    ]

    missing = [col for col in required_columns if col not in df.columns]
    if missing:
        raise ValueError(f"Missing required columns: {missing}")

    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()

    # حذف البيانات القديمة قبل إعادة الاستيراد
    cursor.execute("DELETE FROM drug_interactions")

    for _, row in df.iterrows():
        cursor.execute("""
            INSERT INTO drug_interactions (
                drug_id,
                interacts_with_drug_id,
                severity,
                note_ar
            )
            VALUES (?, ?, ?, ?)
        """, (
            normalize_drug_id(row["drug_id"]),
            normalize_drug_id(row["interacts_with_drug_id"]),
            str(row["severity"]).strip().upper() if pd.notna(row["severity"]) else None,
            str(row["note_ar"]).strip() if pd.notna(row["note_ar"]) else None,
        ))

    conn.commit()
    conn.close()

    print(f"Imported {len(df)} interactions into drug_interactions")


if __name__ == "__main__":
    init_db()
    import_drug_interactions()