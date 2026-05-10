import base64

from fastapi import APIRouter

from app.core.config import settings
from app.services.openai_tts import synthesize_speech
from app.tts.tts_text_formatter import format_tts_text
from app.tts_schemas import TtsTestRequest, TtsTestResponse

router = APIRouter(prefix="/tts", tags=["TTS"])


@router.post("/test", response_model=TtsTestResponse)
def test_tts(req: TtsTestRequest) -> TtsTestResponse:
    """
    Test-only endpoint for OpenAI TTS.

    Flow:
    1. Receive plain text
    2. Convert it to audio bytes
    3. Encode audio as base64
    4. Return JSON suitable for Swagger testing
    """
    clean_text = req.text.strip()
    formatted_text = format_tts_text(clean_text)

    audio_bytes = synthesize_speech(clean_text)
    audio_base64 = base64.b64encode(audio_bytes).decode("utf-8")

    return TtsTestResponse(
        text=clean_text,
        formatted_text=formatted_text,
        audio_format=settings.OPENAI_TTS_FORMAT,
        audio_base64=audio_base64,
    )   