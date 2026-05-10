from __future__ import annotations

import re


def normalize_arabic(text: str) -> str:
    """
    Light Arabic text normalization for NLU.

    Purpose:
    - Clean STT output
    - Reduce simple spelling variation
    - Improve consistency before intent parsing

    Note:
    This function does NOT perform intent detection.
    """

    # Return empty string if input is empty
    if not text:
        return ""

    # ---- 1) Trim spaces ----
    text = text.strip()

    # ---- 2) Remove Arabic diacritics (tashkeel) ----
    text = re.sub(r"[ًٌٍَُِّْـ]", "", text)

    # ---- 3) Normalize Alef variants ----
    replacements = {
        "أ": "ا",
        "إ": "ا",
        "آ": "ا",
    }

    for source, target in replacements.items():
        text = text.replace(source, target)

    # ---- 4) Normalize Arabic digits to English ----
    arabic_digits = "٠١٢٣٤٥٦٧٨٩"
    english_digits = "0123456789"

    for arabic_digit, english_digit in zip(arabic_digits, english_digits):
        text = text.replace(arabic_digit, english_digit)

    # ---- 5) Collapse duplicated whitespace ----
    text = re.sub(r"\s+", " ", text)

    return text