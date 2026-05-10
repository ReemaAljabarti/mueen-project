import base64
import logging
import uuid
from pathlib import Path

from fastapi import APIRouter, UploadFile, File, Form

from app.core.config import settings
from app.core.errors import ApiError
from app.nlu.schemas import NluParseRequest
from app.nlu.service import parse_text
from app.services.assistant_response_formatter import AssistantResponseFormatter
from app.services.db_nlu_integration_service import (
    infer_response_mode,
    retrieve_from_nlu_output,
)
from app.services.dialogue_state_service import dialogue_state_service
from app.services.openai_stt import transcribe_file
from app.services.openai_tts import synthesize_speech
from app.tts_schemas import (
    AssistantTextToSpeechRequest,
    AssistantTextToSpeechResponse,
)

logger = logging.getLogger("assistant")

router = APIRouter(prefix="/assistant", tags=["Assistant"])

formatter = AssistantResponseFormatter()

TMP_DIR = Path("tmp_uploads")
TMP_DIR.mkdir(parents=True, exist_ok=True)


def _get_extension(filename: str | None) -> str:
    if not filename or "." not in filename:
        return ""

    return filename.rsplit(".", 1)[-1].lower().strip()


def _inject_elder_id_into_slots(
    slots: dict,
    elder_id: int | None,
) -> dict:
    updated_slots = dict(slots or {})

    if elder_id is not None:
        updated_slots["ELDER_ID"] = elder_id

    return updated_slots


def _get_elder_id_from_request(req: AssistantTextToSpeechRequest) -> int:
    elder_id = getattr(req, "elder_id", None)

    if elder_id is not None:
        return elder_id

    return 1


def _build_assistant_response_from_text(
    clean_text: str,
    elder_id: int,
) -> AssistantTextToSpeechResponse:
    if not clean_text:
        spoken_text = "ما وصلني طلب واضح."

        audio_bytes = synthesize_speech(spoken_text)
        audio_base64 = base64.b64encode(audio_bytes).decode("utf-8")

        return AssistantTextToSpeechResponse(
            input_text=clean_text,
            nlu_intent="Unknown",
            response_mode=None,
            db_response=None,
            spoken_text=spoken_text,
            audio_format=settings.OPENAI_TTS_FORMAT,
            audio_base64=audio_base64,
        )

    nlu_request = NluParseRequest(text=clean_text)
    nlu_result = parse_text(nlu_request)

    slots = _inject_elder_id_into_slots(
        slots=nlu_result.slots,
        elder_id=elder_id,
    )

    response_mode = infer_response_mode(
        slots,
        normalized_text=nlu_result.normalized_text,
    )

    db_response = retrieve_from_nlu_output(
        nlu_result.intent,
        slots,
        normalized_text=nlu_result.normalized_text,
    )

    spoken_text = formatter.build_spoken_response(
        db_response=db_response,
        response_mode=response_mode,
    )

    dialogue_state_service.save_last_response(
        elder_id=elder_id,
        response_text=spoken_text,
    )

    audio_bytes = synthesize_speech(spoken_text)
    audio_base64 = base64.b64encode(audio_bytes).decode("utf-8")

    return AssistantTextToSpeechResponse(
        input_text=clean_text,
        nlu_intent=nlu_result.intent,
        response_mode=response_mode,
        db_response=db_response,
        spoken_text=spoken_text,
        audio_format=settings.OPENAI_TTS_FORMAT,
        audio_base64=audio_base64,
    )


@router.post("/respond-text", response_model=AssistantTextToSpeechResponse)
def respond_with_text_and_tts(
    req: AssistantTextToSpeechRequest,
) -> AssistantTextToSpeechResponse:
    clean_text = req.text.strip()
    elder_id = _get_elder_id_from_request(req)

    return _build_assistant_response_from_text(
        clean_text=clean_text,
        elder_id=elder_id,
    )


@router.post("/respond-audio", response_model=AssistantTextToSpeechResponse)
async def respond_with_audio_and_tts(
    elder_id: int = Form(...),
    file: UploadFile = File(...),
) -> AssistantTextToSpeechResponse:
    ext = _get_extension(file.filename)

    if ext == "":
        raise ApiError(
            status_code=400,
            code="MISSING_FILE_EXTENSION",
            message="File must have an extension.",
            details={"filename": file.filename},
        )

    if ext not in settings.ALLOWED_EXTENSIONS:
        raise ApiError(
            status_code=415,
            code="UNSUPPORTED_FILE_TYPE",
            message="Only wav, mp3, m4a are supported.",
            details={"received_extension": ext},
        )

    data = await file.read()
    size = len(data)

    if size < settings.MIN_UPLOAD_BYTES:
        raise ApiError(
            status_code=400,
            code="FILE_TOO_SMALL",
            message="Uploaded file is too small.",
            details={"bytes": size},
        )

    if size > settings.MAX_UPLOAD_BYTES:
        raise ApiError(
            status_code=413,
            code="FILE_TOO_LARGE",
            message="File exceeds maximum allowed size.",
            details={"bytes": size},
        )

    temp_name = f"{uuid.uuid4().hex}.{ext}"
    temp_path = TMP_DIR / temp_name

    try:
        temp_path.write_bytes(data)
    except Exception:
        logger.exception("TEMP_SAVE_FAILED: could not write temp file")
        raise ApiError(
            status_code=500,
            code="TEMP_SAVE_FAILED",
            message="Temporary file save failed.",
            details={"stage": "temp_save"},
        )

    try:
        transcribed_text = transcribe_file(temp_path)
        clean_text = transcribed_text.strip()

        return _build_assistant_response_from_text(
            clean_text=clean_text,
            elder_id=elder_id,
        )

    finally:
        try:
            if temp_path.exists():
                temp_path.unlink()
        except Exception:
            pass