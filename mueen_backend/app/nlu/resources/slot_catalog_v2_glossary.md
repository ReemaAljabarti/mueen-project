# Slot Catalog JSON — Glossary (v2)

This document explains the operational fields used in:

slot_catalog_v2.json

It is intended for developers who need a quick, clear understanding of the JSON structure without reviewing the full Slot Catalog reference document.

---

## 1) type

Defines the data type of the slot.

Allowed values:

- string  
  Free text value (e.g., MED_NAME)

- integer  
  Whole number

- boolean  
  true / false

- enum  
  Must match one value from a predefined list

- object  
  Internal structured object built by the system

Purpose:  
Determines how validation and coercion are applied during NLU processing.

---

## 2) allowed_values

Used only when:

- type = enum
- or integer with restricted values

Represents the official whitelist of valid values.

If a value outside this list is detected → clarification is required.

Example:

"allowed_values": [15, 20, 30]

---

## 3) default

Optional field.

Defines the default value if:

- The user does not specify it
- And the slot is inferable
- And no ambiguity exists

Example:

DATE_SCOPE → default = "today"

The system applies defaults only when logically safe.

---

## 4) inferable

Boolean flag.

Indicates whether the system may derive this slot automatically from:

- Intent type
- Context
- Session state

Values:

- true → may be auto-derived
- false → must be provided explicitly by the user or via clarification (not inferred automatically)

Example:

ADHERENCE_STATUS is inferable because the intent determines taken/missed.

---

## 5) internal_only

Boolean flag.

Indicates whether the slot:

- May appear in the NLU response
- Or is used internally only during context resolution

Values:
 
- true → never exposed in NLU output
- false → may appear in NLU output

Example:

DOSE_INSTANCE → internal_only = true  
It is resolved later and never returned directly by NLU.

---

## 6) INFO_TYPE

Defines what type of medication information the user is requesting.

Type:
- enum

Allowed values:

- usage  
  The user is asking about medication usage or purpose  
  → maps to: uses_ar

- food_guide  
  The user is asking about food-related instructions  
  → maps to: food_guide_ar

Purpose:  
Used to control which field should be returned from the database layer.

Behavior:

- If INFO_TYPE = usage  
  → return uses_ar only

- If INFO_TYPE = food_guide  
  → return food_guide_ar only

Notes:

- This slot is inferable from user language
- It should not be guessed under ambiguity
- If not provided, the system may default to "usage" at integration level


# Validation Principles

The NLU layer must:

- Never generate slots not defined in slot_catalog_v2.json
- Never allow values outside allowed_values
- Never expose internal_only slots
- Only infer slots when rules explicitly allow it
- Avoid guessing under ambiguity

---

# Versioning

This glossary corresponds to:

slot_catalog_v2.json

Any structural change to the JSON requires updating this glossary.