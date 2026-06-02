from __future__ import annotations

import json
import re
from pathlib import Path

from app.db_schemas import DbRetrievalResponse
from app.services.db_category_resolver import resolve_med_category
from app.services.db_medication_queries import (
    get_current_due_elder_dose,
    mark_dose_missed as mark_dose_missed_by_id,
    mark_dose_taken as mark_dose_taken_by_id,
    snooze_dose as snooze_dose_by_id,
)
from app.services.db_medication_service import (
    retrieve_adherence_status,
    retrieve_elder_medication_by_name,
    retrieve_medication_by_name,
    retrieve_medications_by_category,
    retrieve_next_dose,
    retrieve_remaining_doses,
    retrieve_today_schedule,
)
from app.services.dialogue_state_service import dialogue_state_service


_RESOURCE_PATH = (
    Path(__file__).parent.parent / "nlu" / "resources" / "food_guide_markers.json"
)


# Load food-guide markers from JSON resource file
def load_food_guide_markers() -> list[str]:
    with open(_RESOURCE_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)

    return data.get("food_guide_markers", [])


# Shared food-guide markers
FOOD_GUIDE_MARKERS = load_food_guide_markers()


# Check if text asks for food-related medication instructions
def _contains_food_guide_marker(text: str) -> bool:
    for marker in FOOD_GUIDE_MARKERS:
        if marker in text:
            return True

    return False


# Infer response type from text if NLU does not provide INFO_TYPE
def _infer_info_type_from_text(normalized_text: str | None) -> str:
    text = (normalized_text or "").strip()

    if _contains_food_guide_marker(text):
        return "food_guide"

    return "usage"


# Determine whether the assistant should return usage or food guide
def infer_response_mode(
    slots: dict,
    normalized_text: str | None = None,
) -> str:
    raw_info_type = slots.get("INFO_TYPE")

    if isinstance(raw_info_type, str) and raw_info_type.strip() in {
        "usage",
        "food_guide",
    }:
        return raw_info_type.strip()

    return _infer_info_type_from_text(normalized_text)


# Extract elder_id from slots with a safe demo fallback
def _get_elder_id_from_slots(slots: dict) -> int:
    raw_elder_id = slots.get("ELDER_ID") or slots.get("elder_id")

    try:
        if raw_elder_id is not None:
            return int(raw_elder_id)
    except (TypeError, ValueError):
        pass

    return 1


# Extract snooze minutes from slots or normalized text.
# Allowed values are only 15, 20, or 30.
# If the user does not mention a duration, default to 15.
# If the user mentions an unsupported duration, return -1.
def _get_snooze_minutes_from_slots(
    slots: dict,
    normalized_text: str | None = None,
) -> int:
    possible_keys = [
        "MINUTES",
        "SNOOZE_MINUTES",
        "DURATION_MINUTES",
        "minutes",
        "snooze_minutes",
    ]

    for key in possible_keys:
        raw_value = slots.get(key)

        if raw_value is None:
            continue

        raw_text = str(raw_value).strip()
        match = re.search(r"\d+", raw_text)

        if not match:
            continue

        minutes = int(match.group(0))

        if minutes in {15, 20, 30}:
            return minutes

        return -1

    text = (normalized_text or "").strip()
    text_match = re.search(r"\d+", text)

    if text_match:
        minutes = int(text_match.group(0))

        if minutes in {15, 20, 30}:
            return minutes

        return -1

    return 15


# Build unsupported-intent response using the existing DB response contract
def _build_unsupported_intent_response(intent: str) -> DbRetrievalResponse:
    return DbRetrievalResponse(
        status="unsupported_intent",
        query_type="nlu_integration",
        matched_by=None,
        matched_value=intent or "",
        count=0,
        result=[],
        issues=[
            "This DB integration currently supports medication usage, schedule, and adherence demo actions."
        ],
        candidates=[],
    )


# Read a value safely from dict-like results or normal objects
def _read_value(source: object, key: str, default: object = None) -> object:
    if source is None:
        return default

    if isinstance(source, dict):
        return source.get(key, default)

    return getattr(source, key, default)


# Clean text before storing it in dialogue state
def _clean_text(value: object) -> str:
    if value is None:
        return ""

    text = str(value).strip()

    if not text:
        return ""

    return " ".join(text.split())


