# app/core/error_handlers.py

import logging
from fastapi import Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError

from .errors import ApiError

logger = logging.getLogger("api")


def api_error_handler(_: Request, exc: ApiError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": {
                "code": exc.code,
                "message": exc.message,
                "details": exc.details or {},
            }
        },
    )


def validation_error_handler(_: Request, exc: RequestValidationError) -> JSONResponse:
    return JSONResponse(
        status_code=422,
        content={
            "error": {
                "code": "VALIDATION_ERROR",
                "message": "Request validation failed.",
                "details": {"errors": exc.errors()},
            }
        },
    )


def unhandled_exception_handler(_: Request, __: Exception) -> JSONResponse:
    logger.exception("UNHANDLED_EXCEPTION")
    return JSONResponse(
        status_code=500,
        content={
            "error": {
                "code": "INTERNAL_ERROR",
                "message": "حدث خطأ غير متوقع.",
                "details": {},
            }
        },
    )