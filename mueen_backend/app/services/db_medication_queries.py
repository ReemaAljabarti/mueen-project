from datetime import date, datetime, timedelta
from difflib import SequenceMatcher
from typing import Dict, List, Optional, Tuple

from app.db.connection import get_db_connection


# Thresholds for fuzzy matching
FUZZY_NAME_THRESHOLD = 0.72
FUZZY_TOKEN_THRESHOLD = 0.69
FUZZY_SCORE_GAP = 0.015
FUZZY_NEAR_MATCH_MARGIN = 0.02

# Allowed time window for current-dose actions.
CURRENT_DOSE_BEFORE_MINUTES = 10
CURRENT_DOSE_AFTER_MINUTES = 10

# Time limit before an unanswered dose becomes missed.
DOSE_MISSED_AFTER_MINUTES = 10


# Convert DB row to dictionary
def _row_to_dict(row) -> Dict:
    return dict(row)


# Generate Arabic medication name variants with and without "ال"
def _build_arabic_name_variants(name: str) -> List[str]:
    cleaned_name = name.strip()
    variants: List[str] = []

    if not cleaned_name:
        return variants

    variants.append(cleaned_name)

    if cleaned_name.startswith("ال") and len(cleaned_name) > 2:
        variants.append(cleaned_name[2:])
    else:
        variants.append(f"ال{cleaned_name}")

    return list(dict.fromkeys(variants))


# Remove basic Arabic punctuation that may affect matching
def _remove_basic_arabic_punctuation(text: str) -> str:
    punctuation_chars = ["؟", "،", "؛", "."]

    for char in punctuation_chars:
        text = text.replace(char, " ")

    return text


# Remove short Arabic prefixes attached to one-word medication names
def _strip_arabic_preposition_prefix(text: str) -> str:
    if not text:
        return ""

    prefixes = ["بال", "ب", "لل", "ل"]

    for prefix in prefixes:
        if text.startswith(prefix) and len(text) > len(prefix) + 2:
            return text[len(prefix):]

    return text


# Normalize medication names before exact, contains, and fuzzy matching
def _normalize_medication_name(text: str) -> str:
    if not text:
        return ""

    normalized = text.strip()

    tashkeel = [
        "\u064b",
        "\u064c",
        "\u064d",
        "\u064e",
        "\u064f",
        "\u0650",
        "\u0651",
        "\u0652",
    ]

    for char in tashkeel:
        normalized = normalized.replace(char, "")

    normalized = _remove_basic_arabic_punctuation(normalized)
    normalized = " ".join(normalized.split())

    if " " not in normalized:
        normalized = _strip_arabic_preposition_prefix(normalized)

    return normalized


# Normalize text and remove spaces for fuzzy comparison
def _normalize_without_spaces(text: str) -> str:
    return _normalize_medication_name(text).replace(" ", "")


# Split a medication name into unique normalized tokens
def _split_name_tokens(text: str) -> List[str]:
    normalized = _normalize_medication_name(text)

    if not normalized:
        return []

    tokens: List[str] = []

    for token in normalized.split():
        token = _strip_arabic_preposition_prefix(token.strip())

        if token and token not in tokens:
            tokens.append(token)

    return tokens


# Calculate similarity between two strings
def _calculate_name_similarity(left: str, right: str) -> float:
    if not left or not right:
        return 0.0

    return SequenceMatcher(None, left, right).ratio()


# Calculate best similarity using normal and no-space comparison
def _calculate_combined_similarity(left: str, right: str) -> float:
    return max(
        _calculate_name_similarity(left, right),
        _calculate_name_similarity(
            _normalize_without_spaces(left),
            _normalize_without_spaces(right),
        ),
    )