# Get a readable medication name from a dose row
def _get_dose_medication_name(dose: dict) -> str:
    return (
        _clean_text(dose.get("display_name_for_elder"))
        or _clean_text(dose.get("brand_name_ar"))
        or "الجرعة"
    )


# Get a readable dose time from a dose row
def _get_dose_time(dose: dict) -> str:
    return (
        _clean_text(dose.get("scheduled_time"))
        or _clean_text(dose.get("first_reminder_time"))
        or "غير محدد"
    )

#=============================================================

# Get the time that should be shown when talking about snooze.
# For snoozed doses, use snoozed_until instead of the original scheduled_time.
def _get_snooze_reference_time(dose: dict) -> str:
    snoozed_until = _clean_text(dose.get("snoozed_until"))

    if snoozed_until:
        return snoozed_until

    return _get_dose_time(dose)


# Build a dialogue response using the same DB response contract
def _build_dialogue_action_response(
    elder_id: int,
    schedule_type: str,
    message: str,
    status: str = "success",
    medication_name: str = "",
    issues: list[str] | None = None,
) -> DbRetrievalResponse:
    result = []

    if status == "success":
        result = [
            {
                "brand_name_ar": medication_name,
                "uses_ar": message,
                "food_guide_ar": None,
            }
        ]

    return DbRetrievalResponse(
        status=status,
        query_type="nlu_integration",
        matched_by="med_category",
        matched_value=f"elder_id:{elder_id}|schedule_type:{schedule_type}",
        count=len(result),
        result=result,
        issues=issues or [],
        candidates=[],
    )


# Build a confirmation response and store the pending action
def _build_pending_confirmation_response(
    elder_id: int,
    dose: dict,
    action_type: str,
    schedule_type: str,
    message: str,
    minutes: int | None = None,
) -> DbRetrievalResponse:
    dose_id = int(dose["dose_id"])
    medication_name = _get_dose_medication_name(dose)
    dose_time = _get_dose_time(dose)

    dialogue_state_service.set_pending_action(
        elder_id=elder_id,
        action_type=action_type,
        dose_id=dose_id,
        medication_name=medication_name,
        dose_time=dose_time,
        minutes=minutes,
        message=message,
        metadata={
            "schedule_type": schedule_type,
            "dose_id": dose_id,
        },
    )

    return _build_dialogue_action_response(
        elder_id=elder_id,
        schedule_type=schedule_type,
        message=message,
        medication_name=medication_name,
    )


# Prepare a confirmation response for marking the current dose as taken
def _prepare_mark_taken_confirmation(elder_id: int) -> DbRetrievalResponse:
    dose = get_current_due_elder_dose(elder_id)

    if not dose:
        return _build_dialogue_action_response(
            elder_id=elder_id,
            schedule_type="mark_taken",
            message="",
            status="not_found",
            issues=["No current due dose found to confirm as taken."],
        )

    medication_name = _get_dose_medication_name(dose)
    dose_time = _get_dose_time(dose)
    message = f"تقصد أنك أخذت {medication_name}، جرعة الساعة {dose_time}، صحيح؟"

    return _build_pending_confirmation_response(
        elder_id=elder_id,
        dose=dose,
        action_type="mark_taken",
        schedule_type="confirm_mark_taken",
        message=message,
    )


# Prepare a confirmation response for marking the current dose as missed
def _prepare_mark_missed_confirmation(elder_id: int) -> DbRetrievalResponse:
    dose = get_current_due_elder_dose(elder_id)

    if not dose:
        return _build_dialogue_action_response(
            elder_id=elder_id,
            schedule_type="mark_missed",
            message="",
            status="not_found",
            issues=["No current due dose found to confirm as missed."],
        )

    medication_name = _get_dose_medication_name(dose)
    dose_time = _get_dose_time(dose)
    message = f"تقصد أن جرعة {medication_name} الساعة {dose_time} فاتتك، صحيح؟"

    return _build_pending_confirmation_response(
        elder_id=elder_id,
        dose=dose,
        action_type="mark_missed",
        schedule_type="confirm_mark_missed",
        message=message,
    )

