import sqlite3

DB_NAME = "mueen.db"
ELDER_ID = 1

DEMO_DOSES = [
    # 2026-04-27
    (1, 1, "09:00", "2026-04-27", "taken", 0, None, "2026-04-27 09:05:00", None, "2026-04-27 09:05:00", "2026-04-27 08:50:00"),
    (2, 1, "18:25", "2026-04-27", "missed", 0, None, None, "2026-04-27 18:40:00", "2026-04-27 18:40:00", "2026-04-27 18:10:00"),

    # 2026-04-28
    (3, 1, "18:30", "2026-04-28", "taken", 0, None, "2026-04-28 18:35:00", None, "2026-04-28 18:35:00", "2026-04-28 18:10:00"),
    (2, 1, "20:00", "2026-04-28", "missed", 0, None, None, "2026-04-28 20:15:00", "2026-04-28 20:15:00", "2026-04-28 19:50:00"),

    # 2026-04-29
    (8, 1, "18:30", "2026-04-29", "snoozed", 1, "19:00", None, None, "2026-04-29 18:32:00", "2026-04-29 18:10:00"),

    # 2026-04-30
    (12, 1, "06:35", "2026-04-30", "taken", 0, None, "2026-04-30 06:40:00", None, "2026-04-30 06:40:00", "2026-04-30 06:20:00"),
    (2, 1, "18:25", "2026-04-30", "missed", 0, None, None, "2026-04-30 18:45:00", "2026-04-30 18:45:00", "2026-04-30 18:10:00"),

    # 2026-05-01
    (14, 1, "10:45", "2026-05-01", "taken", 0, None, "2026-05-01 10:50:00", None, "2026-05-01 10:50:00", "2026-05-01 10:30:00"),

    # 2026-05-02
    (2, 1, "18:25", "2026-05-02", "missed", 0, None, None, "2026-05-02 18:45:00", "2026-05-02 18:45:00", "2026-05-02 18:10:00"),

    # 2026-05-03
    (17, 1, "16:50", "2026-05-03", "taken", 0, None, "2026-05-03 16:55:00", None, "2026-05-03 16:55:00", "2026-05-03 16:35:00"),
]


def main():
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    # احذف بيانات الاختبار لنفس الأسبوع فقط حتى لا تتكرر
    cursor.execute(
        """
        DELETE FROM medication_doses
        WHERE elder_id = ?
          AND dose_date BETWEEN '2026-04-27' AND '2026-05-03'
        """,
        (ELDER_ID,),
    )

    cursor.executemany(
        """
        INSERT INTO medication_doses (
            elder_medication_id,
            elder_id,
            scheduled_time,
            dose_date,
            status,
            snooze_count,
            snoozed_until,
            taken_at,
            missed_at,
            last_updated_at,
            created_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        DEMO_DOSES,
    )

    conn.commit()

    cursor.execute(
        """
        SELECT status, COUNT(*) AS count
        FROM medication_doses
        WHERE elder_id = ?
          AND dose_date BETWEEN '2026-04-27' AND '2026-05-03'
        GROUP BY status
        """,
        (ELDER_ID,),
    )

    print("Weekly demo doses inserted successfully.")
    for row in cursor.fetchall():
        print(f"{row['status']}: {row['count']}")

    conn.close()


if __name__ == "__main__":
    main()