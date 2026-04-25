import sqlite3
import pandas as pd
from database import init_db

DB_NAME = "mueen.db"
EXCEL_PATH = "COPY Mu’een Medications DB v2.xlsx"
SHEET_NAME = "mueen_drugs"


def import_medications():
    df = pd.read_excel(EXCEL_PATH, sheet_name=SHEET_NAME)

    # تنظيف أسماء الأعمدة
    df.columns = [col.strip() for col in df.columns]

    required_columns = [
        "drug_id",
        "brand_name_ar",
        "generic_name_en",
        "med_category",
        "dosage_strength",
        "dosage_form",
        "route_ar",
        "uses_ar",
        "food_guide_ar",
        "gtin",
    ]

    missing = [col for col in required_columns if col not in df.columns]
    if missing:
        raise ValueError(f"Missing required columns: {missing}")

    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()

    # حذف البيانات القديمة قبل إعادة الاستيراد
    cursor.execute("DELETE FROM medications_catalog")

    for _, row in df.iterrows():
        cursor.execute("""
            INSERT INTO medications_catalog (
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
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            str(row["drug_id"]).strip() if pd.notna(row["drug_id"]) else None,
            str(row["brand_name_ar"]).strip() if pd.notna(row["brand_name_ar"]) else "",
            str(row["generic_name_en"]).strip() if pd.notna(row["generic_name_en"]) else None,
            str(row["med_category"]).strip() if pd.notna(row["med_category"]) else None,
            str(row["dosage_strength"]).strip() if pd.notna(row["dosage_strength"]) else None,
            str(row["dosage_form"]).strip() if pd.notna(row["dosage_form"]) else None,
            str(row["route_ar"]).strip() if pd.notna(row["route_ar"]) else None,
            str(row["uses_ar"]).strip() if pd.notna(row["uses_ar"]) else None,
            str(row["food_guide_ar"]).strip() if pd.notna(row["food_guide_ar"]) else None,
            str(row["gtin"]).strip() if pd.notna(row["gtin"]) else None,
        ))

    conn.commit()
    conn.close()

    print(f"Imported {len(df)} medications into medications_catalog")


if __name__ == "__main__":
    init_db()
    import_medications()