#===============================================================
# Prepare a confirmation response for snoozing the current dose
def _prepare_snooze_confirmation(
    elder_id: int,
    minutes: int,
) -> DbRetrievalResponse:
    if minutes not in {15, 20, 30}:
        return _build_dialogue_action_response(
            elder_id=elder_id,
            schedule_type="snooze_invalid_minutes",
            message="معليش، ما أقدر أأجل الجرعة للوقت اللي طلبته. لو سمحت اختر 15 أو 20 أو 30 دقيقة.",
            status="invalid_input",
            issues=["Invalid snooze minutes."],
        )

    dose = get_current_due_elder_dose(elder_id)

    if not dose:
        return _build_dialogue_action_response(
            elder_id=elder_id,
            schedule_type="snooze",
            message="",
            status="not_found",
            issues=["No current due dose found to snooze."],
        )

    medication_name = _get_dose_medication_name(dose)
    snooze_reference_time = _get_snooze_reference_time(dose)

    if int(dose.get("snooze_count") or 0) >= 1:
        updated_dose = snooze_dose_by_id(int(dose["dose_id"]), minutes)

        if not updated_dose:
            return _build_dialogue_action_response(
                elder_id=elder_id,
                schedule_type="snooze_already_used",
                message="",
                status="not_found",
                issues=["Dose not found while handling second snooze attempt."],
            )

        medication_name = _get_dose_medication_name(updated_dose)
        snooze_reference_time = _get_snooze_reference_time(updated_dose)

        message = (
            f"تم استخدام التأجيل لجرعة {medication_name} من قبل إلى الساعة {snooze_reference_time}، "
            "ولا يمكن تأجيلها مرة ثانية. تم تسجيل الجرعة كفائتة."
        )

        return _build_dialogue_action_response(
            elder_id=elder_id,
            schedule_type="snooze_already_used",
            message=message,
            medication_name=medication_name,
        )

    message = (
        f"تقصد تأجيل تذكير {medication_name}، جرعة الساعة {snooze_reference_time}، "
        f"لمدة {minutes} دقيقة، صحيح؟"
    )

    return _build_pending_confirmation_response(
        elder_id=elder_id,
        dose=dose,
        action_type="snooze",
        schedule_type=f"confirm_snooze|minutes:{minutes}",
        message=message,
        minutes=minutes,
    )

#===============================================================
# Execute a confirmed taken action
def _execute_confirmed_taken(elder_id: int, dose_id: int) -> DbRetrievalResponse:
    dose = mark_dose_taken_by_id(dose_id)

    if not dose:
        return _build_dialogue_action_response(
            elder_id=elder_id,
            schedule_type="mark_taken",
            message="",
            status="not_found",
            issues=["Dose not found while confirming taken action."],
        )

    medication_name = _get_dose_medication_name(dose)
    dose_time = _get_dose_time(dose)
    message = f"تم تسجيل جرعة {medication_name} الساعة {dose_time} كمأخوذة."

    return _build_dialogue_action_response(
        elder_id=elder_id,
        schedule_type="mark_taken_done",
        message=message,
        medication_name=medication_name,
    )


# Execute a confirmed missed action
def _execute_confirmed_missed(elder_id: int, dose_id: int) -> DbRetrievalResponse:
    dose = mark_dose_missed_by_id(dose_id)

    if not dose:
        return _build_dialogue_action_response(
            elder_id=elder_id,
            schedule_type="mark_missed",
            message="",
            status="not_found",
            issues=["Dose not found while confirming missed action."],
        )

    medication_name = _get_dose_medication_name(dose)
    dose_time = _get_dose_time(dose)
    message = f"تم تسجيل جرعة {medication_name} الساعة {dose_time} كجرعة فائتة."

    return _build_dialogue_action_response(
        elder_id=elder_id,
        schedule_type="mark_missed_done",
        message=message,
        medication_name=medication_name,
    )


