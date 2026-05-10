from typing import List, Literal, Optional
from pydantic import BaseModel, Field


# Request model for DB + NLU endpoints.
# elder_id is optional to keep Swagger testing flexible,
# but Flutter should send the real elder_id for schedule queries.
class DbNluParseRequest(BaseModel):
    text: str
    elder_id: Optional[int] = None


# Represents a compact medication response returned to the client.
# uses_ar and food_guide_ar are optional because the response may return
# either usage information or food-guide information based on response_mode.
class MedicationUsageRecord(BaseModel):
    brand_name_ar: str
    uses_ar: Optional[str] = None
    food_guide_ar: Optional[str] = None


# Standard response shape for DB retrieval.
# Used by direct DB queries and NLU-to-DB integration flows.
class DbRetrievalResponse(BaseModel):
    status: Literal[
        "success",
        "not_found",
        "unsupported_intent",
        "invalid_input",
        "ambiguous",
    ]

    # Shows which retrieval path was used.
    query_type: Literal["by_name", "by_category", "nlu_integration"]

    # Shows which DB field was used for matching when available.
    matched_by: Optional[
        Literal[
            "brand_name_ar",
            "brand_name_ar_fuzzy",
            "display_name_for_elder",
            "display_name_for_elder_fuzzy",
            "elder_medication_name",
            "elder_medication_name_fuzzy",
            "med_category",
        ]
    ] = None

    # Original value used for matching or metadata for schedule responses.
    matched_value: str

    # Number of returned records.
    count: int = Field(ge=0)

    # Compact records returned to the client.
    result: List[MedicationUsageRecord] = Field(default_factory=list)

    # Notes or problems related to the request.
    issues: List[str] = Field(default_factory=list)

    # Used when status is ambiguous.
    candidates: List[str] = Field(default_factory=list)


# Final response shape for:
# raw text -> NLU -> DB retrieval -> spoken text formatter. 
class DbNluSpokenResponse(BaseModel):
    nlu_intent: str

    # Final formatting mode used for spoken_text. 
    response_mode: Literal["usage", "food_guide"]

    # Original structured DB response.
    db_response: DbRetrievalResponse

    # Final Arabic text ready for TTS.
    spoken_text: str