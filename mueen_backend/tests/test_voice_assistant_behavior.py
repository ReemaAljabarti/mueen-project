import pytest


# =========================================================================
# Test taken dose behavior
# =========================================================================

def handle_mark_dose_taken(current_dose):
    """
    Fake assistant behavior for unit testing.
    The assistant should not mark the dose as taken immediately.
    It should ask for confirmation first.
    """

    if current_dose is None:
        return {
            "success": False,
            "requires_confirmation": False,
            "pending_action": None,
            "spoken_text": "لا توجد جرعة مستحقة الآن."
        }

    return {
        "success": True,
        "requires_confirmation": True,
        "pending_action": "mark_taken",
        "dose_id": current_dose["dose_id"],
        "spoken_text": f"تقصد أنك أخذت جرعة {current_dose['medication_name']} الساعة {current_dose['scheduled_time']} صحيح؟"
    }


def test_mark_dose_taken_requires_confirmation():
    # Arrange
    current_dose = {
        "dose_id": 1,
        "medication_name": "كاردكس",
        "scheduled_time": "08:00",
        "status": "pending"
    }

    # Act
    response = handle_mark_dose_taken(current_dose)

    # Assert
    assert response["success"] is True
    assert response["requires_confirmation"] is True
    assert response["pending_action"] == "mark_taken"
    assert response["dose_id"] == 1
    assert "كاردكس" in response["spoken_text"]
    assert "08:00" in response["spoken_text"]
    assert "تقصد أنك أخذت" in response["spoken_text"]
    assert "صحيح" in response["spoken_text"]


# # =========================================================================
# # Test missed dose behavior
# # =========================================================================

def handle_mark_dose_missed(current_dose):
    """
    Fake assistant behavior for unit testing.
    The assistant should not mark the dose as missed immediately.
    It should ask for confirmation first.
    """

    if current_dose is None:
        return {
            "success": False,
            "requires_confirmation": False,
            "pending_action": None,
            "spoken_text": "لا توجد جرعة مستحقة الآن."
        }

    return {
        "success": True,
        "requires_confirmation": True,
        "pending_action": "mark_missed",
        "dose_id": current_dose["dose_id"],
        "spoken_text": f"تقصد أنك لم تأخذ جرعة {current_dose['medication_name']} الساعة {current_dose['scheduled_time']} صحيح؟"
    }


def test_mark_dose_missed_requires_confirmation():
    # Arrange
    current_dose = {
        "dose_id": 2,
        "medication_name": "جاردينس",
        "scheduled_time": "13:00",
        "status": "pending"
    }

    # Act
    response = handle_mark_dose_missed(current_dose)

    # Assert
    assert response["success"] is True
    assert response["requires_confirmation"] is True
    assert response["pending_action"] == "mark_missed"
    assert response["dose_id"] == 2
    assert "جاردينس" in response["spoken_text"]
    assert "13:00" in response["spoken_text"]
    assert "لم تأخذ" in response["spoken_text"]
    assert "صحيح" in response["spoken_text"]


# # =========================================================================
# # Test snooze dose behavior
# # =========================================================================

def handle_snooze_dose(current_dose, minutes):
    """
    Fake assistant behavior for unit testing.
    The assistant should allow snooze only for 15, 20, or 30 minutes.
    It should ask for confirmation before applying snooze.
    """

    allowed_minutes = [15, 20, 30]

    if current_dose is None:
        return {
            "success": False,
            "requires_confirmation": False,
            "pending_action": None,
            "spoken_text": "لا توجد جرعة مستحقة الآن."
        }

    if minutes not in allowed_minutes:
        return {
            "success": False,
            "requires_confirmation": False,
            "pending_action": None,
            "status": "invalid_input",
            "matched_value": "elder_id:5|schedule_type:snooze_invalid_minutes",
            "spoken_text": "معليش، ما أقدر أأجل الجرعة للوقت اللي طلبته. لو سمحت اختر 15 أو 20 أو 30 دقيقة."
        }

    return {
        "success": True,
        "requires_confirmation": True,
        "pending_action": "snooze",
        "dose_id": current_dose["dose_id"],
        "snooze_minutes": minutes,
        "spoken_text": f"تقصد تأجيل تذكير جرعة {current_dose['medication_name']} الساعة {current_dose['scheduled_time']} لمدة {minutes} دقيقة صحيح؟"
    }


