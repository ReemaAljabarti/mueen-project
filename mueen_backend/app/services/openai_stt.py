# Used to work with file paths (like opening the audio file)
from pathlib import Path

# Import the shared OpenAI client (used to send requests to OpenAI)
from app.core.openai_client import openai_client as client

# Used to log warnings and errors (for debugging and monitoring)
import logging

# Import specific OpenAI errors to handle each case properly
from openai import (
    AuthenticationError,     # Invalid or missing API key
    RateLimitError,          # Too many requests (rate limit exceeded)
    NotFoundError,           # Model or resource not found
    PermissionDeniedError,   # No permission to use model or API
    BadRequestError,         # Invalid request (wrong input or format)
    APITimeoutError,         # Request took too long (timeout)
    APIConnectionError,      # Network or connection problem
    InternalServerError,     # Error from OpenAI server
)

# Import system settings (API key, model name, timeout, etc.)
from app.core.config import settings

# Import custom API error class (used to return clean error responses)
from app.core.errors import ApiError

 
logger = logging.getLogger("stt.openai")


def transcribe_file(file_path: Path) -> str:
    """
    Transcribe an audio file using OpenAI STT and return text.
    """
    model_name = settings.OPENAI_STT_MODEL

    try:
        with file_path.open("rb") as f:
            result = client.audio.transcriptions.create(
                model=model_name,
                file=f,
                language="ar"

            )

        # استخراج النص بطريقة متوافقة مع أكثر من شكل استجابة
        text = getattr(result, "text", None)
        if not text and isinstance(result, dict):
            text = result.get("text")

        # Empty transcription (مطلوب في Task 5)
        if not text or not str(text).strip():
            raise ApiError(
                status_code=502,
                code="STT_EMPTY_RESPONSE",
                message="STT service returned empty transcription.",
                details={"model": model_name},
            )

        return str(text).strip()

    except ApiError:
        raise

    # Error Mapping مفصل
    except AuthenticationError as e:
        logger.warning("OpenAI auth error: %s", str(e)[:200])
        raise ApiError(
            status_code=401,
            code="STT_AUTH_ERROR",
            message="OpenAI authentication failed.",
            details={"model": model_name},
        )

    except PermissionDeniedError as e:
        logger.warning("OpenAI permission denied: %s", str(e)[:200])
        raise ApiError(
            status_code=403,
            code="STT_PERMISSION_DENIED",
            message="Permission denied for STT provider/model.",
            details={"model": model_name},
        )

    except NotFoundError as e:
        logger.warning("OpenAI model not found: %s", str(e)[:200])
        raise ApiError(
            status_code=404,
            code="STT_MODEL_NOT_FOUND",
            message="STT model not found.",
            details={"model": model_name},
        )

    except RateLimitError as e:
        logger.warning("OpenAI rate limit: %s", str(e)[:200])
        raise ApiError(
            status_code=429,
            code="STT_RATE_LIMIT",
            message="STT provider rate limit exceeded.",
            details={"model": model_name},
        )

    except BadRequestError as e:
        logger.warning("OpenAI bad request: %s", str(e)[:200])
        raise ApiError(
            status_code=400,
            code="STT_BAD_REQUEST",
            message="Invalid request sent to STT provider.",
            details={"model": model_name},
        )

    except APITimeoutError as e:
        logger.warning("OpenAI timeout: %s", str(e)[:200])
        raise ApiError(
            status_code=502,
            code="STT_PROVIDER_TIMEOUT",
            message="STT provider timeout.",
            details={"model": model_name},
        )

    except APIConnectionError as e:
        logger.warning("OpenAI connection error: %s", str(e)[:200])
        raise ApiError(
            status_code=502,
            code="STT_PROVIDER_CONNECTION_ERROR",
            message="STT provider connection error.",
            details={"model": model_name},
        )

    except InternalServerError as e:
        logger.warning("OpenAI internal error: %s", str(e)[:200])
        raise ApiError(
            status_code=502,
            code="STT_PROVIDER_INTERNAL_ERROR",
            message="STT provider internal error.",
            details={"model": model_name},
        )

    # Fallback
    except Exception:
        logger.exception("OpenAI STT call failed (unmapped)")
        raise ApiError(
            status_code=502,
            code="STT_PROVIDER_ERROR",
            message="Speech-to-text service failed.",
	    details={"model": model_name},
        )



