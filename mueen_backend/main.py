from fastapi import FastAPI
from models import (
    Elder,
    Caregiver,
    CaregiverLogin,
    ElderLogin,
    ElderMedicationCreate,
    ElderMedicationUpdate,
    InteractionCheckRequest,
)
from database import (
    init_db,
    get_caregiver_by_email_or_phone,
    insert_caregiver,
    get_caregiver_by_login,
    insert_elder,
    get_elder_by_login,
    get_all_caregivers,
    get_elders_by_caregiver_id,
    search_medications,
    insert_elder_medication,
    get_elder_medications,
    delete_elder_medication,
    update_elder_medication,
    get_medication_by_gtin,
    get_drug_interaction_with_existing_medications,
    get_elder_current_interactions,
)
import json

app = FastAPI()

init_db()


@app.get("/")
def root():
    return {"message": "Mu'een API is running"}


@app.post("/caregiver/signup")
def caregiver_signup(caregiver: Caregiver):
    existing = get_caregiver_by_email_or_phone(
        caregiver.email,
        caregiver.phone_number,
    )

    if existing:
        return {
            "success": False,
            "message": "Caregiver account already exists"
        }

    insert_caregiver(
        caregiver.full_name,
        caregiver.phone_number,
        caregiver.email,
        caregiver.password,
    )

    return {
        "success": True,
        "message": "Caregiver account created successfully",
        "data": caregiver
    }


@app.post("/caregiver/login")
def caregiver_login(data: CaregiverLogin):
    email = data.email
    phone_number = data.phone_number
    password = data.password

    caregiver = get_caregiver_by_login(email, phone_number)

    if caregiver and caregiver["password"] == password:
        return {
            "success": True,
            "message": "Login successful",
            "data": dict(caregiver)
        }

    return {
        "success": False,
        "message": "Invalid credentials or account does not exist"
    }


@app.post("/elders")
def add_elder(elder: Elder):
    insert_elder(
        elder.caregiver_id,
        elder.full_name,
        elder.phone_number,
        elder.gender,
        elder.password,
        elder.age,
        elder.weight,
        elder.health_conditions,
    )

    return {
        "message": "Elder added successfully",
        "data": elder
    }


@app.get("/elders/{caregiver_id}")
def get_elders(caregiver_id: int):
    elders = get_elders_by_caregiver_id(caregiver_id)

    result = []
    for elder in elders:
        result.append({
            "id": elder["id"],
            "caregiver_id": elder["caregiver_id"],
            "full_name": elder["full_name"],
            "phone_number": elder["phone_number"],
            "gender": elder["gender"],
            "password": elder["password"],
            "age": elder["age"],
            "weight": elder["weight"],
            "health_conditions": json.loads(elder["health_conditions"]) if elder["health_conditions"] else []
        })

    return result


@app.post("/elder/login")
def elder_login(data: ElderLogin):
    phone_number = data.phone_number
    password = data.password

    elder = get_elder_by_login(phone_number)

    if elder and elder["password"] == password:
        return {
            "success": True,
            "message": "Elder login successful",
            "data": dict(elder)
        }

    return {
        "success": False,
        "message": "Invalid phone number or password"
    }


@app.get("/caregivers")
def get_caregivers():
    caregivers = get_all_caregivers()

    result = []
    for caregiver in caregivers:
        result.append({
            "id": caregiver["id"],
            "full_name": caregiver["full_name"],
            "phone_number": caregiver["phone_number"],
            "email": caregiver["email"],
            "password": caregiver["password"],
        })

    return result


@app.get("/medications/search")
def search_medications_api(query: str):
    results = search_medications(query)

    response = []
    for med in results:
        response.append({
            "id": med["id"],
            "drug_id": med["drug_id"],
            "brand_name_ar": med["brand_name_ar"],
            "generic_name_en": med["generic_name_en"],
            "dosage_strength": med["dosage_strength"],
            "dosage_form": med["dosage_form"],
            "route_ar": med["route_ar"],
            "uses_ar": med["uses_ar"],
            "food_guide_ar": med["food_guide_ar"],
        })

    return response


