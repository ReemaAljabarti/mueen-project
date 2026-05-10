from app.db_schemas import DbRetrievalResponse, MedicationUsageRecord
from app.services.db_medication_queries import (
    get_elder_medication_by_name,
    get_today_elder_doses,
    get_medication_by_name,
    get_medications_by_category,
    get_next_elder_dose,
    get_remaining_elder_doses,
    get_today_adherence_summary,
    record_dose_event,
    record_dose_snooze,
)


# Build compact medication records for medication usage responses.
def _build_usage_records(
    records: list[dict],
    info_type: str,
) -> list[MedicationUsageRecord]:
    compact_records: list[MedicationUsageRecord] = []

    for record in records:
        compact_records.append(
            MedicationUsageRecord(
                brand_name_ar=record["brand_name_ar"],
                uses_ar=record["uses_ar"] if info_type == "usage" else None,
                food_guide_ar=record.get("food_guide_ar")
                if info_type == "food_guide"
                else None,
            )
        )

    return compact_records

# Build schedule records for elder medication queries.
def _build_elder_schedule_records(records: list[dict]) -> list[MedicationUsageRecord]:
    compact_records: list[MedicationUsageRecord] = []

    for record in records:
        display_name = record.get("display_name_for_elder") or ""
        brand_name = record.get("brand_name_ar") or ""
        generic_name = record.get("generic_name_en") or ""

        amount = record.get("dosage_amount")
        unit = record.get("dosage_unit") or ""
        reminder_time = (
            record.get("scheduled_time")
            or record.get("first_reminder_time")
            or "غير محدد"
        )

        name_parts = []

        if display_name:
            name_parts.append(display_name)

        if brand_name and brand_name != display_name:
            name_parts.append(brand_name)

        if generic_name:
            name_parts.append(generic_name)

        readable_name = " - ".join(name_parts) if name_parts else "الدواء"

        schedule_text = f"{amount} {unit} الساعة {reminder_time}".strip()

        compact_records.append(
            MedicationUsageRecord(
                brand_name_ar=readable_name,
                uses_ar=schedule_text,
                food_guide_ar=None,
            )
        )

    return compact_records

# Build a compact message record for action and status responses.
def _build_action_record(
    brand_name: str,
    message: str,
) -> list[MedicationUsageRecord]:
    return [
        MedicationUsageRecord(
            brand_name_ar=brand_name,
            uses_ar=message,
            food_guide_ar=None,
        )
    ]


# Build not-found response for medication name lookup.
def _build_name_not_found_response(name: str) -> DbRetrievalResponse:
    return DbRetrievalResponse(
        status="not_found",
        query_type="by_name",
        matched_by="brand_name_ar",
        matched_value=name,
        count=0,
        result=[],
        issues=["No medication matched the provided name."],
        candidates=[],
    )


# Build ambiguous response for medication name lookup.
def _build_name_ambiguous_response(
    name: str,
    matched_by: str,
    records: list[dict],
) -> DbRetrievalResponse:
    candidate_names = [record["brand_name_ar"] for record in records]

    return DbRetrievalResponse(
        status="ambiguous",
        query_type="by_name",
        matched_by=matched_by or "brand_name_ar",
        matched_value=name,
        count=len(records),
        result=[],
        issues=["Multiple medications matched the provided name."],
        candidates=candidate_names,
    )


# Build schema-compatible response for schedule and action flows.
def _build_schedule_response(
    status: str,
    elder_id: int,
    records: list[MedicationUsageRecord],
    count: int,
    schedule_type: str,
    issue: str | None = None,
) -> DbRetrievalResponse:
    return DbRetrievalResponse(
        status=status,
        query_type="nlu_integration",
        matched_by="med_category",
        matched_value=f"elder_id:{elder_id}|schedule_type:{schedule_type}",
        count=count,
        result=records,
        issues=[issue] if issue else [],
        candidates=[],
    )

#=========================================================================================
# Build an Arabic adherence summary message.
def _build_adherence_summary_message(summary: dict) -> str:
    total = summary.get("total", 0)
    taken = summary.get("taken", 0)
    missed = summary.get("missed", 0)
    snoozed = summary.get("snoozed", 0)
    pending = summary.get("pending", 0)

    if total == 0:
        return "ما عندك جرعات مسجلة لليوم حتى الآن."

    return (
        f"ملخص التزامك اليوم: إجمالي الجرعات {total}. "
        f"المأخوذة {taken}، الفائتة {missed}، "
        f"المؤجلة {snoozed}، والمتبقية {pending}."
    )
#=========================================================================================

# Get a readable medication name from a dose record.
def _get_dose_brand_name(dose: dict) -> str:
    return (
        dose.get("display_name_for_elder")
        or dose.get("brand_name_ar")
        or "الجرعة"
    )


# Get a readable dose time from a dose record.
def _get_dose_time(dose: dict) -> str:
    return (
        dose.get("scheduled_time")
        or dose.get("first_reminder_time")
        or "غير محدد"
    )


