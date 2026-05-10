from __future__ import annotations


# Very small set of words or phrases that benefit from partial tashkeel
# to improve Arabic pronunciation in TTS output.
PARTIAL_TASHKEEL_MAP = {
    "بروفين": "بروفِين",
    "فيرو فول": "فِيرو فُول",
    "ما لقيت": "ما لِقيت",
}


# Minimal phrase-level replacements that are still useful at the TTS layer.
# The main wording should already be handled by AssistantResponseFormatter.
PHRASE_REPLACEMENTS = {
    "لم أتمكن من العثور على": "ما لِقيت",
    "لم أتمكن من العثور": "ما لِقيت",
    "لم يتم العثور على": "ما لِقيت",
}


def _normalize_spacing(text: str) -> str:
    """
    Normalize whitespace in the input text.

    This function removes leading and trailing spaces
    and collapses multiple internal spaces into a single space.
    """
    return " ".join(text.strip().split())


def _apply_phrase_replacements(text: str) -> str:
    """
    Apply a very small set of phrase-level replacements.

    This layer should remain minimal because the final spoken wording
    is expected to be built mainly in AssistantResponseFormatter.
    """
    result = text
    for old, new in PHRASE_REPLACEMENTS.items():
        result = result.replace(old, new)
    return result


def _apply_partial_tashkeel(text: str) -> str:
    """
    Apply partial tashkeel to specific words when needed.

    This is intentionally limited to known cases that showed
    better pronunciation during testing.
    """
    result = text
    for old, new in PARTIAL_TASHKEEL_MAP.items():
        result = result.replace(old, new)
    return result


def format_tts_text(text: str) -> str:
    """
    Convert raw backend text into a TTS-friendly spoken version.

    Processing steps:
    1. Validate the input text.
    2. Normalize spacing.
    3. Apply minimal phrase replacements.
    4. Normalize spacing again after replacements.
    5. Apply partial tashkeel where needed.

    Returns:
        A final text string that is more suitable for OpenAI TTS.
    """
    if not text or not text.strip():
        return "معليش، ما عندي نص صوتي حاليًا."

    result = _normalize_spacing(text)
    result = _apply_phrase_replacements(result)
    result = _normalize_spacing(result)
    result = _apply_partial_tashkeel(result)

    return result