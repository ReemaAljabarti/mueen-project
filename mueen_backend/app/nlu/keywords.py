from __future__ import annotations
from typing import List


def extract_keywords(text: str) -> List[str]:
    """
    Extract simple tokens from the normalized user text.

    Purpose:
    - Keep useful words from the user input
    - Help later components such as logging or DB lookup
    - This function does NOT determine the intent

    Important:
    The OpenAI model remains the main source of intent understanding.
    Keywords here are only supportive signals.
    """

    # Return empty list if the text is empty
    if not text:
        return []

    # Split the normalized text into tokens
    tokens = text.split()

    # Remove empty tokens and extra whitespace
    keywords = [token.strip() for token in tokens if token.strip()]

    # Limit the number of returned keywords to reduce noise
    return keywords[:8]