from locust import HttpUser, task, between


class VoiceAssistantUser(HttpUser):
    wait_time = between(1, 3)

    @task(3)
    def ask_next_dose_no_audio(self):
        self.client.post(
            "/assistant/respond-text-no-audio",
            json={
                "text": "متى جرعتي الجاية؟",
                "elder_id": 5 
            },
            name="Ask Next Dose - No Audio"
        )

    @task(2)
    def ask_today_schedule_no_audio(self):
        self.client.post(
            "/assistant/respond-text-no-audio",
            json={
                "text": "وش عندي أدوية اليوم؟",
                "elder_id": 5
            },
            name="Ask Today Schedule - No Audio"
        )

    @task(1)
    def ask_remaining_doses_no_audio(self):
        self.client.post(
            "/assistant/respond-text-no-audio",
            json={
                "text": "كم باقي لي جرعات اليوم؟",
                "elder_id": 5
                
            },
            name="Ask Remaining Doses - No Audio"
        )