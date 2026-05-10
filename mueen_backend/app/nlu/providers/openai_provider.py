from __future__ import annotations

import json
from typing import Any, Dict, List, Optional

from app.core.config import settings
from app.core.openai_client import openai_client
from app.nlu.intent_catalog import IntentDefinition, get_intent_names, load_intent_definitions


def parse_intent_with_openai(normalized_text: str) -> Optional[Dict[str, Any]]:
    """
    Parse normalized Arabic user text with the OpenAI model.

    Expected return format:
    {
        "intent": str,
        "confidence": float,
        "slots": dict,
        "keywords": list[str]
    }

    Returns None if the model call fails or the response is not usable.
    """
    if not normalized_text:
        return None

    # Load the official intent names and their definitions from the catalog.
    # These are used to constrain the model and reduce unsupported outputs.
    intent_names = get_intent_names()
    intent_definitions = load_intent_definitions()

    # Build a compact guide from intents.yaml so the model sees
    # real intent examples and notes, not only a short manual prompt.
    intent_guide = _build_intent_guide(intent_definitions)

    # Main system instructions for the NLU model.
    # This defines:
    # - output format
    # - supported slots
    # - category handling
    # - INFO_TYPE handling
    system_instructions = (
        "You are an NLU parser for an Arabic medication assistant.\n"
        "Classify the user's intent only.\n"
        "Return JSON with fields: intent, confidence, slots, keywords.\n"
        "Choose intent only from the allowed intents.\n"
        "If unclear, return intent='Unknown'.\n"
        "\n"
        "Relevant slot guidance:\n"

        # Medication name:
        # Return MED_NAME when the user mentions a real medication.
        "- MED_NAME: a medication name mentioned by the user, whether brand_name_ar or generic_name_en.\n"

        # Medication category:
        # Return MED_CATEGORY only when the user is clearly asking by category,
        # not by a specific medication name.
        "- MED_CATEGORY: a medication category only if the user clearly refers to a category.\n"
        "- Allowed MED_CATEGORY values: قلب وضغط، سكري، كوليسترول، مسكنات، ربو، مرطب العين، روماتيزم ومناعة، أعصاب، جهاز هضمي وحموضة، فقر الدم، مرخي عضلات، قولون، مسالك بولية، مكملات غذائية، مضاد حيوي، حساسية وجيوب أنفية، ضغط العين، صداع نصفي.\n"
        "- Use MED_CATEGORY only when the user clearly refers to a category.\n"
        "- Phrases like 'دواء السكري' or 'دواء الكوليسترول' or 'دواء القلب والضغط' are category references, not medication names, unless a real medication name is explicitly mentioned.\n"

        # INFO_TYPE:
        # This decides whether the user is asking about medication usage
        # or food-related instructions.
        "- INFO_TYPE: what type of medication information the user is asking for.\n"
        "- Allowed INFO_TYPE values: usage, food_guide.\n"
        "- usage: when the user asks about what the medication is used for.\n"
        "- food_guide: when the user asks about food-related instructions.\n"
        "- If the user asks about medication purpose, set INFO_TYPE = usage.\n"
        "- If the user asks about food timing or instructions, set INFO_TYPE = food_guide.\n"
        "- Do not invent other values for INFO_TYPE.\n"

        # Strong examples for INFO_TYPE:
        # These examples help the model separate usage questions from food guide questions.
        "- Example: 'وش استخدام جلوكوفاج' -> INFO_TYPE = usage.\n"
        "- Example: 'وش يفيد نكسيوم' -> INFO_TYPE = usage.\n"
        "- Example: 'وش يعالج سيمبيكورت' -> INFO_TYPE = usage.\n"
        "- Example: 'هل جلوكوفاج مع الاكل' -> INFO_TYPE = food_guide.\n"
        "- Example: 'هل نكسيوم قبل الاكل او بعده' -> INFO_TYPE = food_guide.\n"
        "- Example: 'هل سيمبيكورت يؤخذ مع الاكل' -> INFO_TYPE = food_guide.\n"
        "- Example: 'هل يؤخذ على معدة فارغة' -> INFO_TYPE = food_guide.\n"
        "- Example: 'متى اخذه بالنسبة للاكل' -> INFO_TYPE = food_guide.\n"

        # Priority rule:
        # Prefer the exact medication name over the general category
        # when both appear in the same user text.
        "- Prefer MED_NAME when the user explicitly mentions a real medication name.\n"
        "- If the user mentions a general treatment type or disease-related group, return MED_CATEGORY instead of MED_NAME.\n"

        # Snooze:
        # Only relevant for medication delay requests.
        "- SNOOZE_MINUTES: snooze duration in minutes only when the user explicitly requests delaying medication.\n"
        "- Allowed values are 15, 20, or 30 only.\n"

        # Strict slot safety rules:
        # The model must use only official slot names and allowed values.
        "- Use official slot names exactly as written: MED_NAME, MED_CATEGORY, INFO_TYPE, SNOOZE_MINUTES.\n"
        "- Do not invent slot names.\n"
        "- Do not invent slot values.\n"

        "\n"
        "Intent catalog with Arabic examples:\n"
        f"{intent_guide}"
    )

    # Runtime user prompt:
    # Includes the allowed intent names and the current normalized text.
    user_prompt = (
        f"Allowed intents: {intent_names}\n"
        f"User text (Arabic): {normalized_text}\n"
        "Classify the intent using the catalog examples.\n"
        "Return JSON only."
    )

    try:
        # Call the OpenAI model using the configured NLU model and temperature.
        response = openai_client.responses.create(
            model=settings.OPENAI_NLU_MODEL,
            temperature=settings.NLU_TEMPERATURE,
            input=[
                {"role": "system", "content": system_instructions},
                {"role": "user", "content": user_prompt},
            ],
        )

        # Extract plain text from the Responses API object.
        response_text = _responses_text(response)

        if not response_text:
            return None

        # Remove markdown fences if the model wrapped the JSON.
        cleaned_response_text = _clean_json_text(response_text)

        data = json.loads(cleaned_response_text)

        # Response must be a JSON object.
        if not isinstance(data, dict):
            return None

        intent = data.get("intent")
        confidence = data.get("confidence")
        slots = data.get("slots") or {}
        keywords = data.get("keywords") or []

        # Keep slots as dict only.
        if not isinstance(slots, dict):
            slots = {}

        # Keep keywords as a clean short list of strings.
        if not isinstance(keywords, list):
            keywords = []
        keywords = [str(item).strip() for item in keywords if str(item).strip()][:8]

        # Normalize returned intent.
        if not isinstance(intent, str) or not intent.strip():
            intent = "Unknown"
        else:
            intent = intent.strip()

        # Downgrade any unsupported intent to Unknown.
        # This prevents the system from accepting unofficial intent names.
        if intent_names and intent not in intent_names:
            intent = "Unknown"
            confidence = 0.0
            slots = {}

        return {
            "intent": intent,
            "confidence": confidence,
            "slots": slots,
            "keywords": keywords,
        }

    except Exception:
        # Fail safely.
        # service.py will decide the fallback behavior.
        return None