# Execute a confirmed snooze action
def _execute_confirmed_snooze(
    elder_id: int,
    dose_id: int,
    minutes: int,
) -> DbRetrievalResponse:
    dose = snooze_dose_by_id(dose_id, minutes)

    if not dose:
        return _build_dialogue_action_response(
            elder_id=elder_id,
            schedule_type="snooze",
            message="",
            status="not_found",
            issues=["Dose not found while confirming snooze action."],
        )

    operation_status = _clean_text(_read_value(dose, "operation_status"))

    if operation_status == "invalid_snooze_minutes":
        return _build_dialogue_action_response(
            elder_id=elder_id,
            schedule_type="snooze_invalid_minutes",
            message="معليش، ما أقدر أأجل الجرعة للوقت اللي طلبته. لو سمحت اختر 15 أو 20 أو 30 دقيقة.",
            status="invalid_input",
            medication_name="snooze",
            issues=["Invalid snooze minutes."],
        )

    medication_name = _get_dose_medication_name(dose)

    if operation_status == "snooze_already_used":
        snooze_reference_time = _get_snooze_reference_time(dose)
        message = (
            f"تم استخدام التأجيل لجرعة {medication_name} من قبل إلى الساعة {snooze_reference_time}، "
            "ولا يمكن تأجيلها مرة ثانية. تم تسجيل الجرعة كفائتة."
        )

        return _build_dialogue_action_response(
            elder_id=elder_id,
            schedule_type="snooze_already_used",
            message=message,
            medication_name=medication_name,
        )

    dose_time = _get_dose_time(dose)
    snoozed_until = _clean_text(dose.get("snoozed_until")) or "بعد قليل"
    message = (
        f"تم تأجيل تذكير {medication_name}، جرعة الساعة {dose_time}، "
        f"لمدة {minutes} دقيقة. التذكير القادم الساعة {snoozed_until}."
    )

    return _build_dialogue_action_response(
        elder_id=elder_id,
        schedule_type=f"snooze_done|minutes:{minutes}",
        message=message,
        medication_name=medication_name,
    )


# Confirm the current pending action and write to the database
def _handle_confirm_intent(elder_id: int) -> DbRetrievalResponse:
    pending_action = dialogue_state_service.confirm_pending_action(elder_id)

    if pending_action is None:
        return _build_dialogue_action_response(
            elder_id=elder_id,
            schedule_type="confirm",
            message="",
            status="not_found",
            issues=["No pending action found to confirm."],
        )

    dose_id = pending_action.dose_id

    if dose_id is None:
        return _build_dialogue_action_response(
            elder_id=elder_id,
            schedule_type="confirm",
            message="",
            status="not_found",
            issues=["No dose_id found for pending action."],
        )

    if pending_action.action_type == "mark_taken":
        return _execute_confirmed_taken(
            elder_id=elder_id,
            dose_id=dose_id,
        )

    if pending_action.action_type == "mark_missed":
        return _execute_confirmed_missed(
            elder_id=elder_id,
            dose_id=dose_id,
        )

    if pending_action.action_type == "snooze":
        return _execute_confirmed_snooze(
            elder_id=elder_id,
            dose_id=dose_id,
            minutes=pending_action.minutes or 15,
        )

    return _build_dialogue_action_response(
        elder_id=elder_id,
        schedule_type="confirm",
        message="ما قدرت أحدد الإجراء المطلوب تأكيده.",
        issues=["Unsupported pending action type."],
    )


# Cancel and clear the current pending action
def _handle_cancel_intent(elder_id: int) -> DbRetrievalResponse:
    was_cancelled = dialogue_state_service.cancel_pending_action(elder_id)

    if not was_cancelled:
        return _build_dialogue_action_response(
            elder_id=elder_id,
            schedule_type="cancel",
            message="",
            status="not_found",
            issues=["No pending action found to cancel."],
        )

    return _build_dialogue_action_response(
        elder_id=elder_id,
        schedule_type="cancel",
        message="تم إلغاء الإجراء الحالي.",
    )


# Repeat the last saved response when available
def _handle_repeat_intent(elder_id: int) -> DbRetrievalResponse:
    last_response = dialogue_state_service.get_last_response(elder_id)

    if not last_response:
        return _build_dialogue_action_response(
            elder_id=elder_id,
            schedule_type="repeat",
            message="",
            status="not_found",
            issues=["No previous response found to repeat."],
        )

    return _build_dialogue_action_response(
        elder_id=elder_id,
        schedule_type="repeat",
        message=last_response,
    )


