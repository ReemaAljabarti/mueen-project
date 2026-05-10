from app.core.openai_client import openai_client as client
import logging

from openai import (
    AuthenticationError,
    RateLimitError,
    NotFoundError,
    PermissionDeniedError,
    BadRequestError,
    APITimeoutError,
    APIConnectionError,
    InternalServerError,
)

from app.core.config import settings
from app.core.errors import ApiError
from app.tts.tts_text_formatter import format_tts_text

# Dedicated logger for the OpenAI TTS layer
logger = logging.getLogger("tts.openai")


def synthesize_speech(text: str) -> bytes:
    """
    Convert assistant text into audio bytes using OpenAI TTS.

    Flow:
    1. Validate raw input text
    2. Convert it into a TTS-friendly spoken version
    3. Send the formatted text to OpenAI TTS
    4. Return audio bytes
    """
    # Read TTS settings from application config
    model_name = settings.OPENAI_TTS_MODEL
    voice_name = settings.OPENAI_TTS_VOICE
    audio_format = settings.OPENAI_TTS_FORMAT

    # Guard clause:
    # reject empty or whitespace-only input before sending a provider request
    if not text or not str(text).strip():
        raise ApiError(
            status_code=400,
            code="TTS_EMPTY_INPUT",
            message="TTS input text is empty.",
            details={},
        )

    # Minimal raw input cleanup before formatting
    raw_text = str(text).strip()

    # Convert backend text into a spoken-text version
    formatted_text = format_tts_text(raw_text)

    try:
        # Call OpenAI Text-to-Speech using the formatted spoken text
        result = client.audio.speech.create(
            model=model_name,
            voice=voice_name,
            input=formatted_text,
            response_format=audio_format,
        )

        # First, try to read audio data directly from "content"
        audio_bytes = getattr(result, "content", None)

        # Some SDK responses may expose a read() method instead
        if not audio_bytes and hasattr(result, "read"):
            audio_bytes = result.read()

        # If no audio data was returned, treat it as a provider failure
        if not audio_bytes:
            raise ApiError(
                status_code=502,
                code="TTS_EMPTY_RESPONSE",
                message="TTS service returned empty audio.",
                details={
                    "model": model_name,
                    "voice": voice_name,
                    "format": audio_format,
                },
            )

        return audio_bytes

    # Re-raise already normalized API errors
    except ApiError:
        raise

    # Authentication failures
    except AuthenticationError as e:
        logger.warning("OpenAI TTS auth error: %s", str(e)[:200])
        raise ApiError(
            status_code=401,
            code="TTS_AUTH_ERROR",
            message="OpenAI authentication failed.",
            details={"model": model_name, "voice": voice_name},
        )

    # Permission-related failures
    except PermissionDeniedError as e:
        logger.warning("OpenAI TTS permission denied: %s", str(e)[:200])
        raise ApiError(
            status_code=403,
            code="TTS_PERMISSION_DENIED",
            message="Permission denied for TTS provider/model.",
            details={"model": model_name, "voice": voice_name},
        )

    # Model not found or unavailable
    except NotFoundError as e:
        logger.warning("OpenAI TTS model not found: %s", str(e)[:200])
        raise ApiError(
            status_code=404,
            code="TTS_MODEL_NOT_FOUND",
            message="TTS model not found.",
            details={"model": model_name, "voice": voice_name},
        )

    # Rate limit exceeded
    except RateLimitError as e:
        logger.warning("OpenAI TTS rate limit: %s", str(e)[:200])
        raise ApiError(
            status_code=429,
            code="TTS_RATE_LIMIT",
            message="TTS provider rate limit exceeded.",
            details={"model": model_name, "voice": voice_name},
        )

    # Invalid request payload or unsupported parameter values
    except BadRequestError as e:
        logger.warning("OpenAI TTS bad request: %s", str(e)[:200])
        raise ApiError(
            status_code=400,
            code="TTS_BAD_REQUEST",
            message="Invalid request sent to TTS provider.",
            details={"model": model_name, "voice": voice_name},
        )

    # Provider timeout
    except APITimeoutError as e:
        logger.warning("OpenAI TTS timeout: %s", str(e)[:200])
        raise ApiError(
            status_code=502,
            code="TTS_PROVIDER_TIMEOUT",
            message="TTS provider timeout.",
            details={"model": model_name, "voice": voice_name},
        )

    # Connection or network failure between backend and provider
    except APIConnectionError as e:
        logger.warning("OpenAI TTS connection error: %s", str(e)[:200])
        raise ApiError(
            status_code=502,
            code="TTS_PROVIDER_CONNECTION_ERROR",
            message="TTS provider connection error.",
            details={"model": model_name, "voice": voice_name},
        )

    # Internal provider-side failure
    except InternalServerError as e:
        logger.warning("OpenAI TTS internal error: %s", str(e)[:200])
        raise ApiError(
            status_code=502,
            code="TTS_PROVIDER_INTERNAL_ERROR",
            message="TTS provider internal error.",
            details={"model": model_name, "voice": voice_name},
        )

    # Catch-all fallback for any unmapped exception
    except Exception:
        logger.exception("OpenAI TTS call failed (unmapped)")
        raise ApiError(
            status_code=502,
            code="TTS_PROVIDER_ERROR",
            message="Text-to-speech service failed.",
            details={"model": model_name, "voice": voice_name},
        ) 