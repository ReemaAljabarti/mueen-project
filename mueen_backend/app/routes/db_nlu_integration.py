
from app.services.dialogue_state_service import dialogue_state_service

from fastapi import APIRouter
from app.nlu.schemas import NluParseRequest, NluParseResponse
from app.nlu.service import parse_text
from app.db_schemas import (
    DbNluParseRequest,
    DbRetrievalResponse,
    DbNluSpokenResponse,
)
from app.services.assistant_response_formatter import AssistantResponseFormatter
from app.services.db_nlu_integration_service import (
    infer_response_mode,
    retrieve_from_nlu_output,
)
  
router = APIRouter(prefix="/db-nlu", tags=["DB + NLU Integration"])

   
# Formatter instance used to build spoken_text.
formatter = AssistantResponseFormatter()


# Build the original NLU request from the DB + NLU request.
# This keeps the NLU layer unchanged while allowing this route to accept elder_id.
def _build_nlu_request(req: DbNluParseRequest) -> NluParseRequest:
    return NluParseRequest(text=req.text)


# Add elder_id to slots when it is provided by the client.
# Schedule queries use this value to retrieve data for the correct elder.
def _inject_elder_id_into_slots(
    slots: dict,
    elder_id: int | None,
) -> dict:
    updated_slots = dict(slots or {})

    if elder_id is not None:
        updated_slots["ELDER_ID"] = elder_id

    return updated_slots


# Extract elder_id from the request with the same safe fallback used in the demo flow.
def _get_elder_id_from_request(req: DbNluParseRequest) -> int:
    if req.elder_id is not None:
        return req.elder_id

    return 1


# Existing endpoint:
# text -> NLU -> DB response.
# Kept for backward compatibility with the older DB retrieval flow.
@router.post(
    "/parse-and-search",
    response_model=DbRetrievalResponse,
    summary="Parse user text and retrieve medication data",
)
def parse_and_search(req: DbNluParseRequest) -> DbRetrievalResponse:
    nlu_request = _build_nlu_request(req)

    # Parse the raw text with NLU.
    nlu_result: NluParseResponse = parse_text(nlu_request)

    # Add real elder_id to NLU slots if the request includes it.
    slots = _inject_elder_id_into_slots(
        slots=nlu_result.slots,
        elder_id=req.elder_id,
    )

    # Run DB retrieval based on the NLU output.
    db_response = retrieve_from_nlu_output(
        intent=nlu_result.intent,
        slots=slots,
        normalized_text=nlu_result.normalized_text,
    )

    return db_response


# Main endpoint:
# text -> NLU -> DB response -> spoken_text.
@router.post(
    "/parse-search-and-format",
    response_model=DbNluSpokenResponse,
    summary="Parse user text, retrieve medication data, and build spoken text",
)
def parse_search_and_format(req: DbNluParseRequest) -> DbNluSpokenResponse:
    nlu_request = _build_nlu_request(req)

    # Parse the raw text with NLU.
    nlu_result: NluParseResponse = parse_text(nlu_request)

    # Add real elder_id to NLU slots if the request includes it.
    slots = _inject_elder_id_into_slots(
        slots=nlu_result.slots,
        elder_id=req.elder_id,
    )

    # Decide whether the response should use usage or food-guide text.
    response_mode = infer_response_mode(
        slots=slots,
        normalized_text=nlu_result.normalized_text,
    )

    # Run DB retrieval based on the NLU output.
    db_response = retrieve_from_nlu_output(
        intent=nlu_result.intent,
        slots=slots,
        normalized_text=nlu_result.normalized_text,
    )

    # Build the final spoken response text.
    spoken_text = formatter.build_spoken_response(
        db_response=db_response,
        response_mode=response_mode,
    )

    # Save the last spoken response so Repeat intent can return it later.
    elder_id = _get_elder_id_from_request(req)
    dialogue_state_service.save_last_response(
        elder_id=elder_id,
        response_text=spoken_text,
    )

    return DbNluSpokenResponse(
        nlu_intent=nlu_result.intent,
        response_mode=response_mode,
        db_response=db_response,
        spoken_text=spoken_text,
    )