from __future__ import annotations

from typing import Any, Optional


class AssistantResponseFormatter:
    """
    Builds the final short spoken Arabic response from DB retrieval output.
    This class only formats text and does not call DB, NLU, or TTS services.
    """

    # Main formatter entry point.
    def build_spoken_response(
        self,
        db_response: Any,
        response_mode: Optional[str] = None,
    ) -> str:
        status = self._read_value(db_response, "status")
        matched_by = self._read_value(db_response, "matched_by")
        matched_value = self._clean_text(self._read_value(db_response, "matched_value"))
        count = self._read_value(db_response, "count", 0)

        if status != "success":
            return self._build_error_response(status, matched_value)

        if self._is_elder_schedule_response(matched_value):
            return self._build_elder_schedule_response(db_response, matched_value)

        if matched_by == "med_category" or (isinstance(count, int) and count > 1):
            return self._build_ambiguous_response()

        return self._build_success_response(
            db_response=db_response,
            response_mode=response_mode,
        )

    # Detect elder schedule/action responses from matched_value metadata.
    def _is_elder_schedule_response(self, matched_value: str) -> bool:
        return matched_value.startswith("elder_id:")

    # Extract schedule/action type from matched_value metadata.
    def _get_schedule_type(self, matched_value: str) -> str:
        schedule_type_map = {
            "schedule_type:next_dose": "next_dose",
            "schedule_type:today_schedule": "today_schedule",
            "schedule_type:remaining_doses": "remaining_doses",
            "schedule_type:confirm_mark_taken": "confirm_mark_taken",
            "schedule_type:confirm_mark_missed": "confirm_mark_missed",
            "schedule_type:confirm_snooze": "confirm_snooze",
            "schedule_type:mark_taken_done": "mark_taken_done",
            "schedule_type:mark_missed_done": "mark_missed_done",
            "schedule_type:snooze_done": "snooze_done",
            "schedule_type:snooze_already_used": "snooze_already_used",
            "schedule_type:snooze_invalid_minutes": "snooze_invalid_minutes",
            "schedule_type:mark_taken": "mark_taken",
            "schedule_type:mark_missed": "mark_missed",
            "schedule_type:snooze": "snooze",
            "schedule_type:confirm": "confirm",
            "schedule_type:cancel": "cancel",
            "schedule_type:repeat": "repeat",
            "schedule_type:adherence_status_pending": "adherence_status_pending",
            "schedule_type:adherence_status": "adherence_status",
        }

        for key, schedule_type in schedule_type_map.items():
            if key in matched_value:
                return schedule_type

        return "schedule"

    # Build spoken response for schedule and action results.
    def _build_elder_schedule_response(
        self,
        db_response: Any,
        matched_value: str,
    ) -> str:
        result = self._read_value(db_response, "result", [])
        schedule_type = self._get_schedule_type(matched_value)

        if not isinstance(result, list) or not result:
            return "ما لقيت جرعات مسجلة لك حاليًا."

        if schedule_type == "next_dose":
            return self._build_next_dose_response(result)

        if schedule_type == "today_schedule":
            return self._build_today_schedule_response(result)

        if schedule_type == "remaining_doses":
            return self._build_remaining_doses_response(result)

        if schedule_type in {
            "confirm_mark_taken",
            "confirm_mark_missed",
            "confirm_snooze",
            "mark_taken",
            "mark_missed",
            "mark_taken_done",
            "mark_missed_done",
            "snooze",
            "snooze_done",
            "snooze_already_used",
            "snooze_invalid_minutes",
            "adherence_status_pending",
            "confirm",
            "cancel",
            "repeat",
        }:
            return self._build_action_message_response(
                result=result,
                fallback="أحتاج تأكيدك قبل تنفيذ هذا الإجراء.",
            )

        if schedule_type == "adherence_status":
            return self._build_adherence_status_response(result)

        return self._build_today_schedule_response(result)

    # Build response for the next dose.
    def _build_next_dose_response(self, result: list[Any]) -> str:
        item = result[0]

        brand_name = self._clean_text(self._read_value(item, "brand_name_ar"))
        schedule_text = self._clean_text(self._read_value(item, "uses_ar"))

        if schedule_text:
            schedule_text = self._format_times_in_text(schedule_text)

            if brand_name:
                return f"جرعتك الجاية هي: {brand_name}، {schedule_text}."

            return f"جرعتك الجاية هي: {schedule_text}."

        if brand_name:
            return f"جرعتك الجاية هي {brand_name}."

        return "لقيت الجرعة الجاية، لكن ما قدرت أجهز الرد بشكل واضح."

    # Build today's medication list with medication names only.

    def _build_today_schedule_response(self, result: list[Any]) -> str:
        items = self._build_name_schedule_items(result)

        if not items:
            return "لقيت أدوية اليوم، لكن ما قدرت أجهز الرد بشكل واضح."

        joined_items = "، ".join(items)
        return f"أدويتك اليوم هي: {joined_items}."

    # Build medication name list only.
    def _build_name_only_items(self, result: list[Any]) -> list[str]:
        items: list[str] = []

        for item in result:
            brand_name = self._clean_text(self._read_value(item, "brand_name_ar"))

            if brand_name:
                items.append(brand_name)

        return items

    # Build remaining doses response from current time until the end of today.
    def _build_remaining_doses_response(self, result: list[Any]) -> str:
        items = self._build_name_schedule_items(result)
        count = len(items)

        if count == 0:
            return "ما بقيت لك جرعات اليوم."

        joined_items = "، ".join(items)

        if count == 1:
            return f"باقي لك جرعة واحدة: {joined_items}."

        if count == 2:
            return f"باقي لك جرعتين: {joined_items}."

        if count == 3:
            return f"باقي لك ثلاث جرعات: {joined_items}."

        return f"باقي لك {count} جرعات: {joined_items}."

    # Build medication name with dose schedule text.
    def _build_name_schedule_items(self, result: list[Any]) -> list[str]:
        items: list[str] = []

        for item in result:
            brand_name = self._clean_text(self._read_value(item, "brand_name_ar"))
            schedule_text = self._clean_text(self._read_value(item, "uses_ar"))

            if schedule_text:
                schedule_text = self._format_times_in_text(schedule_text)

            if brand_name and schedule_text:
                items.append(f"{brand_name}، {schedule_text}")
            elif brand_name:
                items.append(brand_name)
            elif schedule_text:
                items.append(schedule_text)

        return items

    # Build medication name + category list from schedule records.
    def _build_name_category_items(self, result: list[Any]) -> list[str]:
        items: list[str] = []

        for item in result:
            brand_name = self._clean_text(self._read_value(item, "brand_name_ar"))
            schedule_text = self._clean_text(self._read_value(item, "uses_ar"))
            category = self._extract_category_from_schedule_text(schedule_text)

            if brand_name and category:
                items.append(f"{brand_name}، {category}")
            elif brand_name:
                items.append(brand_name)
            elif category:
                items.append(category)

        return items

    # Extract category from schedule text before the first colon.
    def _extract_category_from_schedule_text(self, schedule_text: str) -> str:
        schedule_text = self._clean_text(schedule_text)

        if not schedule_text:
            return ""

        if ":" in schedule_text:
            return self._clean_text(schedule_text.split(":", 1)[0])

        return ""

    # Return action or pending confirmation message stored in uses_ar.
    def _build_action_message_response(
        self,
        result: list[Any],
        fallback: str,
    ) -> str:
        item = result[0]
        message = self._clean_text(self._read_value(item, "uses_ar"))

        if message:
            return self._format_times_in_text(message)

        return fallback

    # Build adherence summary response from compact summary string.
    def _build_adherence_status_response(self, result: list[Any]) -> str:
        item = result[0]
        message = self._clean_text(self._read_value(item, "uses_ar"))

        if not message:
            return "ما قدرت أطلع ملخص الالتزام حاليًا."

        return self._format_times_in_text(message)

    # Build spoken response for a single medication result.
    def _build_success_response(
        self,
        db_response: Any,
        response_mode: Optional[str] = None,
    ) -> str:
        result = self._read_value(db_response, "result", [])

        if not isinstance(result, list) or not result:
            return "لقيت الدواء، لكن ما قدرت أجهز الرد بشكل واضح."

        item = result[0]

        brand_name = self._clean_text(self._read_value(item, "brand_name_ar"))
        uses_ar = self._clean_text(self._read_value(item, "uses_ar"))
        food_guide_ar = self._clean_text(self._read_value(item, "food_guide_ar"))

        if not brand_name:
            return "لقيت الدواء، لكن اسم الدواء مو واضح."

        if response_mode == "usage":
            if uses_ar:
                return self._format_usage_response(brand_name, uses_ar)
            return f"لقيت {brand_name}، لكن ما عندي معلومات استخدام له حاليًا."

        if response_mode == "food_guide":
            if food_guide_ar:
                return self._format_food_guide_response(brand_name, food_guide_ar)
            return f"لقيت {brand_name}، لكن ما عندي إرشادات أكل له حاليًا."

        if uses_ar:
            return self._format_usage_response(brand_name, uses_ar)

        if food_guide_ar:
            return self._format_food_guide_response(brand_name, food_guide_ar)

        return f"لقيت {brand_name}، لكن ما عندي معلومات إضافية عنه حاليًا."

    # Format medication usage text as stored in the database.
    def _format_usage_response(self, brand_name: str, uses_ar: str) -> str:
        brand_name = self._clean_text(brand_name)
        uses_ar = self._normalize_usage_text(uses_ar)

        if not brand_name or not uses_ar:
            return "لقيت الدواء، لكن ما عندي معلومات استخدام له حاليًا."

        uses_ar = self._ensure_sentence_end(uses_ar)

        return f"{brand_name}: {uses_ar}"

    # Format medication food-guide text as stored in the database.
    def _format_food_guide_response(self, brand_name: str, food_guide_ar: str) -> str:
        brand_name = self._clean_text(brand_name)
        food_guide_ar = self._normalize_food_guide_text(food_guide_ar)

        if not brand_name or not food_guide_ar:
            return "لقيت الدواء، لكن ما عندي إرشادات أكل له حاليًا."

        food_guide_ar = self._ensure_sentence_end(food_guide_ar)

        if brand_name in food_guide_ar:
            return food_guide_ar

        return f"بالنسبة لـ {brand_name}: {food_guide_ar}"

    # Build spoken text for non-success statuses.
    def _build_error_response(
        self,
        status: Optional[str],
        matched_value: str = "",
    ) -> str:
        if status == "not_found":
            not_found_messages = {
                "schedule_type:today_schedule": "ما عندك أدوية مسجلة اليوم.",
                "schedule_type:next_dose": "ما بقيت لك جرعات اليوم.",
                "schedule_type:remaining_doses": "ما لقيت جرعات متبقية مسجلة لك اليوم.",
                "schedule_type:mark_taken": "ما لقيت جرعة حالية أقدر أسجلها كمأخوذة.",
                "schedule_type:mark_missed": "ما لقيت جرعة حالية أقدر أسجلها كفائتة.",
                "schedule_type:snooze": "ما لقيت جرعة حالية أقدر أؤجلها.",
                "schedule_type:confirm": "ما فيه إجراء بانتظار التأكيد حاليًا.",
                "schedule_type:cancel": "ما فيه إجراء أقدر ألغيه حاليًا.",
                "schedule_type:repeat": "ما فيه رد سابق أقدر أعيده حاليًا.",
            }

            for key, message in not_found_messages.items():
                if key in matched_value:
                    return message

            return "ما لقيت بيانات مناسبة لهذا الطلب. تأكد من البيانات لو سمحت."

        if status == "invalid_input" and "schedule_type:snooze_invalid_minutes" in matched_value:
            return "معليش، ما أقدر أأجل الجرعة للوقت اللي طلبته. لو سمحت اختر 15 أو 20 أو 30 دقيقة."

        status_messages = {
            "ambiguous": self._build_ambiguous_response(),
            "invalid_input": "ما فهمت الطلب بشكل كافٍ. قل اسم الدواء أو المطلوب بشكل أوضح.",
            "unsupported_intent": "معليش، هذا الطلب مو مدعوم حاليًا.",
        }

        return status_messages.get(status, "حدث خطأ غير متوقع. جرّب مرة ثانية.")

    # Return clarification response for ambiguous medication matches.
    def _build_ambiguous_response(self) -> str:
        return "فيه أكثر من دواء مطابق. اذكر اسم الدواء لو سمحت."

    # Return usage text as stored in the database.
    def _normalize_usage_text(self, text: str) -> str:
        text = self._clean_text(text)
        return self._format_times_in_text(text)

    # Return food-guide text as stored in the database.
    def _normalize_food_guide_text(self, text: str) -> str:
        text = self._clean_text(text)
        return self._format_times_in_text(text)

    # Convert HH:MM text into Arabic-friendly spoken time.
    def _format_time_for_speech(self, time_text: str) -> str:
        try:
            hour_text, minute_text = time_text.split(":", 1)
            hour = int(hour_text)
            minute = int(minute_text)
        except (ValueError, TypeError):
            return time_text

        period = "صباحًا" if hour < 12 else "مساءً"
        spoken_hour = hour % 12

        if spoken_hour == 0:
            spoken_hour = 12

        if minute == 0:
            return f"{spoken_hour} {period}"

        return f"{spoken_hour}:{minute_text} {period}"

    # Replace HH:MM time patterns inside Arabic spoken text.
    def _format_times_in_text(self, text: str) -> str:
        text = self._clean_text(text)

        if not text:
            return ""

        words = text.split()
        formatted_words: list[str] = []

        for word in words:
            cleaned_word = word.strip("،.؟!؛")
            trailing = word[len(cleaned_word):] if cleaned_word else ""

            if len(cleaned_word) == 5 and cleaned_word[2] == ":":
                formatted_time = self._format_time_for_speech(cleaned_word)
                formatted_words.append(f"{formatted_time}{trailing}")
            else:
                formatted_words.append(word)

        return " ".join(formatted_words)

    # Read a value from dicts or normal objects.
    def _read_value(self, source: Any, key: str, default: Any = None) -> Any:
        if source is None:
            return default

        if isinstance(source, dict):
            return source.get(key, default)

        return getattr(source, key, default)

    # Convert any value into clean trimmed text.
    def _clean_text(self, value: Any) -> str:
        if value is None:
            return ""

        text = str(value).strip()

        if not text:
            return ""

        return " ".join(text.split())

    # Add a period if the text does not already end with punctuation.
    def _ensure_sentence_end(self, text: str) -> str:
        text = self._clean_text(text)

        if not text:
            return text

        if text.endswith(("؟", "!", ".", "،")):
            return text 

        return f"{text}."

    # Safely convert values to int for adherence summary.
    def _safe_int(self, value: Any) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return 0 
        

