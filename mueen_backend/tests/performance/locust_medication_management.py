from locust import HttpUser, task, between


class MedicationManagementUser(HttpUser):
    wait_time = between(1, 3)

    @task(2)
    def medication_lookup_by_gtin(self):
        self.client.get(
            "/medications/by-gtin/6286023000126",
            name="Medication - GTIN Lookup",
        )

    @task(2)
    def drug_interaction_check(self):
        self.client.post(
            "/drug-interactions/check",
            json={
                "elder_id": 1,
                "catalog_medication_id": 2,
            },
            name="Medication - Drug Interaction Check",
        )