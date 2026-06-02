from locust import HttpUser, task, between


class DoseAlertUser(HttpUser):
    wait_time = between(1, 3)

    elder_id = 1

    @task(3)
    def get_due_doses(self):
        self.client.get(
            f"/reminders/due-now/{self.elder_id}",
            name="Alert - Get Due Doses",
        )