# Load all catalog medications with Arabic brand names
def _fetch_named_medications() -> List[Dict]:
    connection = get_db_connection()

    try:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT *
            FROM medications_catalog
            WHERE brand_name_ar IS NOT NULL
              AND TRIM(brand_name_ar) != ''
            """
        )

        return [_row_to_dict(row) for row in cursor.fetchall()]

    finally:
        connection.close()


# Find exact medication name matches after normalization
def _find_normalized_exact_name_matches(name: str, rows: List[Dict]) -> List[Dict]:
    normalized_input = _normalize_medication_name(name)

    if not normalized_input:
        return []

    input_variants = {
        _normalize_medication_name(variant)
        for variant in _build_arabic_name_variants(normalized_input)
    }

    matches: List[Dict] = []

    for row in rows:
        brand = _normalize_medication_name(row.get("brand_name_ar", ""))

        if brand in input_variants:
            matches.append(row)
            continue

        brand_variants = {
            _normalize_medication_name(variant)
            for variant in _build_arabic_name_variants(brand)
        }

        if normalized_input in brand_variants:
            matches.append(row)

    return matches


# Find partial medication name matches
def _find_contains_name_matches(name: str, rows: List[Dict]) -> List[Dict]:
    normalized_input = _normalize_medication_name(name)

    if not normalized_input:
        return []

    input_variants = [
        _normalize_medication_name(variant)
        for variant in _build_arabic_name_variants(normalized_input)
    ]

    matches: List[Dict] = []

    for row in rows:
        brand = _normalize_medication_name(row.get("brand_name_ar", ""))

        for variant in input_variants:
            if variant and variant in brand:
                matches.append(row)
                break

    return matches


# Find best full-name fuzzy medication match
def _find_best_fuzzy_name_matches(
    name: str,
    rows: List[Dict],
) -> Tuple[Optional[Dict], float, Optional[Dict], float]:
    normalized_input = _normalize_medication_name(name)

    scored: List[Tuple[float, Dict]] = []

    for row in rows:
        brand_name = row.get("brand_name_ar", "")

        if not brand_name:
            continue

        score = _calculate_combined_similarity(
            normalized_input,
            _normalize_medication_name(brand_name),
        )
        scored.append((score, row))

    if not scored:
        return None, 0.0, None, 0.0

    scored.sort(reverse=True, key=lambda item: item[0])

    best_score, best_row = scored[0]
    second_score = 0.0
    second_row: Optional[Dict] = None

    if len(scored) > 1:
        second_score, second_row = scored[1]

    return best_row, best_score, second_row, second_score


# Find best token-based fuzzy medication match
def _find_best_fuzzy_token_matches(
    name: str,
    rows: List[Dict],
) -> Tuple[Optional[Dict], float, Optional[Dict], float]:
    normalized_input = _normalize_medication_name(name)

    scored: List[Tuple[float, Dict]] = []

    for row in rows:
        for token in _split_name_tokens(row.get("brand_name_ar", "")):
            if len(token) < 4:
                continue

            score = _calculate_combined_similarity(normalized_input, token)
            scored.append((score, row))

    if not scored:
        return None, 0.0, None, 0.0

    scored.sort(reverse=True, key=lambda item: item[0])

    best_score, best_row = scored[0]
    second_score = 0.0
    second_row: Optional[Dict] = None

    if len(scored) > 1:
        second_score, second_row = scored[1]

    return best_row, best_score, second_row, second_score


# Check if full-name fuzzy match is reliable enough
def _is_confident_full_name_match(best_score: float, second_score: float) -> bool:
    if best_score >= FUZZY_NAME_THRESHOLD:
        return (best_score - second_score) >= FUZZY_SCORE_GAP

    near_threshold = FUZZY_NAME_THRESHOLD - FUZZY_NEAR_MATCH_MARGIN

    if best_score >= near_threshold:
        return (best_score - second_score) >= FUZZY_SCORE_GAP

    return False


# Check if token fuzzy match is reliable enough
def _is_confident_token_match(best_score: float, second_score: float) -> bool:
    if best_score < FUZZY_TOKEN_THRESHOLD:
        return False

    if best_score >= FUZZY_TOKEN_THRESHOLD + 0.04:
        return True

    return (best_score - second_score) >= 0.01


# Normalize category text before category matching
def _normalize_category_text(text: str) -> str:
    if not text:
        return ""

    normalized = text.strip()
    normalized = _remove_basic_arabic_punctuation(normalized)

    removable_words = [
        "دواء",
        "دواءك",
        "دوائي",
        "أدوية",
        "ادوية",
        "علاج",
        "علاجات",
    ]

    for word in removable_words:
        normalized = normalized.replace(word, " ")

    return " ".join(normalized.split())


# Split category text into unique tokens
def _build_category_tokens(category: str) -> List[str]:
    normalized = _normalize_category_text(category)

    if not normalized:
        return []

    tokens: List[str] = []

    for token in normalized.split():
        cleaned_token = token.strip()

        if cleaned_token and cleaned_token not in tokens:
            tokens.append(cleaned_token)

    return tokens


# Return official medication categories from DB
def get_distinct_med_categories() -> List[str]:
    connection = get_db_connection()

    try:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT DISTINCT med_category
            FROM medications_catalog
            WHERE med_category IS NOT NULL
              AND TRIM(med_category) != ''
            ORDER BY med_category
            """
        )
        rows = cursor.fetchall()

        return [row["med_category"] for row in rows]

    finally:
        connection.close()


# Search medications by Arabic brand name
def get_medication_by_name(name: str) -> Tuple[Optional[str], List[Dict]]:
    normalized_name = _normalize_medication_name(name)

    if not normalized_name:
        return None, []

    rows = _fetch_named_medications()

    if not rows:
        return None, []

    exact = _find_normalized_exact_name_matches(normalized_name, rows)

    if exact:
        return "brand_name_ar", exact

    contains = _find_contains_name_matches(normalized_name, rows)

    if contains:
        return "brand_name_ar", contains

    best, score, _second_row, second_score = _find_best_fuzzy_name_matches(
        normalized_name,
        rows,
    )

    if best and _is_confident_full_name_match(score, second_score):
        return "brand_name_ar_fuzzy", [best]

    best, score, _second_row, second_score = _find_best_fuzzy_token_matches(
        normalized_name,
        rows,
    )

    if best and _is_confident_token_match(score, second_score):
        return "brand_name_ar_fuzzy", [best]

    return None, []


