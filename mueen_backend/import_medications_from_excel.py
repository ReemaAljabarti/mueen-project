from __future__ import annotations

import sqlite3
from pathlib import Path

import pandas as pd


# Required columns that must exist in the Excel file
REQUIRED_COLUMNS = [
    "drug_id",
    "brand_name_ar",
    "generic_name_en",
    "dosage_strength",
    "dosage_form",
    "route_ar",
    "gtin",
    "uses_ar",
    "food_guide_ar",
    "med_category",
]


# Convert any Excel cell value into a clean string
# - Remove NaN
# - Trim spaces
def clean_text(value: object) -> str:
    if pd.isna(value):
        return ""

    return str(value).strip()


# Clean GTIN values
# - Keep as text, important for barcodes
# - Remove leading apostrophe added by Excel
def clean_gtin(value: object) -> str:
    cleaned = clean_text(value)

    if cleaned.startswith("'"):
        cleaned = cleaned[1:]

    return cleaned


# Ensure Excel contains all required columns
# Raises error if anything is missing
def validate_required_columns(dataframe: pd.DataFrame) -> None:
    missing_columns = [col for col in REQUIRED_COLUMNS if col not in dataframe.columns]

    if missing_columns:
        raise ValueError(
            f"Missing required columns in Excel file: {', '.join(missing_columns)}"
        )


# Clean and normalize the DataFrame before inserting
# - Keep only required columns
# - Clean text
# - Remove empty rows
# - Check duplicate IDs
def normalize_dataframe(dataframe: pd.DataFrame) -> pd.DataFrame:
    cleaned_df = dataframe[REQUIRED_COLUMNS].copy()
    cleaned_df = cleaned_df.dropna(how="all")

    for column in REQUIRED_COLUMNS:
        if column == "gtin":
            cleaned_df[column] = cleaned_df[column].apply(clean_gtin)
        else:
            cleaned_df[column] = cleaned_df[column].apply(clean_text)

    # Remove rows with empty drug_id
    cleaned_df = cleaned_df[cleaned_df["drug_id"] != ""]

    # Check for duplicate IDs
    duplicated_ids = cleaned_df[cleaned_df["drug_id"].duplicated()]["drug_id"].tolist()
    if duplicated_ids:
        raise ValueError(
            f"Duplicate drug_id values found in Excel file: {', '.join(duplicated_ids)}"
        )

    return cleaned_df


# Create medications_catalog table inside mueen.db
# This table is used by the assistant for search
def create_medications_catalog_table(connection: sqlite3.Connection) -> None:
    cursor = connection.cursor()

    cursor.execute(
        """
        CREATE TABLE IF NOT EXISTS medications_catalog (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            drug_id TEXT NOT NULL UNIQUE,
            brand_name_ar TEXT NOT NULL,
            generic_name_en TEXT NOT NULL,
            med_category TEXT,
            dosage_strength TEXT,
            dosage_form TEXT,
            route_ar TEXT,
            uses_ar TEXT,
            food_guide_ar TEXT,
            gtin TEXT
        )
        """
    )

    connection.commit()


# Clear only medication catalog data
# Do NOT touch elders, elder_medications, medication_doses, or adherence_logs
def clear_medications_catalog(connection: sqlite3.Connection) -> None:
    cursor = connection.cursor()
    cursor.execute("DELETE FROM medications_catalog")
    connection.commit()


# Insert cleaned Excel data into medications_catalog
def insert_medications_catalog(
    connection: sqlite3.Connection,
    dataframe: pd.DataFrame,
) -> None:
    cursor = connection.cursor()

    rows_to_insert = [
        (
            row["drug_id"],
            row["brand_name_ar"],
            row["generic_name_en"],
            row["med_category"],
            row["dosage_strength"],
            row["dosage_form"],
            row["route_ar"],
            row["uses_ar"],
            row["food_guide_ar"],
            row["gtin"],
        )
        for _, row in dataframe.iterrows()
    ]

    cursor.executemany(
        """
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
        """,
        rows_to_insert,
    )

    connection.commit()


# Print a quick verification row after import
def print_import_check(connection: sqlite3.Connection) -> None:
    cursor = connection.cursor()

    row = cursor.execute(
        """
        SELECT drug_id, brand_name_ar, uses_ar
        FROM medications_catalog
        WHERE drug_id = ?
        """,
        ("MU003",),
    ).fetchone()

    if row:
        print("Verification row:")
        print(f"drug_id: {row[0]}")
        print(f"brand_name_ar: {row[1]}")
        print(f"uses_ar: {row[2]}")
    else:
        print("Warning: MU003 was not found after import.")


# Main execution flow:
# 1. Read Excel
# 2. Validate + clean data
# 3. Connect to mueen.db
# 4. Create table if not exists
# 5. Clear old medications_catalog data only
# 6. Insert new data
def main() -> None:
    project_root = Path(__file__).resolve().parent

    # Excel source file in:
    # C:\flutter_projects\mueen-project\mueen_backend\mueen_drugs_db_v3.xlsx
    excel_path = project_root / "mueen_drugs_db_v3.xlsx"

    # Target unified database in:
    # C:\flutter_projects\mueen-project\mueen_backend\mueen.db
    db_path = project_root / "mueen.db"

    if not excel_path.exists():
        raise FileNotFoundError(f"Excel file not found: {excel_path}")

    if not db_path.exists():
        raise FileNotFoundError(f"Database file not found: {db_path}")

    dataframe = pd.read_excel(excel_path, sheet_name="mueen_drugs")

    validate_required_columns(dataframe)
    cleaned_df = normalize_dataframe(dataframe)

    connection = sqlite3.connect(db_path)

    try:
        create_medications_catalog_table(connection)
        clear_medications_catalog(connection)
        insert_medications_catalog(connection, cleaned_df)
        print_import_check(connection)
    finally:
        connection.close()

    print("Medication catalog imported successfully.")
    print(f"Excel path: {excel_path}")
    print(f"Database path: {db_path}")
    print("Target table: medications_catalog")
    print(f"Inserted rows: {len(cleaned_df)}")


if __name__ == "__main__":
    main()  