from pydantic import BaseModel

class SttSuccessResponse(BaseModel):
    request_id: str
    text: str
    language: str
    duration_ms: int 