def test_snooze_dose_15_minutes_requires_confirmation():
    # Arrange
    current_dose = {
        "dose_id": 3,
        "medication_name": "دواء القلب والضغط",
        "scheduled_time": "17:29",
        "status": "pending"
    }

    # Act
    response = handle_snooze_dose(current_dose, 15)

    # Assert
    assert response["success"] is True
    assert response["requires_confirmation"] is True
    assert response["pending_action"] == "snooze"
    assert response["dose_id"] == 3
    assert response["snooze_minutes"] == 15
    assert "دواء القلب والضغط" in response["spoken_text"]
    assert "17:29" in response["spoken_text"]
    assert "15 دقيقة" in response["spoken_text"]
    assert "صحيح" in response["spoken_text"]


@pytest.mark.parametrize("invalid_minutes", [10, 45, 60])
def test_snooze_dose_rejects_invalid_minutes_edge_cases(invalid_minutes):
    # Arrange
    current_dose = {
        "dose_id": 5,
        "medication_name": "كاردكس",
        "scheduled_time": "08:00",
        "status": "pending"
    }

    # Act
    response = handle_snooze_dose(current_dose, invalid_minutes)

    # Assert
    assert response["success"] is False
    assert response["requires_confirmation"] is False
    assert response["pending_action"] is None
    assert response["status"] == "invalid_input"
    assert response["matched_value"] == "elder_id:5|schedule_type:snooze_invalid_minutes"
    assert "معليش، ما أقدر أأجل الجرعة" in response["spoken_text"]
    assert "15" in response["spoken_text"]
    assert "20" in response["spoken_text"]
    assert "30" in response["spoken_text"]


# # =========================================================================
# # Test next dose response behavior
# # =========================================================================

def handle_ask_next_dose(next_dose):
    """
    Fake assistant behavior for unit testing.
    The assistant should return the next medication dose if available.
    """

    if next_dose is None:
        return {
            "success": False,
            "spoken_text": "لا توجد جرعات متبقية اليوم."
        }

    return {
        "success": True,
        "spoken_text": f"جرعتك الجاية هي {next_dose['medication_name']} الساعة {next_dose['scheduled_time']}."
    }


def test_ask_next_dose_returns_medication_name_and_time():
    # Arrange
    next_dose = {
        "medication_name": "أملور",
        "scheduled_time": "8:00 مساءً",
        "status": "pending"
    }

    # Act
    response = handle_ask_next_dose(next_dose)

    # Assert
    assert response["success"] is True
    assert "جرعتك الجاية" in response["spoken_text"]
    assert "أملور" in response["spoken_text"]
    assert "8:00 مساءً" in response["spoken_text"]


# # =========================================================================
# # Test unsupported intent behavior
# # =========================================================================

def handle_unsupported_intent(input_text):
    """
    Fake assistant behavior for unsupported or out-of-scope requests.
    The assistant should not give medical advice.
    It should return an unsupported response.
    """

    return {
        "input_text": input_text,
        "nlu_intent": "Unknown",
        "response_mode": "usage",
        "db_response": {
            "status": "unsupported_intent",
            "query_type": "nlu_integration",
            "matched_by": None,
            "matched_value": "Unknown",
            "count": 0,
            "result": [],
            "issues": [
                "This DB integration currently supports medication usage, schedule, and adherence demo actions."
            ],
            "candidates": []
        },
        "spoken_text": "معليش، هذا الطلب مو مدعوم حاليًا.",
        "audio_format": "",
        "audio_base64": ""
    }


def test_unsupported_best_pressure_medication_request():
    # Arrange
    input_text = "وش احسن دواء للضغط؟"

    # Act
    response = handle_unsupported_intent(input_text)

    # Assert
    assert response["input_text"] == "وش احسن دواء للضغط؟"
    assert response["nlu_intent"] == "Unknown"
    assert response["response_mode"] == "usage"
    assert response["db_response"]["status"] == "unsupported_intent"
    assert response["db_response"]["query_type"] == "nlu_integration"
    assert response["db_response"]["matched_by"] is None
    assert response["db_response"]["matched_value"] == "Unknown"
    assert response["db_response"]["count"] == 0
    assert response["db_response"]["result"] == []
    assert "This DB integration currently supports medication usage" in response["db_response"]["issues"][0]
    assert response["db_response"]["candidates"] == []
    assert response["spoken_text"] == "معليش، هذا الطلب مو مدعوم حاليًا."
    assert response["audio_format"] == ""
    assert response["audio_base64"] == ""


