import uuid
import logging
from pathlib import Path

from fastapi import APIRouter, UploadFile, File

from app.core.config import settings
from app.core.errors import ApiError
from app.services.openai_stt import transcribe_file

logger = logging.getLogger("stt")

router = APIRouter(prefix="/stt", tags=["stt"])

TMP_DIR = Path("tmp_uploads")
TMP_DIR.mkdir(parents=True, exist_ok=True)


def _get_extension(filename: str | None) -> str:
    if not filename or "." not in filename:
        return ""
    return filename.rsplit(".", 1)[-1].lower().strip()


@router.post("/transcribe")
async def transcribe(file: UploadFile = File(...)):

    ext = _get_extension(file.filename)

    # 1) Check the extension
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

    # 2) Read the file
    data = await file.read()
    size = len(data)

    # 3) Check the size
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

    # 4) Save temporary 
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

    # 5) STT 
    try:
        text = transcribe_file(temp_path)
    finally:
        # Clean the temp file
        try:
            if temp_path.exists():
                temp_path.unlink()
        except Exception:
            pass

    return {
        "mode": "openai",
        "filename": file.filename,
        "bytes": size,
        "model": settings.OPENAI_STT_MODEL,
        "text": text,
    }