# Get the time that should be shown for snoozed dose responses.
def _get_snooze_reference_time(dose: dict) -> str:
    snoozed_until = dose.get("snoozed_until")

    if snoozed_until and str(snoozed_until).strip():
        return str(snoozed_until).strip()

    return _get_dose_time(dose)

#=================================================================
# Search medication information by medication name.
def retrieve_medication_by_name(
    name: str,
    info_type: str = "usage",
) -> DbRetrievalResponse:
    matched_by, records = get_medication_by_name(name=name)

    if not records:
        return _build_name_not_found_response(name)

    if len(records) > 1:
        return _build_name_ambiguous_response(
            name=name,
            matched_by=matched_by or "brand_name_ar",
            records=records,
        )

    compact_records = _build_usage_records(records, info_type)

    return DbRetrievalResponse(
        status="success",
        query_type="by_name",
        matched_by=matched_by,
        matched_value=name,
        count=len(compact_records),
        result=compact_records,
        issues=[],
        candidates=[],
    )


# Search medication information within one elder's assigned medications by display name or brand name.
def retrieve_elder_medication_by_name(
    elder_id: int,
    name: str,
    info_type: str = "usage",
) -> DbRetrievalResponse:
    matched_by, records = get_elder_medication_by_name(
        elder_id=elder_id,
        name=name,
    )

    if not records:
        return DbRetrievalResponse(
            status="not_found",
            query_type="nlu_integration",
            matched_by="display_name_for_elder",
            matched_value=name,
            count=0,
            result=[],
            issues=["No elder medication matched the provided name."],
            candidates=[],
        )

    if len(records) > 1:
        candidate_names = []

        for record in records:
            display_name = record.get("display_name_for_elder")
            brand_name = record.get("brand_name_ar")

            if display_name and str(display_name).strip():
                candidate_names.append(str(display_name).strip())
            elif brand_name and str(brand_name).strip():
                candidate_names.append(str(brand_name).strip())

        return DbRetrievalResponse(
            status="ambiguous",
            query_type="nlu_integration",
            matched_by=matched_by or "display_name_for_elder",
            matched_value=name,
            count=len(records),
            result=[],
            issues=["Multiple elder medications matched the provided name."],
            candidates=candidate_names,
        )

    compact_records = _build_usage_records(records, info_type)

    return DbRetrievalResponse(
        status="success",
        query_type="nlu_integration",
        matched_by=matched_by or "display_name_for_elder",
        matched_value=name,
        count=len(compact_records),
        result=compact_records,
        issues=[],
        candidates=[],
    )


# Search medication information by medication category.
def retrieve_medications_by_category(
    category: str,
    info_type: str = "usage",
) -> DbRetrievalResponse:
    records = get_medications_by_category(category=category)

    if not records:
        return DbRetrievalResponse(
            status="not_found",
            query_type="by_category",
            matched_by="med_category",
            matched_value=category,
            count=0,
            result=[],
            issues=["No medications matched the provided category."],
            candidates=[],
        )

    if len(records) == 1:
        compact_records = _build_usage_records(records, info_type)

        return DbRetrievalResponse(
            status="success",
            query_type="by_category",
            matched_by="med_category",
            matched_value=category,
            count=1,
            result=compact_records,
            issues=[],
            candidates=[],
        )

    candidate_names = [record["brand_name_ar"] for record in records]

    return DbRetrievalResponse(
        status="ambiguous",
        query_type="by_category",
        matched_by="med_category",
        matched_value=category,
        count=len(records),
        result=[],
        issues=["Multiple medications matched the provided category."],
        candidates=candidate_names,
    )


# Retrieve today's full medication schedule for one elder.
def retrieve_today_schedule(elder_id: int) -> DbRetrievalResponse:
    records = get_today_elder_doses(elder_id)

    if not records:
        return _build_schedule_response(
            status="not_found",
            elder_id=elder_id,
            records=[],
            count=0,
            schedule_type="today_schedule",
            issue="No medication doses found for this elder today.",
        )

    compact_records = _build_elder_schedule_records(records)

    return _build_schedule_response(
        status="success",
        elder_id=elder_id,
        records=compact_records,
        count=len(compact_records),
        schedule_type="today_schedule",
    )


# Retrieve the next dose from the current time onward.
def retrieve_next_dose(elder_id: int) -> DbRetrievalResponse:
    record = get_next_elder_dose(elder_id)

    if not record:
        return _build_schedule_response(
            status="not_found",
            elder_id=elder_id,
            records=[],
            count=0,
            schedule_type="next_dose",
            issue="No upcoming dose found for this elder today.",
        )

    compact_records = _build_elder_schedule_records([record])

    return _build_schedule_response(
        status="success",
        elder_id=elder_id,
        records=compact_records,
        count=1,
        schedule_type="next_dose",
    )


