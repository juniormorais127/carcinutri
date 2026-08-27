import secrets
from datetime import datetime, timedelta, timezone

from jose import jwt
from passlib.context import CryptContext

from .config import settings

# bcrypt fixado em 4.0.1 (requirements) para evitar incompatibilidade com passlib.
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def criar_token() -> str:
    """Token aleatório único para verificação de e-mail / redefinição de senha."""
    return secrets.token_urlsafe(32)


def hash_senha(senha: str) -> str:
    return pwd_context.hash(senha)


def verificar_senha(senha: str, hash_armazenado: str) -> bool:
    return pwd_context.verify(senha, hash_armazenado)


def criar_access_token(subject: str, role: str) -> str:
    expira = datetime.now(timezone.utc) + timedelta(
        minutes=settings.access_token_expire_minutes
    )
    payload = {
        "sub": subject,
        "role": role,
        "exp": expira,
        "iat": datetime.now(timezone.utc),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decodificar_token(token: str) -> dict:
    return jwt.decode(
        token, settings.jwt_secret, algorithms=[settings.jwt_algorithm]
    )
