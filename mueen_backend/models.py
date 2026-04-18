from pydantic import BaseModel
from typing import List, Optional

class Elder(BaseModel):
    caregiver_id: int
    full_name: str
    phone_number: str
    gender: str
    password: str
    age: Optional[str] = None
    weight: Optional[str] = None
    health_conditions: List[str] = []

class Caregiver(BaseModel):
    full_name: str
    phone_number: str
    email: str
    password: str

class CaregiverLogin(BaseModel):
    email: str | None = None
    phone_number: str | None = None
    password: str

class ElderLogin(BaseModel):
    phone_number: str
    password: str