def _build_intent_guide(intent_definitions: List[IntentDefinition]) -> str:
    """
    Build a compact text guide from intents.yaml definitions.
    """
    if not intent_definitions:
        return ""

    sections: List[str] = []

    for intent_def in intent_definitions:
        name = str(intent_def.name).strip()
        category = str(intent_def.category).strip()
        utterances = intent_def.utterances or []
        notes = intent_def.notes or []

        # Keep only a few examples to avoid prompt bloat.
        example_utterances = [
            str(item).strip()
            for item in utterances
            if str(item).strip()
        ][:6]

        # Keep only a few notes to keep the prompt compact.
        note_lines = [
            str(item).strip()
            for item in notes
            if str(item).strip()
        ][:3]

        section_lines = [f"Intent: {name}"]

        if category:
            section_lines.append(f"Category: {category}")

        if example_utterances:
            section_lines.append("Examples:")
            for example in example_utterances:
                section_lines.append(f"- {example}")

        if note_lines:
            section_lines.append("Notes:")
            for note in note_lines:
                section_lines.append(f"- {note}")

        sections.append("\n".join(section_lines))

    return "\n\n".join(sections)


def _responses_text(response: Any) -> Optional[str]:
    """
    Extract plain text from an OpenAI Responses API result.
    """
    try:
        output_text = getattr(response, "output_text", None)
        if output_text:
            return str(output_text).strip()
    except Exception:
        pass

    try:
        output_items = getattr(response, "output", None) or []
        for item in output_items:
            content_items = getattr(item, "content", None) or []
            for content_item in content_items:
                if getattr(content_item, "type", None) == "output_text":
                    text_value = getattr(content_item, "text", None)
                    if text_value:
                        return str(text_value).strip()
    except Exception:
        return None

    return None


def _clean_json_text(text: str) -> str:
    """
    Remove markdown code fences if present.
    """
    if not text:
        return ""

    text = text.strip()

    if text.startswith("```json"):
        text = text[len("```json"):].strip()
    elif text.startswith("```"):
        text = text[len("```"):].strip()

    if text.endswith("```"):
        text = text[:-3].strip()

    return text