# Load all medications assigned to one elder with names used for matching
def _fetch_elder_named_medications(elder_id: int) -> List[Dict]:
    connection = get_db_connection()

    try:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT
                em.id AS elder_medication_id,
                em.elder_id,
                em.display_name_for_elder,
                em.dosage_amount,
                em.dosage_unit,
                em.usage_instruction,
                em.short_description,
                em.treatment_duration_type,
                em.start_date,
                em.end_date,
                em.times_per_day,
                em.first_reminder_time,
                em.days_pattern,
                mc.id AS catalog_medication_id,
                mc.brand_name_ar,
                mc.med_category,
                mc.uses_ar,
                mc.food_guide_ar
            FROM elder_medications em
            JOIN medications_catalog mc
                ON em.catalog_medication_id = mc.id
            WHERE em.elder_id = ?
              AND (
                    (em.display_name_for_elder IS NOT NULL AND TRIM(em.display_name_for_elder) != '')
                    OR
                    (mc.brand_name_ar IS NOT NULL AND TRIM(mc.brand_name_ar) != '')
                  )
            ORDER BY em.first_reminder_time ASC
            """,
            (elder_id,),
        )

        return [_row_to_dict(row) for row in cursor.fetchall()]

    finally:
        connection.close()


# Remove duplicate elder-medication rows while preserving order
def _deduplicate_elder_medication_rows(rows: List[Dict]) -> List[Dict]:
    seen_ids: set[int] = set()
    unique_rows: List[Dict] = []

    for row in rows:
        elder_medication_id = row.get("elder_medication_id")

        if elder_medication_id is None:
            continue

        row_id = int(elder_medication_id)

        if row_id in seen_ids:
            continue

        seen_ids.add(row_id)
        unique_rows.append(row)

    return unique_rows


# Get searchable names for an elder medication row
def _get_elder_search_names(row: Dict) -> List[Tuple[str, str]]:
    names: List[Tuple[str, str]] = []

    display_name = row.get("display_name_for_elder")
    brand_name = row.get("brand_name_ar")

    if display_name and str(display_name).strip():
        names.append(("display_name_for_elder", str(display_name).strip()))

    if brand_name and str(brand_name).strip():
        names.append(("brand_name_ar", str(brand_name).strip()))

    return names


# Find exact matches inside elder medications using display name and brand name
def _find_elder_exact_name_matches(
    name: str,
    rows: List[Dict],
) -> Tuple[Optional[str], List[Dict]]:
    normalized_input = _normalize_medication_name(name)

    if not normalized_input:
        return None, []

    input_variants = {
        _normalize_medication_name(variant)
        for variant in _build_arabic_name_variants(normalized_input)
    }

    matched_by: Optional[str] = None
    matches: List[Dict] = []

    for row in rows:
        for field_name, field_value in _get_elder_search_names(row):
            normalized_field = _normalize_medication_name(field_value)

            if normalized_field in input_variants:
                matched_by = matched_by or field_name
                matches.append(row)
                break

            field_variants = {
                _normalize_medication_name(variant)
                for variant in _build_arabic_name_variants(normalized_field)
            }

            if normalized_input in field_variants:
                matched_by = matched_by or field_name
                matches.append(row)
                break

    return matched_by, _deduplicate_elder_medication_rows(matches)


# Find contains matches inside elder medications using display name and brand name
def _find_elder_contains_name_matches(
    name: str,
    rows: List[Dict],
) -> Tuple[Optional[str], List[Dict]]:
    normalized_input = _normalize_medication_name(name)

    if not normalized_input:
        return None, []

    input_variants = [
        _normalize_medication_name(variant)
        for variant in _build_arabic_name_variants(normalized_input)
    ]

    matched_by: Optional[str] = None
    matches: List[Dict] = []

    for row in rows:
        for field_name, field_value in _get_elder_search_names(row):
            normalized_field = _normalize_medication_name(field_value)

            for variant in input_variants:
                if variant and variant in normalized_field:
                    matched_by = matched_by or field_name
                    matches.append(row)
                    break
            else:
                continue

            break

    return matched_by, _deduplicate_elder_medication_rows(matches)


# Find best fuzzy match inside elder medications using display name and brand name
def _find_best_elder_fuzzy_name_match(
    name: str,
    rows: List[Dict],
) -> Tuple[Optional[str], Optional[Dict], float, Optional[Dict], float]:
    normalized_input = _normalize_medication_name(name)

    scored: List[Tuple[float, str, Dict]] = []

    for row in rows:
        for field_name, field_value in _get_elder_search_names(row):
            score = _calculate_combined_similarity(
                normalized_input,
                _normalize_medication_name(field_value),
            )
            scored.append((score, field_name, row))

    if not scored:
        return None, None, 0.0, None, 0.0

    scored.sort(reverse=True, key=lambda item: item[0])

    best_score, best_field_name, best_row = scored[0]
    best_row_id = best_row.get("elder_medication_id")

    second_score = 0.0
    second_row: Optional[Dict] = None

    for score, _field_name, row in scored[1:]:
        if row.get("elder_medication_id") != best_row_id:
            second_score = score
            second_row = row
            break

    return best_field_name, best_row, best_score, second_row, second_score


# Search medications assigned to a specific elder by display_name_for_elder or brand_name_ar
def get_elder_medication_by_name(
    elder_id: int,
    name: str,
) -> Tuple[Optional[str], List[Dict]]:
    normalized_name = _normalize_medication_name(name)

    if not normalized_name:
        return None, []

    rows = _fetch_elder_named_medications(elder_id)

    if not rows:
        return None, []

    matched_by, exact_matches = _find_elder_exact_name_matches(
        normalized_name,
        rows,
    )

    if exact_matches:
        return matched_by or "elder_medication_name", exact_matches

    matched_by, contains_matches = _find_elder_contains_name_matches(
        normalized_name,
        rows,
    )

    if contains_matches:
        return matched_by or "elder_medication_name", contains_matches

    matched_by, best, score, _second_row, second_score = _find_best_elder_fuzzy_name_match(
        normalized_name,
        rows,
    )

    # Keep elder-specific fuzzy matching stricter to avoid matching the wrong elder display name.
    if best and score >= FUZZY_NAME_THRESHOLD and _is_confident_full_name_match(
        score,
        second_score,
    ):
        match_type = f"{matched_by}_fuzzy" if matched_by else "elder_medication_name_fuzzy"
        return match_type, [best]

    return None, []


# Search medications by medication category
def get_medications_by_category(category: str) -> List[Dict]:
    connection = get_db_connection()

    try:
        cursor = connection.cursor()
        tokens = _build_category_tokens(category)

        if not tokens:
            return []

        where_clauses = " AND ".join(["med_category LIKE ?"] * len(tokens))
        query = f"""
            SELECT *
            FROM medications_catalog
            WHERE {where_clauses}
        """
        parameters = tuple(f"%{token}%" for token in tokens)

        cursor.execute(query, parameters)
        rows = cursor.fetchall()

        return [_row_to_dict(row) for row in rows]

    finally:
        connection.close()


# Get all active medications assigned to one elder
def get_elder_medications(elder_id: int) -> List[Dict]:
    connection = get_db_connection()

    try:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT
                em.id AS elder_medication_id,
                em.elder_id,
                em.display_name_for_elder,
                em.dosage_amount,
                em.dosage_unit,
                em.usage_instruction,
                em.short_description,
                em.treatment_duration_type,
                em.start_date,
                em.end_date,
                em.times_per_day,
                em.first_reminder_time,
                em.days_pattern,
                mc.id AS catalog_medication_id,
                mc.brand_name_ar,
                mc.med_category,
                mc.uses_ar,
                mc.food_guide_ar
            FROM elder_medications em
            JOIN medications_catalog mc
                ON em.catalog_medication_id = mc.id
            WHERE em.elder_id = ?
            ORDER BY em.first_reminder_time ASC
            """,
            (elder_id,),
        )

        return [_row_to_dict(row) for row in cursor.fetchall()]

    finally:
        connection.close()


