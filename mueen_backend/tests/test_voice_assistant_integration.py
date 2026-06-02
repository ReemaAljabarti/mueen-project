# NOTE:
# This is a real-time integration test, not a fixed unit test.
# It sends actual HTTP requests to the running FastAPI backend and checks
# the assistant response based on the current medication data stored for the test elder.
#
# Because dose-related responses depend on the current date, current time,
# and the dose status in the database, some tests will only pass when the
# test elder has an active or pending dose at the time of execution.
#
# If the test is run at a different time, or if the elder medication schedule
# has been changed, the assistant may return a different valid response,
# causing the test to fail even if the backend logic is working correctly.
#
# Before running this test, make sure that:
# 1. The FastAPI backend is running.
# 2. The ELDER_ID belongs to a real test elder account.
# 3. The expected medications and dose times exist in the database.
# 4. Dose-action tests are executed when a current/pending dose is available.

import requests

BASE_URL = "http://127.0.0.1:8001"

# Replace this with the real elder_id for the test elder account.
ELDER_ID = 6

TIMEOUT = 60


EXPECTED_DOSES = [
    {
        "name": "دواء القلب",
        "times": ["10:20", "١٠:٢٠", "22:20", "١٠:٢٠ مساء", "10:20 مساء"],
    },
    {
        "name": "دواء الكوليسترول",
        "times": ["10:45", "١٠:٤٥", "22:45", "١٠:٤٥ مساء", "10:45 مساء"],
    },
    {
        "name": "دواء المعدة",
        "times": ["11:05", "١١:٠٥", "23:05", "١١:٠٥ مساء", "11:05 مساء"],
    },
    {
        "name": "باكلون",
        "times": ["11:35", "١١:٣٥", "23:35", "١١:٣٥ مساء", "11:35 مساء"],
    },
]


def assistant_request(text: str):
    response = requests.post(
        f"{BASE_URL}/assistant/respond-text",
        params={
            "include_audio": False
        },
        json={
            "text": text,
            "elder_id": ELDER_ID
        },
        timeout=120,
    )

    data = response.json()

    safe_data = data.copy()
    if "audio_base64" in safe_data:
        safe_data["audio_base64"] = "<hidden audio>"
    if "audio" in safe_data:
        safe_data["audio"] = "<hidden audio>"

    print("\nUser input:", text)
    print("Status code:", response.status_code)
    print("Assistant response:", safe_data)

    assert response.status_code == 200
    assert "nlu_intent" in data
    assert "spoken_text" in data

    return data

def contains_any(text: str, expected_values: list[str]) -> bool:
    return any(value in text for value in expected_values)


def contains_any_expected_dose(text: str) -> bool:
    for dose in EXPECTED_DOSES:
        if dose["name"] in text:
            return True

        if contains_any(text, dose["times"]):
            return True

    return False


def test_ask_next_dose_returns_one_of_today_doses():
    data = assistant_request("متى جرعتي الجاية؟")

    assert data["nlu_intent"] == "AskNextDose"
    assert "جرعتك الجاية" in data["spoken_text"]
    assert contains_any_expected_dose(data["spoken_text"])


def test_ask_today_schedule_returns_current_medications():
    data = assistant_request("وش عندي أدوية اليوم؟")

    assert data["nlu_intent"] == "AskTodaySchedule"

    assert (
        "دواء القلب" in data["spoken_text"]
        or "دواء الكوليسترول" in data["spoken_text"]
        or "دواء المعدة" in data["spoken_text"]
        or "باكلون" in data["spoken_text"]
    )


def test_medication_usage_for_stomach_medicine():
    data = assistant_request("وش استخدام دواء المعدة؟")

    assert data["nlu_intent"] == "AskMedicationUsage"

    assert (
        "المعدة" in data["spoken_text"]
        or "الحموضة" in data["spoken_text"]
        or "ارتجاع" in data["spoken_text"]
        or "اضطراب" in data["spoken_text"]
    )


def test_medication_usage_for_cholesterol_medicine():
    data = assistant_request("وش استخدام دواء الكوليسترول؟")

    assert data["nlu_intent"] == "AskMedicationUsage"

    assert (
        "الكوليسترول" in data["spoken_text"]
        or "الدهون" in data["spoken_text"]
        or "القلب" in data["spoken_text"]
    )


def test_mark_dose_taken_asks_for_confirmation():
    data = assistant_request("أخذت الجرعة")

    assert data["nlu_intent"] == "MarkDoseTaken"

    assert (
        "تقصد" in data["spoken_text"]
        and "أخذت" in data["spoken_text"]
        and "صحيح" in data["spoken_text"]
    )


def test_confirm_updates_dose_to_taken():
    first_data = assistant_request("أخذت الجرعة")

    assert first_data["nlu_intent"] == "MarkDoseTaken"

    second_data = assistant_request("نعم")

    assert second_data["nlu_intent"] == "Confirm"

    assert (
        "تم" in second_data["spoken_text"]
        or "أخذت" in second_data["spoken_text"]
        or "تسجيل" in second_data["spoken_text"]
    )


def test_snooze_15_minutes_asks_for_confirmation():
    data = assistant_request("أجل الجرعة 15 دقيقة")

    assert data["nlu_intent"] == "SnoozeMedication"

    assert (
        "تقصد" in data["spoken_text"]
        or "تأجيل" in data["spoken_text"]
        or "صحيح" in data["spoken_text"]
        or "15" in data["spoken_text"]
        or "١٥" in data["spoken_text"]
    )


def test_confirm_snoozes_dose_15_minutes():
    first_data = assistant_request("أجل الجرعة 15 دقيقة")

    assert first_data["nlu_intent"] == "SnoozeMedication"

    second_data = assistant_request("نعم")

    assert second_data["nlu_intent"] == "Confirm"

    assert (
        "تم" in second_data["spoken_text"]
        or "تأجيل" in second_data["spoken_text"]
        or "15" in second_data["spoken_text"]
        or "١٥" in second_data["spoken_text"]
    )


def test_mark_dose_missed_asks_for_confirmation():
    data = assistant_request("ما أخذت الجرعة")

    assert data["nlu_intent"] == "MarkDoseMissed"

    assert (
        "تقصد" in data["spoken_text"]
        or "لم تأخذ" in data["spoken_text"]
        or "ما أخذت" in data["spoken_text"]
        or "صحيح" in data["spoken_text"]
    )


def test_confirm_marks_dose_as_missed():
    first_data = assistant_request("ما أخذت الجرعة")

    assert first_data["nlu_intent"] == "MarkDoseMissed"

    second_data = assistant_request("نعم")

    assert second_data["nlu_intent"] == "Confirm"

    assert (
        "تم" in second_data["spoken_text"]
        or "لم يتم أخذ" in second_data["spoken_text"]
        or "فائتة" in second_data["spoken_text"]
        or "missed" in second_data["spoken_text"]
    )