# Retrieve remaining doses from the current time until the end of today.
def retrieve_remaining_doses(elder_id: int) -> DbRetrievalResponse:
    records = get_remaining_elder_doses(elder_id)

    if not records:
        return _build_schedule_response(
            status="not_found",
            elder_id=elder_id,
            records=[],
            count=0,
            schedule_type="remaining_doses",
            issue="No remaining doses found for this elder today.",
        )

    compact_records = _build_elder_schedule_records(records)

    return _build_schedule_response(
        status="success",
        elder_id=elder_id,
        records=compact_records,
        count=len(compact_records),
        schedule_type="remaining_doses",
    )


# Mark the current due dose as taken.
def record_taken_dose(elder_id: int) -> DbRetrievalResponse:
    dose = record_dose_event(elder_id=elder_id, event_type="taken")

    if not dose:
        return _build_schedule_response(
            status="not_found",
            elder_id=elder_id,
            records=[],
            count=0,
            schedule_type="mark_taken",
            issue="No current due dose found to mark as taken.",
        )

    brand_name = _get_dose_brand_name(dose)
    reminder_time = _get_dose_time(dose)

    records = _build_action_record(
        brand_name=brand_name,
        message=f"تم تسجيل جرعة {brand_name} الساعة {reminder_time} كمأخوذة.",
    )

    return _build_schedule_response(
        status="success",
        elder_id=elder_id,
        records=records,
        count=1,
        schedule_type="mark_taken_done",
    )


# Mark the current due dose as missed.
def record_missed_dose(elder_id: int) -> DbRetrievalResponse:
    dose = record_dose_event(elder_id=elder_id, event_type="missed")

    if not dose:
        return _build_schedule_response(
            status="not_found",
            elder_id=elder_id,
            records=[],
            count=0,
            schedule_type="mark_missed",
            issue="No current due dose found to mark as missed.",
        )

    brand_name = _get_dose_brand_name(dose)
    reminder_time = _get_dose_time(dose)

    records = _build_action_record(
        brand_name=brand_name,
        message=f"تم تسجيل جرعة {brand_name} الساعة {reminder_time} كجرعة فائتة.",
    )

    return _build_schedule_response(
        status="success",
        elder_id=elder_id,
        records=records,
        count=1,
        schedule_type="mark_missed_done",
    )


# Snooze the current due dose once only.
def snooze_dose(elder_id: int, minutes: int) -> DbRetrievalResponse:
    dose = record_dose_snooze(elder_id=elder_id, minutes=minutes)

    if not dose:
        return _build_schedule_response(
            status="not_found",
            elder_id=elder_id,
            records=[],
            count=0,
            schedule_type="snooze",
            issue="No current due dose found to snooze.",
        )

    operation_status = dose.get("operation_status")

    if operation_status == "invalid_snooze_minutes":
        records = _build_action_record(
            brand_name="snooze",
            message="معليش، ما أقدر أأجل الجرعة للوقت اللي طلبته. لو سمحت اختر 15 أو 20 أو 30 دقيقة.",
        )

        return _build_schedule_response(
            status="invalid_input",
            elder_id=elder_id,
            records=records,
            count=1,
            schedule_type="snooze_invalid_minutes",
            issue="Invalid snooze minutes.",
        )

    if operation_status == "snooze_already_used":
        brand_name = _get_dose_brand_name(dose)
        snooze_reference_time = _get_snooze_reference_time(dose)

        records = _build_action_record(
            brand_name=brand_name,
            message=(
                f"تم استخدام التأجيل لجرعة {brand_name} من قبل إلى الساعة {snooze_reference_time}، "
                "ولا يمكن تأجيلها مرة ثانية. تم تسجيل الجرعة كفائتة."
            ),
        )

        return _build_schedule_response(
            status="success",
            elder_id=elder_id,
            records=records,
            count=1,
            schedule_type="snooze_already_used",
        )

#========================================================
    brand_name = _get_dose_brand_name(dose)
    reminder_time = _get_dose_time(dose)
    snoozed_until = _get_snooze_reference_time(dose)

    records = _build_action_record(
        brand_name=brand_name,
        message=(
            f"تم تأجيل تذكير {brand_name}، جرعة الساعة {reminder_time}، "
            f"لمدة {minutes} دقيقة. التذكير القادم الساعة {snoozed_until}."
        ),
    )

    return _build_schedule_response(
        status="success",
        elder_id=elder_id,
        records=records,
        count=1,
        schedule_type=f"snooze_done|minutes:{minutes}",
    )


# Retrieve today's adherence status.
def retrieve_adherence_status(elder_id: int) -> DbRetrievalResponse:
    summary = get_today_adherence_summary(elder_id)
    message = _build_adherence_summary_message(summary)

    records = _build_action_record(
        brand_name="adherence_summary",
        message=message,
    )

    return _build_schedule_response(
        status="success",
        elder_id=elder_id,
        records=records,
        count=1,
        schedule_type="adherence_status",
    )