# Return today's date as YYYY-MM-DD
def _today_str() -> str:
    return date.today().isoformat()


# Return current timestamp for dose and adherence events
def _now_timestamp() -> str:
    return datetime.now().isoformat(timespec="seconds")

# Convert HH:MM text into a time object   
def _parse_reminder_time(time_text: str | None):
    if not time_text:
        return None

    try:
        return datetime.strptime(str(time_text).strip(), "%H:%M").time()
    except ValueError:
        return None

# Convert a snoozed_until value into a datetime object
def _parse_datetime(timestamp_text: str | None) -> Optional[datetime]:
    if not timestamp_text:
        return None

    value = str(timestamp_text).strip()

    try:
        return datetime.fromisoformat(value)
    except ValueError:
        pass

    try:
        snooze_time = datetime.strptime(value, "%H:%M").time()
        return datetime.combine(date.today(), snooze_time)
    except ValueError:
        return None


# Automatically mark overdue pending/snoozed doses as missed.
def _expire_overdue_doses_for_today(elder_id: int) -> None:
    connection = get_db_connection()

    try:
        cursor = connection.cursor()

        cursor.execute(
            """
            SELECT
                id AS dose_id,
                elder_medication_id,
                elder_id,
                scheduled_time,
                status,
                snoozed_until
            FROM medication_doses
            WHERE elder_id = ?
              AND dose_date = ?
              AND status IN ('pending', 'snoozed')
            """,
            (elder_id, _today_str()),
        )

        rows = [_row_to_dict(row) for row in cursor.fetchall()]
        now = datetime.now()
        now_text = _now_timestamp()

        overdue_doses = []

        for dose in rows:
            status = dose.get("status")
            cutoff_datetime = None

            if status == "pending":
                scheduled_time = _parse_reminder_time(dose.get("scheduled_time"))

                if scheduled_time is None:
                    continue

                scheduled_datetime = datetime.combine(date.today(), scheduled_time)
                cutoff_datetime = scheduled_datetime + timedelta(
                    minutes=DOSE_MISSED_AFTER_MINUTES
                )

            elif status == "snoozed":
                snoozed_until = _parse_datetime(dose.get("snoozed_until"))

                if snoozed_until is None:
                    continue

                cutoff_datetime = snoozed_until + timedelta(
                    minutes=DOSE_MISSED_AFTER_MINUTES
                )

            if cutoff_datetime and now > cutoff_datetime:
                overdue_doses.append(dose)

        for dose in overdue_doses:
            dose_id = int(dose["dose_id"])
            elder_medication_id = int(dose["elder_medication_id"])

            cursor.execute(
                """
                UPDATE medication_doses
                SET status = ?,
                    taken_at = NULL,
                    missed_at = ?,
                    last_updated_at = ?
                WHERE id = ?
                  AND status IN ('pending', 'snoozed')
                """,
                ("missed", now_text, now_text, dose_id),
            )

            _insert_adherence_log(
                cursor=cursor,
                dose_id=dose_id,
                elder_id=elder_id,
                elder_medication_id=elder_medication_id,
                status="missed",
                event_type="missed",
                event_time=now_text,
                note="Auto marked as missed after the allowed response window.",
            )

        connection.commit()

    except Exception:
        connection.rollback()
        raise

    finally:
        connection.close()
