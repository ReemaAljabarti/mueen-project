from locust import HttpUser, task, between
import random


DOSES = [
    {"dose_id": 194, "elder_id": 25, "elder_medication_id": 18},
    {"dose_id": 195, "elder_id": 25, "elder_medication_id": 19},
    {"dose_id": 196, "elder_id": 25, "elder_medication_id": 20},
    {"dose_id": 200, "elder_id": 25, "elder_medication_id": 54},
    {"dose_id": 201, "elder_id": 25, "elder_medication_id": 55},
    {"dose_id": 202, "elder_id": 25, "elder_medication_id": 56},
    {"dose_id": 203, "elder_id": 25, "elder_medication_id": 57},
    {"dose_id": 204, "elder_id": 25, "elder_medication_id": 58},
]


class AdherenceApiUser(HttpUser):
    wait_time = between(1, 3)

    @task(2)
    def mark_dose_taken(self):
        dose = random.choice(DOSES)

        self.client.post(
            "/adherence/taken",
            json=dose,
            name="Mark Dose Taken"
        )

    @task(2)
    def mark_dose_missed(self):
        dose = random.choice(DOSES)

        self.client.post(
            "/adherence/missed",
            json=dose,
            name="Mark Dose Missed"
        )

    @task(1)
    def snooze_dose(self):
        dose = random.choice(DOSES).copy()
        dose["snooze_minutes"] = random.choice([15, 20, 30])

        self.client.post(
            "/reminders/snooze",
            json=dose,
            name="Snooze Dose"
        )