@app.post("/elder-medications")
def create_elder_medication(data: ElderMedicationCreate):
    insert_elder_medication(
        data.elder_id,
        data.catalog_medication_id,
        data.display_name_for_elder,
        data.dosage_amount,
        data.dosage_unit,
        data.usage_instruction,
        data.short_description,
        data.treatment_duration_type,
        data.start_date,
        data.end_date,
        data.times_per_day,
        data.first_reminder_time,
        data.days_pattern,
        
    )

    return {
        "success": True,
        "message": "Elder medication saved successfully",
        "data": data,
    }

@app.get("/elder-medications/{elder_id}")
def get_elder_medications_api(elder_id: int):
    meds = get_elder_medications(elder_id)

    response = []
    for med in meds:
        response.append({
            "id": med["id"],
            "elder_id": med["elder_id"],
            "catalog_medication_id": med["catalog_medication_id"],
            "display_name_for_elder": med["display_name_for_elder"],
            "dosage_amount": med["dosage_amount"],
            "dosage_unit": med["dosage_unit"],
            "usage_instruction": med["usage_instruction"],
            "short_description": med["short_description"],
            "times_per_day": med["times_per_day"],
            "first_reminder_time": med["first_reminder_time"],
            "days_pattern": med["days_pattern"],
            "brand_name_ar": med["brand_name_ar"],
            "dosage_form": med["dosage_form"],
            "dosage_strength": med["dosage_strength"],
            "route_ar": med["route_ar"],
            "food_guide_ar": med["food_guide_ar"],
            "gtin": med["gtin"],

        })

    return response

@app.delete("/elder-medications/{elder_medication_id}")
def delete_elder_medication_api(elder_medication_id: int):
    deleted_count = delete_elder_medication(elder_medication_id)

    if deleted_count == 0:
        return {
            "success": False,
            "message": "Medication not found"
        }

    return {
        "success": True,
        "message": "Elder medication deleted successfully"
    }

@app.put("/elder-medications/{elder_medication_id}")
def update_elder_medication_api(
    elder_medication_id: int,
    data: ElderMedicationUpdate,
):
    updated_count = update_elder_medication(
        elder_medication_id,
        data.display_name_for_elder,
        data.dosage_amount,
        data.dosage_unit,
        data.first_reminder_time,
    )

    if updated_count == 0:
        return {
            "success": False,
            "message": "Medication not found"
        }

    return {
        "success": True,
        "message": "Elder medication updated successfully"
    }

@app.get("/medications/by-gtin/{gtin}")
def medication_by_gtin_api(gtin: str):

    print("RAW GTIN:", gtin)

    medication = get_medication_by_gtin(gtin)

    print("AFTER LOOKUP:", medication)

    if medication is None:
        return {
            "found": False,
            "message": "Medication not found"
        }

    return {
        "found": True,
        "medication": {
            "id": medication[0],
            "drug_id": medication[1],
            "brand_name_ar": medication[2],
            "generic_name_en": medication[3],
            "dosage_strength": medication[4],
            "dosage_form": medication[5],
            "route_ar": medication[6],
            "gtin": medication[7],
            "uses_ar": medication[8],
            "food_guide_ar": medication[9],
        }
    }

@app.post("/drug-interactions/check")
def check_drug_interaction_api(data: InteractionCheckRequest):
    result = get_drug_interaction_with_existing_medications(
        elder_id=data.elder_id,
        new_catalog_medication_id=data.catalog_medication_id,
    )

    if result is None:
        return {
            "has_interaction": False,
            "severity": None,
            "note_ar": None,
            "new_medication_name": None,
            "existing_medication_name": None,
        }

    return {
        "has_interaction": True,
        "severity": result["severity"],
        "note_ar": result["note_ar"],
        "new_medication_name": result["new_brand_name"],
        "existing_medication_name": result["existing_brand_name"],
    }

@app.get("/elders/{elder_id}/drug-interactions")
def get_elder_drug_interactions_api(elder_id: int):
    interactions = get_elder_current_interactions(elder_id)

    return {
        "has_interactions": len(interactions) > 0,
        "count": len(interactions),
        "interactions": interactions,
    }