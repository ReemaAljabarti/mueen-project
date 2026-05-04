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


class ElderMedicationCreate(BaseModel):
    elder_id: int
    catalog_medication_id: int
    display_name_for_elder: Optional[str] = None
    dosage_amount: int
    dosage_unit: str
    usage_instruction: Optional[str] = None
    short_description: Optional[str] = None
    treatment_duration_type: Optional[str] = None
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    times_per_day: int
    first_reminder_time: str
    days_pattern: str

class ElderMedicationUpdate(BaseModel):
    display_name_for_elder: Optional[str] = None
    dosage_amount: int
    dosage_unit: str
    first_reminder_time: str

class InteractionCheckRequest(BaseModel):
    elder_id: int
    catalog_medication_id: int


# ─── Dose Reminder & Adherence Models ───────────────────────────────────────

class DoseCreateRequest(BaseModel):
    elder_medication_id: int
    elder_id: int
    scheduled_time: str          # HH:MM
    dose_date: str               # YYYY-MM-DD


class AdherenceTakenRequest(BaseModel):
    dose_id: int
    elder_id: int
    elder_medication_id: int


class AdherenceMissedRequest(BaseModel):
    dose_id: int
    elder_id: int
    elder_medication_id: int
    note: Optional[str] = None


class SnoozeRequest(BaseModel):
    dose_id: int
    elder_id: int
    elder_medication_id: int
    snooze_minutes: int          # allowed: 15, 20, 30


class NoResponseRequest(BaseModel):
    dose_id: int
    elder_id: int
    elder_medication_id: int