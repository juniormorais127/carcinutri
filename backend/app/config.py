from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configurações lidas do ambiente / arquivo .env."""

    database_url: str
    jwt_secret: str
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 30  # 30 dias (sessão longa)
    cors_origins: str = "*"  # string separada por vírgula (ex.: "*" ou "http://a,http://b")

    # E-mail (verificação + esqueci senha). Sem RESEND_API_KEY, os links são
    # impressos no console (modo dev) em vez de enviados.
    resend_api_key: str = ""
    email_from: str = "Carcinutri <onboarding@resend.dev>"
    public_base_url: str = "http://localhost:8000"  # usado nos links dos e-mails

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


settings = Settings()
