from fastapi import APIRouter, Query

from app.db_schemas import DbRetrievalResponse
from app.services.db_medication_service import (
    retrieve_medication_by_name,
    retrieve_medications_by_category,
)

# Router for DB-related medication endpoints
router = APIRouter(prefix="/db/medications", tags=["DB Medications"])


# Endpoint: Search medication by name (Arabic or English)
@router.get("/by-name", response_model=DbRetrievalResponse)
def get_medication_by_name_endpoint(
    name: str = Query(..., min_length=1, description="Medication name")
) -> DbRetrievalResponse:

    # Trim input to avoid issues with extra spaces
    return retrieve_medication_by_name(name=name.strip())


# Endpoint: Search medications by category (e.g. سكري، قلب وضغط)
@router.get("/by-category", response_model=DbRetrievalResponse)
def get_medications_by_category_endpoint(
    category: str = Query(..., min_length=1, description="Medication category")
) -> DbRetrievalResponse:

    # Clean input and forward to service layer
    return retrieve_medications_by_category(category=category.strip())