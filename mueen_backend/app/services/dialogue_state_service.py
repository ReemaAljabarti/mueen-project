from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Any, Optional


# Represents a temporary action that needs user confirmation (e.g. take dose, snooze)
@dataclass
class PendingAction:
    elder_id: int
    action_type: str
    dose_id: Optional[int] = None
    medication_name: str = ""
    dose_time: str = ""
    minutes: Optional[int] = None
    message: str = ""
    metadata: dict[str, Any] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.now)
    expires_at: datetime = field(default_factory=lambda: datetime.now() + timedelta(minutes=5))


# Stores the full dialogue state for a single elder
@dataclass
class DialogueState:
    elder_id: int
    pending_action: Optional[PendingAction] = None
    last_response: str = ""
    updated_at: datetime = field(default_factory=datetime.now)


class DialogueStateService:
    """
    Keeps temporary dialogue state for the voice assistant.
    This service is memory-based and does NOT write anything to the database.
    """

    def __init__(self) -> None:
        # In-memory store: elder_id -> DialogueState
        self._states: dict[int, DialogueState] = {}

    # Save the last spoken response (used for Repeat intent)
    def save_last_response(
        self,
        elder_id: int,
        response_text: str,
    ) -> None:
        state = self._get_or_create_state(elder_id)
        state.last_response = self._clean_text(response_text)
        state.updated_at = datetime.now()

    # Retrieve the last spoken response for this elder
    def get_last_response(self, elder_id: int) -> str:
        state = self._states.get(elder_id)

        if state is None:
            return ""

        return self._clean_text(state.last_response)

    # Create and store a new pending action that requires confirmation
    def set_pending_action(
        self,
        elder_id: int,
        action_type: str,
        dose_id: Optional[int] = None,
        medication_name: str = "",
        dose_time: str = "",
        minutes: Optional[int] = None,
        message: str = "",
        metadata: Optional[dict[str, Any]] = None,
        ttl_minutes: int = 5,
    ) -> PendingAction:
        state = self._get_or_create_state(elder_id)

        # Create a new pending action with expiration time
        pending_action = PendingAction(
            elder_id=elder_id,
            action_type=self._clean_text(action_type),
            dose_id=dose_id,
            medication_name=self._clean_text(medication_name),
            dose_time=self._clean_text(dose_time),
            minutes=minutes,
            message=self._clean_text(message),
            metadata=metadata or {},
            expires_at=datetime.now() + timedelta(minutes=ttl_minutes),
        )

        # Store it in the dialogue state
        state.pending_action = pending_action
        state.updated_at = datetime.now()

        return pending_action

    # Retrieve the current pending action if still valid (not expired)
    def get_pending_action(self, elder_id: int) -> Optional[PendingAction]:
        state = self._states.get(elder_id)

        if state is None or state.pending_action is None:
            return None

        # Auto-clear if expired
        if self._is_expired(state.pending_action):
            state.pending_action = None
            state.updated_at = datetime.now()
            return None

        return state.pending_action

    # Clear any existing pending action without confirmation
    def clear_pending_action(self, elder_id: int) -> None:
        state = self._states.get(elder_id)

        if state is None:
            return

        state.pending_action = None
        state.updated_at = datetime.now()

    # Confirm the pending action and then clear it
    def confirm_pending_action(self, elder_id: int) -> Optional[PendingAction]:
        pending_action = self.get_pending_action(elder_id)

        if pending_action is None:
            return None

        self.clear_pending_action(elder_id)
        return pending_action

    # Cancel the pending action (returns False if nothing to cancel)
    def cancel_pending_action(self, elder_id: int) -> bool:
        pending_action = self.get_pending_action(elder_id)

        if pending_action is None:
            return False

        self.clear_pending_action(elder_id)
        return True

    # Completely remove all dialogue state for this elder
    def clear_state(self, elder_id: int) -> None:
        self._states.pop(elder_id, None)

    # Check if there is an active pending action
    def has_pending_action(self, elder_id: int) -> bool:
        return self.get_pending_action(elder_id) is not None

    # Internal helper: get existing state or create a new one
    def _get_or_create_state(self, elder_id: int) -> DialogueState:
        if elder_id not in self._states:
            self._states[elder_id] = DialogueState(elder_id=elder_id)

        return self._states[elder_id]

    # Internal helper: check if pending action is expired
    def _is_expired(self, pending_action: PendingAction) -> bool:
        return datetime.now() > pending_action.expires_at

    # Internal helper: normalize and clean text input
    def _clean_text(self, value: Any) -> str:
        if value is None:
            return ""

        text = str(value).strip()

        if not text:
            return ""

        return " ".join(text.split())
 

# Global singleton instance used across the assistant
dialogue_state_service = DialogueStateService()