# Main DB integration entry point
def retrieve_from_nlu_output(
    intent: str | None,
    slots: dict,
    normalized_text: str | None = None,
) -> DbRetrievalResponse:
    normalized_intent = (intent or "").strip()

    info_type = infer_response_mode(
        slots=slots,
        normalized_text=normalized_text,
    )

    elder_id = _get_elder_id_from_slots(slots)

    # Control intents use the temporary in-memory dialogue state
    control_handlers = {
        "Confirm": lambda: _handle_confirm_intent(elder_id=elder_id),
        "Cancel": lambda: _handle_cancel_intent(elder_id=elder_id),
        "Repeat": lambda: _handle_repeat_intent(elder_id=elder_id),
    }

    if normalized_intent in control_handlers:
        return control_handlers[normalized_intent]()

    # Schedule and dose queries use elder_medications and medication_doses
    schedule_handlers = {
        "AskTodaySchedule": lambda: retrieve_today_schedule(elder_id=elder_id),
        "AskNextDose": lambda: retrieve_next_dose(elder_id=elder_id),
        "AskRemainingDoses": lambda: retrieve_remaining_doses(elder_id=elder_id),
        "AskAdherenceStatus": lambda: retrieve_adherence_status(elder_id=elder_id),
    }

    if normalized_intent in schedule_handlers:
        return schedule_handlers[normalized_intent]()

    # Voice actions create confirmation responses before writing to the database
    action_handlers = {
        "MarkDoseTaken": lambda: _prepare_mark_taken_confirmation(elder_id=elder_id),
        "MarkDoseMissed": lambda: _prepare_mark_missed_confirmation(elder_id=elder_id),
        "SnoozeMedication": lambda: _prepare_snooze_confirmation(
            elder_id=elder_id,
            minutes=_get_snooze_minutes_from_slots(
                slots=slots,
                normalized_text=normalized_text,
            ),
        ),
    }

    if normalized_intent in action_handlers:
        return action_handlers[normalized_intent]()


    # Medication usage intent uses elder-specific names first, then catalog fallback
    if normalized_intent != "AskMedicationUsage":
        return _build_unsupported_intent_response(normalized_intent)

    # Priority 1: search by medication name inside the elder's assigned medications first
    med_name = slots.get("MED_NAME")

    if isinstance(med_name, str) and med_name.strip():
        cleaned_med_name = med_name.strip()

        elder_name_response = retrieve_elder_medication_by_name(
            elder_id=elder_id,
            name=cleaned_med_name,
            info_type=info_type,
        )

        if elder_name_response.status != "not_found":
            return elder_name_response

        name_response = retrieve_medication_by_name(
            name=cleaned_med_name,
            info_type=info_type,
        )

        if name_response.status != "not_found":
            return name_response

        category_resolution = resolve_med_category(cleaned_med_name)

        if (
            category_resolution.status == "resolved"
            and category_resolution.matched_category
        ):
            return retrieve_medications_by_category(
                category=category_resolution.matched_category,
                info_type=info_type,
            )

        if category_resolution.status == "ambiguous":
            return DbRetrievalResponse(
                status="ambiguous",
                query_type="nlu_integration",
                matched_by="med_category",
                matched_value=cleaned_med_name,
                count=len(category_resolution.candidates),
                result=[],
                issues=[
                    "The provided text may refer to more than one medication category."
                ],
                candidates=category_resolution.candidates,
            )

        return name_response

    # Priority 2: search by medication category, but first try it as an elder-specific display name
    med_category = slots.get("MED_CATEGORY")

    if isinstance(med_category, str) and med_category.strip():
        cleaned_med_category = med_category.strip()

        elder_category_as_name_response = retrieve_elder_medication_by_name(
            elder_id=elder_id,
            name=cleaned_med_category,
            info_type=info_type,
        )

        if elder_category_as_name_response.status != "not_found":
            return elder_category_as_name_response

        category_resolution = resolve_med_category(cleaned_med_category)

        if (
            category_resolution.status == "resolved"
            and category_resolution.matched_category
        ):
            return retrieve_medications_by_category(
                category=category_resolution.matched_category,
                info_type=info_type,
            )  

        if category_resolution.status == "ambiguous":
            return DbRetrievalResponse(
                status="ambiguous",
                query_type="nlu_integration",
                matched_by="med_category",
                matched_value=cleaned_med_category,
                count=len(category_resolution.candidates),
                result=[],
                issues=[
                    "The provided text may refer to more than one medication category."
                ],
                candidates=category_resolution.candidates,
            )

        return DbRetrievalResponse(
            status="not_found",
            query_type="nlu_integration",
            matched_by="med_category",
            matched_value=cleaned_med_category,
            count=0,
            result=[],
            issues=["No medication category matched the provided input."],
            candidates=[],
        )

    return DbRetrievalResponse(
        status="invalid_input",
        query_type="nlu_integration",
        matched_by=None,
        matched_value="",
        count=0,
        result=[],
        issues=["Missing required slot: MED_NAME or MED_CATEGORY."],
        candidates=[],
    )