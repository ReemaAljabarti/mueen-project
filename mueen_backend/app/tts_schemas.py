from typing import Literal, Optional

from pydantic import BaseModel, Field

from app.db_schemas import DbRetrievalResponse


class TtsTestRequest(BaseModel):
    # Raw text sent directly to the isolated TTS test endpoint
    text: str = Field(..., min_length=1, description="Text to convert to speech")


class TtsTestResponse(BaseModel):
    # Echoed input text after minimal cleanup
    text: str

    # TTS-friendly text after formatter processing
    formatted_text: str

    # Output audio format configured in application settings
    audio_format: str

    # Base64-encoded audio bytes for easy Swagger testing
    audio_base64: str


class AssistantTextToSpeechRequest(BaseModel):
    # Raw user text that will go through the full assistant flow:
    # NLU -> DB -> formatter -> TTS
    text: str = Field(
        ...,
        min_length=1,
        description="User text input for the full assistant flow",
    )

    # Optional elder ID used to retrieve the correct elder-specific medication data.
    elder_id: Optional[int] = None


class AssistantTextToSpeechResponse(BaseModel):
    # Original cleaned input text received by the endpoint
    input_text: str

    # Intent extracted by the NLU layer
    nlu_intent: str

    # Final response mode chosen for spoken output
    # usage = medication use/purpose
    # food_guide = food-related instruction
    response_mode: Optional[Literal["usage", "food_guide"]] = None
 
    # Raw DB retrieval result returned from the integration layer
    db_response: Optional[DbRetrievalResponse] = None 

    # Final Arabic text prepared for speech synthesis
    spoken_text: str

    # Output audio format configured in application settings
    audio_format: str

    # Base64-encoded synthesized audio content
    audio_base64: str