from fastapi import FastAPI
from models import (
    Elder,
    Caregiver,
    CaregiverLogin,
    ElderLogin,
    ElderMedicationCreate,
    ElderMedicationUpdate,
    InteractionCheckRequest,
    DoseCreateRequest,
    AdherenceTakenRequest,
    AdherenceMissedRequest,
    SnoozeRequest,
    NoResponseRequest,
    
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
    # Dose Reminder & Adherence
    get_due_doses_for_elder,
    create_dose_for_elder,
    mark_dose_taken,
    mark_dose_missed,
    snooze_dose,
    insert_adherence_log,
    create_caregiver_alert,
    get_elder_caregiver_id,
    get_missed_doses_for_caregiver,
    get_weekly_adherence_summary,
    generate_today_doses,
    get_today_doses_for_elder,
    get_next_dose_for_elder,
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
        generation_result = None

        try:
            generation_result = generate_today_doses(elder["id"])
        except Exception as e:
            print("[elder_login] generate_today_doses failed:", e)

        return {
            "success": True,
            "message": "Elder login successful",
            "data": dict(elder),
            "generated_doses": generation_result,
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

    generation_result = None

    try:
        generation_result = generate_today_doses(data.elder_id)
    except Exception as e:
        print("[create_elder_medication] generate_today_doses failed:", e)

    return {
        "success": True,
        "message": "Elder medication saved successfully",
        "data": data,
        "generated_doses": generation_result,
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
            "med_category": med["med_category"],
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

# ═══════════════════════════════════════════════════════════════════════
# Dose Reminder & Adherence Endpoints
# ═══════════════════════════════════════════════════════════════════════
@app.post("/reminders/generate-today/{elder_id}")
def generate_today_doses_api(elder_id: int):
    result = generate_today_doses(elder_id)

    return {
        "success": True,
        "message": "Today's doses generated successfully",
        **result,
    }


@app.get("/reminders/today/{elder_id}")
def get_today_doses_api(elder_id: int):
    rows = get_today_doses_for_elder(elder_id)

    result = []
    for d in rows:
        med_name = d["display_name_for_elder"] or d["brand_name_ar"]

        result.append({
            "dose_id": d["id"],
            "elder_medication_id": d["elder_medication_id"],
            "elder_id": d["elder_id"],
            "scheduled_time": d["scheduled_time"],
            "dose_date": d["dose_date"],
            "status": d["status"],
            "snooze_count": d["snooze_count"],
            "snoozed_until": d["snoozed_until"],
            "taken_at": d["taken_at"],
            "missed_at": d["missed_at"],
            "last_updated_at": d["last_updated_at"],
            "medication_name": med_name,
            "brand_name_ar": d["brand_name_ar"],
            "generic_name_en": d["generic_name_en"],
            "med_category": d["med_category"],
            "dosage_amount": d["dosage_amount"],
            "dosage_unit": d["dosage_unit"],
            "dosage_form": d["dosage_form"],
            "dosage_strength": d["dosage_strength"],
            "route_ar": d["route_ar"],
            "food_guide_ar": d["food_guide_ar"],
            "usage_instruction": d["usage_instruction"],
            "gtin": d["gtin"],
        })

    return {
        "elder_id": elder_id,
        "count": len(result),
        "today_doses": result,
    }


@app.get("/reminders/next-dose/{elder_id}")
def get_next_dose_api(elder_id: int):
    d = get_next_dose_for_elder(elder_id)

    if d is None:
        return {
            "found": False,
            "message": "No upcoming dose found for today",
            "next_dose": None,
        }

    med_name = d["display_name_for_elder"] or d["brand_name_ar"]

    return {
        "found": True,
        "next_dose": {
            "dose_id": d["id"],
            "elder_medication_id": d["elder_medication_id"],
            "elder_id": d["elder_id"],
            "scheduled_time": d["scheduled_time"],
            "dose_date": d["dose_date"],
            "status": d["status"],
            "snooze_count": d["snooze_count"],
            "snoozed_until": d["snoozed_until"],
            "medication_name": med_name,
            "brand_name_ar": d["brand_name_ar"],
            "generic_name_en": d["generic_name_en"],
            "med_category": d["med_category"],
            "dosage_amount": d["dosage_amount"],
            "dosage_unit": d["dosage_unit"],
            "dosage_form": d["dosage_form"],
            "dosage_strength": d["dosage_strength"],
            "route_ar": d["route_ar"],
            "food_guide_ar": d["food_guide_ar"],
            "usage_instruction": d["usage_instruction"],
            "gtin": d["gtin"],
        },
    }
@app.post("/reminders/create-dose")
def create_dose_api(data: DoseCreateRequest):
    """Create a pending dose record (called when elder opens the app or on schedule)."""
    dose_id = create_dose_for_elder(
        elder_medication_id=data.elder_medication_id,
        elder_id=data.elder_id,
        scheduled_time=data.scheduled_time,
        dose_date=data.dose_date,
    )
    return {"success": True, "dose_id": dose_id}


@app.get("/reminders/due-now/{elder_id}")
def get_due_doses_api(elder_id: int):
    """Return doses that are due now for the elder (pending or snoozed-and-expired)."""
    doses = get_due_doses_for_elder(elder_id)
    result = []
    for d in doses:
        med_name = d["display_name_for_elder"] or d["brand_name_ar"]
        result.append({
    "dose_id": d["id"],
    "elder_medication_id": d["elder_medication_id"],
    "elder_id": d["elder_id"],
    "scheduled_time": d["scheduled_time"],
    "dose_date": d["dose_date"],
    "status": d["status"],
    "snooze_count": d["snooze_count"],
    "snoozed_until": d["snoozed_until"],
    "medication_name": med_name,
    "display_name_for_elder": d["display_name_for_elder"],
    "brand_name_ar": d["brand_name_ar"],
    "generic_name_en": d["generic_name_en"],
    "med_category": d["med_category"],
    "dosage_amount": d["dosage_amount"],
    "dosage_unit": d["dosage_unit"],
    "dosage_form": d["dosage_form"],
    "dosage_strength": d["dosage_strength"],
    "route_ar": d["route_ar"],
    "usage_instruction": d["usage_instruction"],
    "food_guide_ar": d["food_guide_ar"],
    "uses_ar": d["uses_ar"],
    "gtin": d["gtin"],
})
    return {"due_doses": result, "count": len(result)}


@app.post("/adherence/taken")
def mark_taken_api(data: AdherenceTakenRequest):
    """Mark a dose as taken and log it."""
    mark_dose_taken(data.dose_id)
    insert_adherence_log(
        dose_id=data.dose_id,
        elder_id=data.elder_id,
        elder_medication_id=data.elder_medication_id,
        status="taken",
    )
    return {"success": True, "status": "taken"}


@app.post("/adherence/missed")
def mark_missed_api(data: AdherenceMissedRequest):
    """Mark a dose as missed, log it, and create a caregiver alert."""
    mark_dose_missed(data.dose_id)
    insert_adherence_log(
        dose_id=data.dose_id,
        elder_id=data.elder_id,
        elder_medication_id=data.elder_medication_id,
        status="missed",
        note=data.note,
    )
    caregiver_id = get_elder_caregiver_id(data.elder_id)
    if caregiver_id:
        create_caregiver_alert(
            caregiver_id=caregiver_id,
            elder_id=data.elder_id,
            dose_id=data.dose_id,
            alert_type="missed_dose",
            message=f"كبير السن لم يتناول الجرعة المقررة",
        )
    return {"success": True, "status": "missed"}


@app.post("/reminders/snooze")
def snooze_dose_api(data: SnoozeRequest):
    """
    Snooze a dose once (15, 20, or 30 minutes only).
    Second snooze attempt marks the dose as missed and alerts caregiver.
    """
    allowed_minutes = [15, 20, 30]
    if data.snooze_minutes not in allowed_minutes:
        return {
            "success": False,
            "error": f"snooze_minutes must be one of {allowed_minutes}",
        }

    result = snooze_dose(data.dose_id, data.snooze_minutes)

    if result["action"] == "snoozed":
        insert_adherence_log(
            dose_id=data.dose_id,
            elder_id=data.elder_id,
            elder_medication_id=data.elder_medication_id,
            status="snoozed",
            snooze_minutes=data.snooze_minutes,
        )
        return {"success": True, "action": "snoozed", "snoozed_until": result["snoozed_until"]}

    elif result["action"] == "missed":
        insert_adherence_log(
            dose_id=data.dose_id,
            elder_id=data.elder_id,
            elder_medication_id=data.elder_medication_id,
            status="missed",
            note="repeated_snooze_attempt",
        )
        caregiver_id = get_elder_caregiver_id(data.elder_id)
        if caregiver_id:
            create_caregiver_alert(
                caregiver_id=caregiver_id,
                elder_id=data.elder_id,
                dose_id=data.dose_id,
                alert_type="repeated_snooze",
                message="كبير السن حاول تأجيل الجرعة أكثر من مرة وتم تسجيلها كفائتة",
            )
        return {"success": True, "action": "missed", "reason": "repeated_snooze_attempt"}

    return {"success": False, "action": result.get("action", "unknown")}


@app.post("/adherence/no-response")
def no_response_api(data: NoResponseRequest):
    """
    Called when the dose timer expires with no action from the elder.
    Marks dose as no_response and alerts caregiver.
    """
    conn_helper = __import__("database")
    conn = conn_helper.get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "UPDATE medication_doses SET status = 'no_response' WHERE id = ? AND status IN ('pending', 'snoozed')",
        (data.dose_id,)
    )
    conn.commit()
    conn.close()

    insert_adherence_log(
        dose_id=data.dose_id,
        elder_id=data.elder_id,
        elder_medication_id=data.elder_medication_id,
        status="no_response",
        note="timer_expired",
    )
    caregiver_id = get_elder_caregiver_id(data.elder_id)
    if caregiver_id:
        create_caregiver_alert(
            caregiver_id=caregiver_id,
            elder_id=data.elder_id,
            dose_id=data.dose_id,
            alert_type="no_response",
            message="كبير السن لم يستجب لتنبيه الجرعة وانتهت مهلة الاستجابة",
        )
    return {"success": True, "status": "no_response"}


@app.get("/caregiver/missed-doses/{caregiver_id}")
def get_caregiver_missed_doses_api(caregiver_id: int):
    """Return today's missed/no_response doses for all elders under this caregiver."""
    rows = get_missed_doses_for_caregiver(caregiver_id)
    missed_list = []
    for r in rows:
        med_name = r["display_name_for_elder"] or r["brand_name_ar"]
        missed_list.append({
            "dose_id": r["dose_id"],
            "elder_name": r["elder_name"],
            "medication_name": med_name,
            "brand_name_ar": r["brand_name_ar"],
            "med_category": r["med_category"],
            "dosage": f"{r['dosage_amount']} {r['dosage_unit']}",
            "scheduled_time": r["scheduled_time"],
            "status": r["status"],
        })
    return {
        "total_missed_today": len(missed_list),
        "missed_doses": missed_list,
    }


@app.get("/reports/weekly/{elder_id}")
def get_weekly_report_api(elder_id: int):
    """Return weekly adherence summary for the report screen."""
    summary = get_weekly_adherence_summary(elder_id)
    return summary
