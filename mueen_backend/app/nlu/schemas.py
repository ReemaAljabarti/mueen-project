from typing import Any, Dict, List, Optional, Literal
from pydantic import BaseModel, Field


# ==========================================================
# Shared Literal Types (Fixed Allowed Values)
# ==========================================================

# Used for queries that depend on time range
DateScopeLiteral = Literal["today", "this_week"]

# Internal medication categories supported by the system
MedCategoryLiteral = Literal[
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
]

# Allowed snooze durations (strict range)
SnoozeMinutesLiteral = Literal[15, 20, 30]

# Adherence status derived from intent type (not free text)
AdherenceStatusLiteral = Literal["taken", "missed"]


# ✅ NEW — نوع المعلومة المطلوبة من الدواء
# يحدد هل المستخدم يريد:
# - الاستخدام (uses_ar)
# - أو إرشادات الأكل (food_guide_ar)
InfoTypeLiteral = Literal["usage", "food_guide"]


# ==========================================================
# Issue Codes
# ==========================================================

IssueCodeLiteral = Literal[
    "low_confidence",
    "ambiguous_medication",
    "ambiguous_dose_instance",
    "missing_required_slot",
    "invalid_slot_value",
    "invalid_slot_name",
    "out_of_scope",
    "no_data",
]


# ==========================================================
# Request Schema
# ==========================================================

class NluParseRequest(BaseModel):
    """
    Represents the input sent to the NLU layer.
    This should already be normalized Arabic text from STT.
    """

    text: str = Field(
        ...,
        min_length=1,
        description="User utterance after STT processing",
    )

    session_id: Optional[str] = Field(
        None,
        description="Conversation session identifier",
    )

    locale: Optional[str] = Field(
        default="ar-SA",
        description="Locale of the user input",
    )


# ==========================================================
# Clarification Model
# ==========================================================

class PendingQuestion(BaseModel):
    """
    Used when the system cannot proceed directly
    and needs clarification from the user.
    """

    question: str = Field(...)

    missing_slots: List[str] = Field(default_factory=list)

    candidate_values: Optional[Dict[str, List[Any]]] = None


# ==========================================================
# NLU Response Schema
# ==========================================================

class NluParseResponse(BaseModel):
    """
    Final structured output produced by the NLU layer.
    """

    intent: Optional[str] = None

    confidence: float = Field(..., ge=0.0, le=1.0)
 
    normalized_text: str

    # Do not strictly validate slot values here to avoid breaking existing flow
    # INFO_TYPE is now supported and may appear inside slots when provided by the model

    slots: Dict[str, Any] = Field(default_factory=dict)

    keywords: List[str] = Field(default_factory=list)

    issues: List[IssueCodeLiteral] = Field(default_factory=list)

    candidates: Optional[Dict[str, List[Any]]] = None

    pending_question: Optional[PendingQuestion] = None