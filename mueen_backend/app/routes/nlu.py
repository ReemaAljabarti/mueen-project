
from __future__ import annotations

from fastapi import APIRouter

from app.nlu.schemas import NluParseRequest, NluParseResponse
from app.nlu.service import parse_text

router = APIRouter(prefix="/nlu", tags=["NLU"])


@router.post(
    "/parse",
    response_model=NluParseResponse,
    summary="Parse text into intent and slots",
    description="NLU parsing endpoint used by Flutter after STT transcription.",
)
def nlu_parse(req: NluParseRequest) -> NluParseResponse:
    return parse_text(req)