#=====================================================================

# Check if the medication reminder time is still upcoming today
def _is_upcoming_today(record: Dict) -> bool:
    reminder_time = _parse_reminder_time(record.get("first_reminder_time"))

    if reminder_time is None:
        return False

    return reminder_time >= datetime.now().time()


# Check if the medication reminder time is already due or passed today
def _is_due_or_passed_today(record: Dict) -> bool:
    reminder_time = _parse_reminder_time(record.get("first_reminder_time"))

    if reminder_time is None:
        return False

    return reminder_time <= datetime.now().time()


# Check if the medication reminder time is within the current dose window
def _is_current_due_window(record: Dict) -> bool:
    reminder_time = _parse_reminder_time(record.get("first_reminder_time"))

    if reminder_time is None:
        return False

    now = datetime.now()
    reminder_datetime = datetime.combine(date.today(), reminder_time)

    window_start = reminder_datetime - timedelta(
        minutes=CURRENT_DOSE_BEFORE_MINUTES
    )
    window_end = reminder_datetime + timedelta(
        minutes=CURRENT_DOSE_AFTER_MINUTES
    )

    return window_start <= now <= window_end


# Sort medication records by first reminder time
def _sort_by_reminder_time(records: List[Dict]) -> List[Dict]:
    return sorted(
        records,
        key=lambda record: _parse_reminder_time(
            record.get("first_reminder_time")
        ),
    )


# Sort dose records by scheduled time
def _sort_by_scheduled_time(records: List[Dict]) -> List[Dict]:
    return sorted(
        records,
        key=lambda record: _parse_reminder_time(
            record.get("scheduled_time")
        ),
    )


# Fetch today's dose rows with medication details
def _fetch_today_dose_rows(elder_id: int) -> List[Dict]:
    _expire_overdue_doses_for_today(elder_id)

    connection = get_db_connection()

    try:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT
                md.id AS dose_id,
                md.elder_medication_id,
                md.elder_id,
                md.scheduled_time,
                md.dose_date,
                md.status,
                md.snooze_count,
                md.snoozed_until,
                md.created_at AS dose_created_at,
                md.taken_at,
                md.missed_at,
                md.last_updated_at,
                em.display_name_for_elder,
                em.dosage_amount,
                em.dosage_unit,
                em.usage_instruction,
                em.short_description,
                em.treatment_duration_type,
                em.start_date,
                em.end_date,
                em.times_per_day,
                em.first_reminder_time,
                em.days_pattern,
                mc.id AS catalog_medication_id,
                mc.brand_name_ar,
                mc.med_category,
                mc.uses_ar,
                mc.food_guide_ar
            FROM medication_doses md
            JOIN elder_medications em
                ON md.elder_medication_id = em.id
            JOIN medications_catalog mc
                ON em.catalog_medication_id = mc.id
            WHERE md.elder_id = ?
              AND md.dose_date = ?
            ORDER BY md.scheduled_time ASC, md.id ASC
            """,
            (elder_id, _today_str()),
        )

        return [_row_to_dict(row) for row in cursor.fetchall()]

    finally:
        connection.close()

#============================================================================
# Get all dose rows scheduled for today from medication_doses
def get_today_elder_doses(elder_id: int) -> List[Dict]:
    dose_rows = _fetch_today_dose_rows(elder_id)

    return _sort_by_scheduled_time(dose_rows)
#============================================================================
# Fetch one dose row with medication details by dose_id
def _fetch_dose_by_id(dose_id: int) -> Optional[Dict]:
    connection = get_db_connection()

    try:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT
                md.id AS dose_id,
                md.elder_medication_id,
                md.elder_id,
                md.scheduled_time,
                md.dose_date,
                md.status,
                md.snooze_count,
                md.snoozed_until,
                md.created_at AS dose_created_at,
                md.taken_at,
                md.missed_at,
                md.last_updated_at,
                em.display_name_for_elder,
                em.dosage_amount,
                em.dosage_unit,
                em.usage_instruction,
                em.short_description,
                em.treatment_duration_type,
                em.start_date,
                em.end_date,
                em.times_per_day,
                em.first_reminder_time,
                em.days_pattern,
                mc.id AS catalog_medication_id,
                mc.brand_name_ar,
                mc.generic_name_en,
                mc.med_category,
                mc.uses_ar,
                mc.food_guide_ar
                
            FROM medication_doses md
            JOIN elder_medications em
                ON md.elder_medication_id = em.id
            JOIN medications_catalog mc
                ON em.catalog_medication_id = mc.id
            WHERE md.id = ?
            """,
            (dose_id,),
        )

        row = cursor.fetchone()

        if not row:
            return None

        return _row_to_dict(row)

    finally:
        connection.close()


