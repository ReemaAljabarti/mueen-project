from __future__ import annotations

from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from typing import Dict, List, Optional

import yaml


def _normalize_text(text: str) -> str:
    """
    Apply very light text normalization for catalog helpers.

    This is used only for internal catalog matching,
    not as the main Arabic normalizer in the NLU pipeline.
    """
    return " ".join((text or "").strip().split())


@dataclass(frozen=True)
class IntentDefinition:
    """
    Structured representation of one intent loaded from intents.yaml.

    This stores the core intent metadata used by the NLU layer.
    """
    name: str
    category: str
    utterances: List[str]
    notes: List[str]


@lru_cache(maxsize=1)
def load_intent_definitions() -> List[IntentDefinition]:
    """
    Load intents.yaml and convert it into structured IntentDefinition objects.

    The result is cached so the YAML file is read only once per runtime.
    """
    # Resolve the local path to app/nlu/resources/intents.yaml
    base_dir = Path(__file__).resolve().parent
    yaml_path = base_dir / "resources" / "intents.yaml"

    if not yaml_path.exists():
        raise FileNotFoundError(f"intents.yaml not found at: {yaml_path}")

    # Read YAML content safely
    data = yaml.safe_load(yaml_path.read_text(encoding="utf-8")) or {}
    intents_data = data.get("intents", []) or []
    definitions: List[IntentDefinition] = []

    # Parse each intent block from the YAML file
    for item in intents_data:
        if not isinstance(item, dict):
            continue

        name = str(item.get("name") or "").strip()
        if not name:
            continue

        category = str(item.get("category") or "").strip()

        # Normalize utterances lightly before storing them
        raw_utterances = item.get("utterances") or []
        utterances: List[str] = []
        for value in raw_utterances:
            normalized_value = _normalize_text(str(value))
            if normalized_value:
                utterances.append(normalized_value)

        # Keep notes as clean non-empty strings
        raw_notes = item.get("notes") or []
        notes: List[str] = []
        for value in raw_notes:
            note_text = str(value).strip()
            if note_text:
                notes.append(note_text)

        definitions.append(
            IntentDefinition(
                name=name,
                category=category,
                utterances=utterances,
                notes=notes,
            )
        )
    return definitions


@lru_cache(maxsize=1)
def get_intent_names() -> List[str]:
    """
    Return the list of valid intent names from intents.yaml.
    """
    return [intent.name for intent in load_intent_definitions()]


@lru_cache(maxsize=1)
def get_intent_map() -> Dict[str, IntentDefinition]:
    """
    Build a fast lookup dictionary: intent name -> intent definition.
    """
    return {intent.name: intent for intent in load_intent_definitions()}


def get_intent_definition(intent_name: str) -> Optional[IntentDefinition]:
    """
    Return one intent definition by name.

    Returns None if the name is empty or not found.
    """
    if not intent_name:
        return None

    return get_intent_map().get(intent_name)