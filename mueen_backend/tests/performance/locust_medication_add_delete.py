from locust import HttpUser, task, between
import random


class MedicationAddDeleteUser(HttpUser):
    wait_time = between(1, 3)

    elder_id = 1
    catalog_medication_id = 3

    @task
    def add_get_and_delete_medication(self):
        unique_name = f"Performance Test Medication {random.randint(1000, 9999)}"

        # Step 1: Add a medication for the elder.
        add_response = self.client.post(
            "/elder-medications",
            json={
                "elder_id": self.elder_id,
                "catalog_medication_id": self.catalog_medication_id,
                "display_name_for_elder": unique_name,
                "dosage_amount": 1,
                "dosage_unit": "حبة",
                "usage_instruction": "بعد الفطور",
                "short_description": "Performance test medication",
                "treatment_duration_type": None,
                "start_date": None,
                "end_date": None,
                "times_per_day": 1,
                "first_reminder_time": "9:00 ص",
                "days_pattern": "daily",
            },
            name="Medication - Add Elder Medication",
        )

        # Step 2: If add succeeded, retrieve the elder medication list.
        if add_response.status_code == 200:
            list_response = self.client.get(
                f"/elder-medications/{self.elder_id}",
                name="Medication - Get Elder Medications",
            )

            if list_response.status_code == 200:
                medications = list_response.json()

                # Step 3: Find the medication that was just added by its unique name.
                added_medication = next(
                    (
                        med for med in medications
                        if med.get("display_name_for_elder") == unique_name
                    ),
                    None
                )

                # Step 4: Delete the same medication using its returned ID.
                if added_medication:
                    elder_medication_id = added_medication.get("id")

                    if elder_medication_id:
                        self.client.delete(
                            f"/elder-medications/{elder_medication_id}",
                            name="Medication - Delete Elder Medication",
                        )