# Check if a medication_doses row is actionable now
def _is_current_medication_dose(record: Dict) -> bool:
    status = record.get("status")

    if status == "pending":
        scheduled_time = _parse_reminder_time(record.get("scheduled_time"))

        if scheduled_time is None:
            return False

        now = datetime.now()
        scheduled_datetime = datetime.combine(date.today(), scheduled_time)

        window_start = scheduled_datetime - timedelta(
            minutes=CURRENT_DOSE_BEFORE_MINUTES
        )
        window_end = scheduled_datetime + timedelta(
            minutes=CURRENT_DOSE_AFTER_MINUTES
        )

        return window_start <= now <= window_end

    if status == "snoozed":
        snoozed_until = _parse_datetime(record.get("snoozed_until"))

        if snoozed_until is None:
            return False

        now = datetime.now()
        window_end = snoozed_until + timedelta(
            minutes=CURRENT_DOSE_AFTER_MINUTES
        )

        return snoozed_until <= now <= window_end

    return False


# Get the current dose from medication_doses
def get_current_dose(elder_id: int) -> Optional[Dict]:
    dose_rows = _fetch_today_dose_rows(elder_id)

    current_doses = [
        dose
        for dose in dose_rows
        if dose.get("status") in {"pending", "snoozed"}
        and _is_current_medication_dose(dose)
    ]

    if not current_doses:
        return None

    current_doses = _sort_by_scheduled_time(current_doses)

    return current_doses[0]


# Check if today has rows in medication_doses
def _has_today_dose_rows(elder_id: int) -> bool:
    connection = get_db_connection()

    try:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT COUNT(*) AS count
            FROM medication_doses
            WHERE elder_id = ?
              AND dose_date = ?
            """,
            (elder_id, _today_str()),
        )

        row = cursor.fetchone()

        return int(row["count"]) > 0

    finally:
        connection.close()


# Get completed elder medication IDs from medication_doses for today
def _get_completed_elder_medication_ids_for_today(elder_id: int) -> set[int]:
    connection = get_db_connection()

    try:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT elder_medication_id
            FROM medication_doses
            WHERE elder_id = ?
              AND dose_date = ?
              AND status IN ('taken', 'missed')
            """,
            (elder_id, _today_str()),
        )

        return {int(row["elder_medication_id"]) for row in cursor.fetchall()}

    finally:
        connection.close()


# Get remaining doses using medication_doses when available
def get_remaining_elder_doses(elder_id: int) -> List[Dict]:
    if _has_today_dose_rows(elder_id):
        dose_rows = _fetch_today_dose_rows(elder_id)
        now_time = datetime.now().time()

        remaining_doses = []

        for dose in dose_rows:
            status = dose.get("status")
            scheduled_time = _parse_reminder_time(dose.get("scheduled_time"))

            if status == "pending" and scheduled_time and scheduled_time >= now_time:
                remaining_doses.append(dose)

            elif status == "snoozed":
                remaining_doses.append(dose)

        return _sort_by_scheduled_time(remaining_doses)

    medications = get_elder_medications(elder_id)

    if not medications:
        return []

    completed_ids = _get_completed_elder_medication_ids_for_today(elder_id)

    remaining_doses = [
        medication
        for medication in medications
        if int(medication["elder_medication_id"]) not in completed_ids
        and _is_upcoming_today(medication)
    ]

    return _sort_by_reminder_time(remaining_doses)


