from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field


class Settings(BaseSettings):
    # Upload validation
    MAX_UPLOAD_BYTES: int = 25 * 1024 * 1024  # 25MB
    MIN_UPLOAD_BYTES: int = 1024              # 1KB
    ALLOWED_EXTENSIONS: set[str] = {"wav", "mp3", "m4a"}

    # OpenAI Core Configuration
    OPENAI_API_KEY: str = Field(..., description="OpenAI API key")
    OPENAI_TIMEOUT_SECONDS: int = 60

    # STT Configuration
    OPENAI_STT_MODEL: str = Field("gpt-4o-transcribe", description="OpenAI STT model")

    # NLU Configuration
    NLU_PROVIDER: str = Field("openai", description="NLU provider: openai | rules")

    OPENAI_NLU_MODEL: str = Field(
        "gpt-4o-mini",
        description="OpenAI model used for NLU parsing"
    )

    NLU_TEMPERATURE: float = Field(
        0.0,
        description="Temperature for NLU model (must stay low for determinism)"
    )

    NLU_INTENTS_PATH: str = Field(
        "app/nlu/resources/intents.yaml",
        description="Path to intents whitelist file"
    )

    NLU_SLOT_CATALOG_PATH: str = Field(
        "app/nlu/resources/slot_catalog_v2.json",
        description="Path to operational slot catalog"
    )

    # TTS Configuration
    OPENAI_TTS_MODEL: str = Field(
        "gpt-4o-mini-tts",
        description="OpenAI TTS model"
    )

    OPENAI_TTS_VOICE: str = Field(
        "cedar",
        description="OpenAI TTS voice"
    )

    OPENAI_TTS_FORMAT: str = Field(
        "mp3",
        description="OpenAI TTS audio format"
    )

    model_config = SettingsConfigDict( 
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

settings = Settings()