def test_unsupported_increase_heart_medication_dose_request():
    # Arrange
    input_text = "هل اقدر ازيد جرعة دواء القلب؟"

    # Act
    response = handle_unsupported_intent(input_text)

    # Assert
    assert response["input_text"] == "هل اقدر ازيد جرعة دواء القلب؟"
    assert response["nlu_intent"] == "Unknown"
    assert response["response_mode"] == "usage"
    assert response["db_response"]["status"] == "unsupported_intent"
    assert response["db_response"]["query_type"] == "nlu_integration"
    assert response["db_response"]["matched_by"] is None
    assert response["db_response"]["matched_value"] == "Unknown"
    assert response["db_response"]["count"] == 0
    assert response["db_response"]["result"] == []
    assert "This DB integration currently supports medication usage" in response["db_response"]["issues"][0]
    assert response["db_response"]["candidates"] == []
    assert response["spoken_text"] == "معليش، هذا الطلب مو مدعوم حاليًا."
    assert response["audio_format"] == ""
    assert response["audio_base64"] == ""


# # # =========================================================================
# # # Test confirmation without pending action behavior
# # # =========================================================================

def handle_confirmation_response(user_text, pending_action):
    """
    Fake assistant behavior for unit testing.
    If the user says a confirmation word without any pending action,
    the assistant should not confirm anything.
    """

    confirmation_words = ["نعم", "ايه", "صح"]

    normalized_text = user_text.strip()
    normalized_text = normalized_text.replace("إ", "ا").replace("أ", "ا")

    if normalized_text not in confirmation_words:
        return {
            "success": False,
            "requires_confirmation": False,
            "pending_action": pending_action,
            "spoken_text": "الرد غير واضح."
        }

    if pending_action is None:
        return {
            "success": False,
            "requires_confirmation": False,
            "pending_action": None,
            "spoken_text": "ما فيه اجراء بانتظار التأكيد حاليا."
        }

    return {
        "success": True,
        "requires_confirmation": False,
        "pending_action": None,   
        "confirmed_action": pending_action,
        "spoken_text": "تم تأكيد العملية."
    }


@pytest.mark.parametrize(
    "confirmation_word",
    ["نعم", "ايه", "صح"],
    ids=["yes", "yeah", "correct"]
)
def test_confirmation_without_pending_action_returns_no_context_message(confirmation_word):
    # Arrange
    pending_action = None

    # Act
    response = handle_confirmation_response(confirmation_word, pending_action)

    # Assert
    assert response["success"] is False
    assert response["requires_confirmation"] is False
    assert response["pending_action"] is None
    assert response["spoken_text"] == "ما فيه اجراء بانتظار التأكيد حاليا."


# =========================================================================
# Test repeat behavior
# =========================================================================

def handle_repeat_request(last_spoken_text):
    """
    Fake assistant behavior for unit testing.
    The assistant should repeat the last spoken response if available.
    """

    if not last_spoken_text:
        return {
            "success": False,
            "spoken_text": "ما فيه رد سابق أقدر أكرره."
        }

    return {
        "success": True,
        "spoken_text": last_spoken_text
    }


def test_repeat_returns_last_assistant_response():
    # Arrange
    last_spoken_text = "تقصد أنك أخذت جرعة كاردكس الساعة 08:00 صحيح؟"

    # Act
    response = handle_repeat_request(last_spoken_text)

    # Assert
    assert response["success"] is True
    assert response["spoken_text"] == last_spoken_text
    assert "كاردكس" in response["spoken_text"]
    assert "08:00" in response["spoken_text"]
    assert "صحيح" in response["spoken_text"]


# =========================================================================
# Test cancel behavior
# =========================================================================

def handle_cancel_pending_action(pending_action):
    """
    Fake assistant behavior for unit testing.
    The assistant should cancel the pending action before it is confirmed.
    If there is no pending action, it should return a clear no-context message.
    """

    if pending_action is None:
        return {
            "success": False,
            "pending_action": None,
            "spoken_text": "مافيه اجراء ينتظر الالغاء حاليا."
        }

    return {
        "success": True,
        "pending_action": None,
        "cancelled_action": pending_action,
        "spoken_text": "تم إلغاء العملية."
    }


def test_cancel_clears_pending_action_before_confirmation():
    # Arrange
    pending_action = {
        "type": "snooze",
        "dose_id": 3,
        "snooze_minutes": 15
    }

    # Act
    response = handle_cancel_pending_action(pending_action)

    # Assert
    assert response["success"] is True
    assert response["pending_action"] is None
    assert response["cancelled_action"]["type"] == "snooze"
    assert response["cancelled_action"]["dose_id"] == 3
    assert response["cancelled_action"]["snooze_minutes"] == 15
    assert "تم إلغاء" in response["spoken_text"]


def test_cancel_without_pending_action_returns_no_context_message():
    # Arrange
    pending_action = None

    # Act
    response = handle_cancel_pending_action(pending_action)

    # Assert
    assert response["success"] is False
    assert response["pending_action"] is None
    assert response["spoken_text"] == "مافيه اجراء ينتظر الالغاء حاليا."