# Get next dose from the filtered upcoming doses list
def get_next_elder_dose(elder_id: int) -> Optional[Dict]:
    remaining_doses = get_remaining_elder_doses(elder_id)

    if not remaining_doses:
        return None

    return remaining_doses[0]


# Get latest due dose for taken/missed confirmation flows
def get_latest_due_elder_dose(elder_id: int) -> Optional[Dict]:
    if _has_today_dose_rows(elder_id):
        dose_rows = _fetch_today_dose_rows(elder_id)
        now = datetime.now()

        due_doses = []

        for dose in dose_rows:
            status = dose.get("status")
            scheduled_time = _parse_reminder_time(dose.get("scheduled_time"))
            snoozed_until = _parse_datetime(dose.get("snoozed_until"))

            if status == "pending" and scheduled_time:
                scheduled_datetime = datetime.combine(date.today(), scheduled_time)

                if scheduled_datetime <= now:
                    due_doses.append(dose)

            elif status == "snoozed" and snoozed_until:
                if snoozed_until <= now:
                    due_doses.append(dose)

        if not due_doses:
            return None

        due_doses = _sort_by_scheduled_time(due_doses)

        return due_doses[-1]

    medications = get_elder_medications(elder_id)

    if not medications:
        return None

    completed_ids = _get_completed_elder_medication_ids_for_today(elder_id)

    due_doses = [
        medication
        for medication in medications
        if int(medication["elder_medication_id"]) not in completed_ids
        and _is_due_or_passed_today(medication)
    ]

    if not due_doses:
        return None

    due_doses = _sort_by_reminder_time(due_doses)

    return due_doses[-1]


    # Get current due dose only within the allowed snooze/action window.
def get_current_due_elder_dose(elder_id: int) -> Optional[Dict]:
    # If medication_doses has rows for today, use it as the source of truth.
    # Do not fall back to elder_medications because it does not have dose_id.
    if _has_today_dose_rows(elder_id):
        return get_current_dose(elder_id)

    medications = get_elder_medications(elder_id)

    if not medications:
        return None

    completed_ids = _get_completed_elder_medication_ids_for_today(elder_id)

    current_doses = [
        medication
        for medication in medications
        if int(medication["elder_medication_id"]) not in completed_ids
        and _is_current_due_window(medication)
    ]

    if not current_doses:
        return None

    current_doses = _sort_by_reminder_time(current_doses)

    return current_doses[0]

