from __future__ import annotations

from typing import Any, Dict, List

from app.core.config import settings
from app.nlu.intent_catalog import get_intent_names
from app.nlu.keywords import extract_keywords
from app.nlu.providers.openai_provider import parse_intent_with_openai
from app.nlu.schemas import (
    NluParseRequest,
    NluParseResponse,
    PendingQuestion,
)
from app.nlu.text_normalizer import normalize_arabic

ALLOWED_SLOT_NAMES = {
    "MED_NAME",
    "MED_CATEGORY",
    "SNOOZE_MINUTES",
}

ALLOWED_SNOOZE_MINUTES = {15, 20, 30}

ALLOWED_MED_CATEGORIES = {
    "قلب وضغط",
    "سكري",
    "كوليسترول",
    "مسكنات",
    "ربو",
    "مرطب العين",
    "روماتيزم ومناعة",
    "أعصاب",
    "جهاز هضمي وحموضة",
    "فقر الدم",
    "مرخي عضلات",
    "قولون",
    "مسالك بولية",
    "مكملات غذائية",
    "مضاد حيوي",
    "حساسية وجيوب أنفية",
    "ضغط العين",
    "صداع نصفي",
}


def _safe_confidence(value: object) -> float:
    """
    Convert any confidence value into a safe float between 0.0 and 1.0.

    Invalid values are converted to 0.0 instead of breaking the flow.
    """
    try:
        confidence = float(value)
    except (TypeError, ValueError):
        return 0.0

    return max(0.0, min(confidence, 1.0))


def _validate_slots(slots: object) -> tuple[Dict[str, Any], List[str]]:
    """
    Validate and clean provider-returned slots.

    Rules in v1:
    - Accept only officially supported slot names
    - Validate SNOOZE_MINUTES against allowed values
    - Validate MED_CATEGORY against allowed catalog values
    - Keep MED_NAME only if it is a non-empty string
    """
    if not isinstance(slots, dict):
        return {}, []

    validated_slots: Dict[str, Any] = {}
    issues: List[str] = []

    for slot_name, slot_value in slots.items():
        if slot_name not in ALLOWED_SLOT_NAMES:
            if "invalid_slot_name" not in issues:
                issues.append("invalid_slot_name")
            continue

        if slot_name == "SNOOZE_MINUTES":
            try:
                minutes = int(slot_value)
            except (TypeError, ValueError):
                if "invalid_slot_value" not in issues:
                    issues.append("invalid_slot_value")
                continue

            if minutes not in ALLOWED_SNOOZE_MINUTES:
                if "invalid_slot_value" not in issues:
                    issues.append("invalid_slot_value")
                continue

            validated_slots["SNOOZE_MINUTES"] = minutes
            continue

        if slot_name == "MED_CATEGORY":
            if not isinstance(slot_value, str):
                if "invalid_slot_value" not in issues:
                    issues.append("invalid_slot_value")
                continue

            category = slot_value.strip()
            if category not in ALLOWED_MED_CATEGORIES:
                if "invalid_slot_value" not in issues:
                    issues.append("invalid_slot_value")
                continue

            validated_slots["MED_CATEGORY"] = category
            continue

        if slot_name == "MED_NAME":
            if not isinstance(slot_value, str):
                if "invalid_slot_value" not in issues:
                    issues.append("invalid_slot_value")
                continue

            med_name = slot_value.strip()
            if not med_name:
                if "invalid_slot_value" not in issues:
                    issues.append("invalid_slot_value")
                continue

            validated_slots["MED_NAME"] = med_name
            continue

    return validated_slots, issues


def parse_text(req: NluParseRequest) -> NluParseResponse:
   # print("### NEW NLU SERVICE VERSION LOADED ###")
    
    """
    Main NLU parsing entry point.

    Flow:
    1) Read raw text
    2) Normalize Arabic text
    3) Extract keywords
    4) Parse intent with OpenAI
    5) Validate the result
    6) Return Unknown if no reliable intent is found
    """

    # Read raw input text safely
    raw_text = (req.text or "").strip()

    # Normalize text for consistent downstream parsing
    normalized_text = normalize_arabic(raw_text)

    # Extract supportive keywords from normalized text
    extracted_keywords = extract_keywords(normalized_text)

    # Load supported intents from the shared catalog
    supported_intents = set(get_intent_names())

    model_result = None
    detected_intent = None
    confidence_score = 0.0
    detected_slots = {}
    final_keywords = extracted_keywords
    slot_issues: List[str] = []

    # OpenAI is the only intent parser in the main path
    if settings.NLU_PROVIDER.lower() == "openai":
        model_result = parse_intent_with_openai(normalized_text=normalized_text)

        if isinstance(model_result, dict):
            model_intent = model_result.get("intent")
            model_confidence = _safe_confidence(model_result.get("confidence"))
            model_slots = model_result.get("slots") or {}
            model_keywords = model_result.get("keywords") or extracted_keywords

            if isinstance(model_intent, str):
                model_intent = model_intent.strip()

            # Accept only supported intents from the shared catalog
            if model_intent in supported_intents:
                detected_intent = model_intent
                confidence_score = model_confidence
                detected_slots, slot_issues = _validate_slots(model_slots)
                final_keywords = model_keywords if isinstance(model_keywords, list) else extracted_keywords

    # Return valid OpenAI result when confidence is high enough
    if detected_intent and confidence_score >= 0.60:
        # Special case: ask for snooze duration if missing
        if detected_intent == "SnoozeMedication" and not detected_slots.get("SNOOZE_MINUTES"):
            return NluParseResponse(
                intent="SnoozeMedication",
                confidence=confidence_score,
                normalized_text=normalized_text,
                slots=detected_slots,
                keywords=final_keywords,
                issues=list(dict.fromkeys(slot_issues + ["missing_required_slot"])),
                candidates=None,
                pending_question=PendingQuestion(
                    question="كم مدة التأجيل؟",
                    missing_slots=["SNOOZE_MINUTES"],
                    candidate_values={"SNOOZE_MINUTES": [15, 20, 30]},
                ),
            )

        return NluParseResponse(
            intent=detected_intent,
            confidence=confidence_score,
            normalized_text=normalized_text,
            slots=detected_slots,
            keywords=final_keywords,
            issues=slot_issues,
            candidates=None,
            pending_question=None,  
        )

    # Safe final fallback when no reliable model result is found
    return NluParseResponse(
        intent="Unknown",
        confidence=0.30,
        normalized_text=normalized_text,
        slots={},
        keywords=extracted_keywords,
        issues=["low_confidence"],
        candidates=None,
        pending_question=None,
    )