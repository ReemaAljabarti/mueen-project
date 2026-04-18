from fastapi import FastAPI
from models import Elder, Caregiver, CaregiverLogin, ElderLogin
from database import (
    init_db,
    get_caregiver_by_email_or_phone,
    insert_caregiver,
    get_caregiver_by_login,
    insert_elder,
    get_elder_by_login,
    get_all_caregivers,
    get_elders_by_caregiver_id,
)
import json

app = FastAPI()

init_db()


@app.get("/")
def root():
    return {"message": "Mu'een API is running"}


# =============================
# Caregiver Signup
# =============================
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


# =============================
# Caregiver Login
# =============================
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


# =============================
# Add Elder (مرتبط بـ caregiver)
# =============================
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


# =============================
# Get Elders by Caregiver
# =============================
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


# =============================
# Elder Login
# =============================
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


# =============================
# Get Caregivers (للمراجعة)
# =============================
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