#=========================================================================
# Insert one adherence log row
def _insert_adherence_log(
    cursor,
    dose_id: int,
    elder_id: int,
    elder_medication_id: int,
    status: str,
    event_type: str,
    event_time: str,
    snooze_minutes: Optional[int] = None,
    note: Optional[str] = None,
) -> None:
    cursor.execute(
        """
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
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            dose_id,
            elder_id,
            elder_medication_id,
            status,
            event_type,
            event_time,
            snooze_minutes,
            note,
        ),
    )


# Mark one medication_doses row as taken and write adherence log
def mark_dose_taken(dose_id: int) -> Optional[Dict]:
    dose = _fetch_dose_by_id(dose_id)

    if not dose:
        return None

    now = _now_timestamp()

    connection = get_db_connection()

    try:
        cursor = connection.cursor()

        cursor.execute(
            """
            UPDATE medication_doses
            SET status = ?,
                taken_at = ?,
                missed_at = NULL,
                last_updated_at = ?
            WHERE id = ?
            """,
            ("taken", now, now, dose_id),
        )

        _insert_adherence_log(
            cursor=cursor,
            dose_id=dose_id,
            elder_id=int(dose["elder_id"]),
            elder_medication_id=int(dose["elder_medication_id"]),
            status="taken",
            event_type="taken",
            event_time=now,
        )

        connection.commit()

        updated_dose = _fetch_dose_by_id(dose_id)

        if updated_dose:
            updated_dose["operation_status"] = "success"

        return updated_dose

    except Exception:
        connection.rollback()
        raise

    finally:
        connection.close()


# Mark one medication_doses row as missed and write adherence log
def mark_dose_missed(dose_id: int) -> Optional[Dict]:
    dose = _fetch_dose_by_id(dose_id)

    if not dose:
        return None

    now = _now_timestamp()

    connection = get_db_connection()

    try:
        cursor = connection.cursor()

        cursor.execute(
            """
            UPDATE medication_doses
            SET status = ?,
                taken_at = NULL,
                missed_at = ?,
                last_updated_at = ?
            WHERE id = ?
            """,
            ("missed", now, now, dose_id),
        )

        _insert_adherence_log(
            cursor=cursor,
            dose_id=dose_id,
            elder_id=int(dose["elder_id"]),
            elder_medication_id=int(dose["elder_medication_id"]),
            status="missed",
            event_type="missed",
            event_time=now,
        )

        connection.commit()

        updated_dose = _fetch_dose_by_id(dose_id)

        if updated_dose:
            updated_dose["operation_status"] = "success"

        return updated_dose

    except Exception:
        connection.rollback()
        raise

    finally:
        connection.close()


# Snooze one medication_doses row once only and write adherence log
def snooze_dose(dose_id: int, minutes: int) -> Optional[Dict]:
    if minutes not in {15, 20, 30}:
        return {
            "operation_status": "invalid_snooze_minutes",
            "allowed_minutes": [15, 20, 30],
        }

    dose = _fetch_dose_by_id(dose_id)

    if not dose:
        return None

    if int(dose.get("snooze_count") or 0) >= 1:
        now_text = _now_timestamp()

        connection = get_db_connection()

        try:
            cursor = connection.cursor()

            cursor.execute(
                """
                UPDATE medication_doses
                SET status = ?,
                    taken_at = NULL,
                    missed_at = ?,
                    last_updated_at = ?
                WHERE id = ?
                  AND status = 'snoozed'
                """,
                ("missed", now_text, now_text, dose_id),
            )

            _insert_adherence_log(
                cursor=cursor,
                dose_id=dose_id,
                elder_id=int(dose["elder_id"]),
                elder_medication_id=int(dose["elder_medication_id"]),
                status="missed",
                event_type="missed",
                event_time=now_text,
                note="Snooze already used. Dose marked as missed.",
            )

            connection.commit()

            updated_dose = _fetch_dose_by_id(dose_id)

            if updated_dose:
                updated_dose["operation_status"] = "snooze_already_used"
                return updated_dose

            dose["operation_status"] = "snooze_already_used"
            return dose

        except Exception:
            connection.rollback()
            raise

        finally:
            connection.close()

    now = datetime.now()
    now_text = now.isoformat(timespec="seconds")
    snoozed_until = (now + timedelta(minutes=minutes)).strftime("%H:%M")

    connection = get_db_connection()

    try:
        cursor = connection.cursor()

        cursor.execute(
            """
            UPDATE medication_doses
            SET status = ?,
                snooze_count = snooze_count + 1,
                snoozed_until = ?,
                last_updated_at = ?
            WHERE id = ?
            """,
            ("snoozed", snoozed_until, now_text, dose_id),
        )

        _insert_adherence_log(
            cursor=cursor,
            dose_id=dose_id,
            elder_id=int(dose["elder_id"]),
            elder_medication_id=int(dose["elder_medication_id"]),
            status="snoozed",
            event_type="snoozed",
            event_time=now_text,
            snooze_minutes=minutes,
        )

        connection.commit()

        updated_dose = _fetch_dose_by_id(dose_id)

        if updated_dose:
            updated_dose["operation_status"] = "success"

        return updated_dose

    except Exception:
        connection.rollback()
        raise

    finally:
        connection.close()
#===================================================================

# Build adherence summary for today from medication_doses
def get_today_adherence_summary(elder_id: int) -> Dict:
    _expire_overdue_doses_for_today(elder_id)

    connection = get_db_connection()

    try:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT status, COUNT(*) AS count
            FROM medication_doses
            WHERE elder_id = ?
              AND dose_date = ?
            GROUP BY status
            """,
            (elder_id, _today_str()),
        )

        counts = {row["status"]: int(row["count"]) for row in cursor.fetchall()}

        total = sum(counts.values())

        return {
            "total": total,
            "taken": int(counts.get("taken", 0)),
            "missed": int(counts.get("missed", 0)),
            "snoozed": int(counts.get("snoozed", 0)),
            "pending": int(counts.get("pending", 0)),
            "no_response": int(counts.get("no_response", 0)),
        }

    finally:
        connection.close()


# Select the target dose for voice actions such as taken and missed
def _get_target_dose_for_action(elder_id: int) -> Optional[Dict]:
    return get_current_due_elder_dose(elder_id)


# Compatibility wrapper for older service code
def record_dose_event(
    elder_id: int,
    event_type: str,
) -> Optional[Dict]:
    if event_type not in {"taken", "missed"}:
        return None

    dose = _get_target_dose_for_action(elder_id)

    if not dose:
        return None

    if "dose_id" not in dose:
        return None

    dose_id = int(dose["dose_id"])

    if event_type == "taken":
        return mark_dose_taken(dose_id)

    return mark_dose_missed(dose_id)


# Compatibility wrapper for older service code
def record_dose_snooze(
    elder_id: int,
    minutes: int,
) -> Optional[Dict]:
    dose = get_current_due_elder_dose(elder_id)

    if not dose:
        return None

    if "dose_id" not in dose:
        return None

    return snooze_dose(int(dose["dose_id"]), minutes)


# Compatibility wrapper for older service code
def get_adherence_summary(elder_id: int) -> Dict:
    summary = get_today_adherence_summary(elder_id)

    return {
        "total_doses": summary["total"],
        "taken_count": summary["taken"],
        "missed_count": summary["missed"],
        "remaining_count": summary["pending"] + summary["snoozed"],
        "snoozed_count": summary["snoozed"],
        "pending_count": summary["pending"],   
        "no_response_count": summary["no_response"],
    }