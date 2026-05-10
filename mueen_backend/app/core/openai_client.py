from openai import OpenAI
from app.core.config import settings

# Shared OpenAI client for entire backend
openai_client = OpenAI(
    api_key=settings.OPENAI_API_KEY,
    timeout=settings.OPENAI_TIMEOUT_SECONDS,
)   