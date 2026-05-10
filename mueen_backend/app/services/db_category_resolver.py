from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import List, Optional, Set

from app.services.db_medication_queries import get_distinct_med_categories


# Common filler words that should not affect category resolution.
CATEGORY_FILLER_WORDS = [
    "دواء",
    "أدوية",
    "ادوية",
    "علاج",
    "أبغى",
    "ابغى",
    "أبي",
    "ابي",
    "وش",
    "استخدامات",
    "استعمال",
    "اقدر",
    "أقدر",
    "اخذ",
    "آخذ",
    "مع",
    "الأكل",
    "الاكل",
]


# Represents the output of category resolution before DB search.
@dataclass
class CategoryResolutionResult:
    status: str
    matched_category: Optional[str] = None
    candidates: List[str] = field(default_factory=list)


# Normalize one Arabic token before comparison.
def _normalize_token(token: str) -> str:
    normalized = token.strip()

    # Remove leading "ال" to reduce variation like:
    # "الضغط" -> "ضغط"
    # "القلب" -> "قلب"
    if normalized.startswith("ال") and len(normalized) > 2:
        normalized = normalized[2:]

    # Remove leading connector "و" when attached to the token.
    # Examples:
    # "والضغط" -> "الضغط" -> "ضغط"
    # "وقلب" -> "قلب"
    if normalized.startswith("و") and len(normalized) > 1:
        normalized = normalized[1:]
        if normalized.startswith("ال") and len(normalized) > 2:
            normalized = normalized[2:]

    return normalized.strip()


# Normalize free-text category input before comparison.
def _normalize_text(text: str) -> str:
    normalized = text.strip()

    # Remove punctuation and separators
    normalized = re.sub(r"[\/،,\-+]+", " ", normalized)

    # Remove common filler words from user phrasing
    for filler_word in CATEGORY_FILLER_WORDS:
        normalized = normalized.replace(filler_word, " ")

    # Collapse repeated spaces
    normalized = " ".join(normalized.split())

    return normalized


# Convert text into a unique normalized token set for comparison.
def _tokenize(text: str) -> Set[str]:
    normalized = _normalize_text(text)
    if not normalized:
        return set()

    tokens: Set[str] = set()
    for token in normalized.split():
        cleaned_token = _normalize_token(token)
        if cleaned_token:
            tokens.add(cleaned_token)

    return tokens


# Build a distinctiveness map from the official DB categories.
# A token is considered stronger if it appears in fewer categories.
def _build_token_frequency(categories: List[str]) -> dict[str, int]:
    token_frequency: dict[str, int] = {}

    for category in categories:
        category_tokens = _tokenize(category)
        for token in category_tokens:
            token_frequency[token] = token_frequency.get(token, 0) + 1

    return token_frequency


# Score one user input against one official category.
# Higher score means a stronger and safer match.
def _score_category_match(
    user_tokens: Set[str],
    category_tokens: Set[str],
    token_frequency: dict[str, int],
) -> float:
    if not user_tokens or not category_tokens:
        return 0.0

    shared_tokens = user_tokens.intersection(category_tokens)
    if not shared_tokens:
        return 0.0

    # Coverage rewards how much of the category was matched
    coverage_score = len(shared_tokens) / len(category_tokens)

    # Precision rewards how much of the user input was useful
    precision_score = len(shared_tokens) / len(user_tokens)

    # Distinctive tokens are stronger than generic ones
    distinctiveness_score = sum(1 / token_frequency[token] for token in shared_tokens)

    return coverage_score + precision_score + distinctiveness_score


# Resolve free-text user input into one official DB category when possible.
def resolve_med_category(text: str) -> CategoryResolutionResult:
    user_tokens = _tokenize(text)
    if not user_tokens:
        return CategoryResolutionResult(status="not_found")

    official_categories = get_distinct_med_categories()
    if not official_categories:
        return CategoryResolutionResult(status="not_found")

    token_frequency = _build_token_frequency(official_categories)

    scored_matches: List[tuple[str, float]] = []
    for category in official_categories:
        category_tokens = _tokenize(category)
        score = _score_category_match(
            user_tokens=user_tokens,
            category_tokens=category_tokens,
            token_frequency=token_frequency,
        )

        if score > 0:
            scored_matches.append((category, score))

    if not scored_matches:
        return CategoryResolutionResult(status="not_found")

    scored_matches.sort(key=lambda item: item[1], reverse=True)

    best_category, best_score = scored_matches[0]

    # Keep only matches close to the best score
    close_matches = [
        category
        for category, score in scored_matches
        if score >= best_score - 0.25
    ]

    best_tokens = _tokenize(best_category)
    shared_best_tokens = user_tokens.intersection(best_tokens)

    # Distinctive shared tokens are safer than generic ones
    distinctive_shared_tokens = [
        token for token in shared_best_tokens if token_frequency[token] == 1
    ]

    # Case 1:
    # One strong winner and the full category meaning is covered
    if len(close_matches) == 1 and best_tokens.issubset(user_tokens):
        return CategoryResolutionResult(
            status="resolved",
            matched_category=best_category,
            candidates=[],
        )

    # Case 2:
    # One strong winner with at least two shared tokens
    if len(close_matches) == 1 and len(shared_best_tokens) >= 2:
        return CategoryResolutionResult(
            status="resolved",
            matched_category=best_category,
            candidates=[],
        )

    # Case 3:
    # One-token partial match can be resolved if the token is distinctive
    if len(close_matches) == 1 and len(distinctive_shared_tokens) >= 1:
        return CategoryResolutionResult(
            status="resolved",
            matched_category=best_category,
            candidates=[],
        )

    # Case 4:
    # Prefer a unique category if it contains a distinctive user token
    if len(close_matches) > 1:
        distinctive_candidates: List[str] = []

        for category in close_matches:
            category_tokens = _tokenize(category)
            shared_tokens = user_tokens.intersection(category_tokens)

            has_distinctive_token = any(
                token_frequency[token] == 1 for token in shared_tokens
            )

            if has_distinctive_token:
                distinctive_candidates.append(category)

        if len(distinctive_candidates) == 1:
            return CategoryResolutionResult(
                status="resolved",
                matched_category=distinctive_candidates[0],
                candidates=[],
            )

    return CategoryResolutionResult( 
        status="ambiguous",
        matched_category=None,
        candidates=close_matches,
    )