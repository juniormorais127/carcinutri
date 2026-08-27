from uuid import UUID

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError
from sqlalchemy.orm import Session

from .database import get_db
from .models import RoleEnum, User
from .security import decodificar_token

# tokenUrl é usado apenas para documentar o fluxo OAuth2 no Swagger UI.
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")


def get_current_user(
    token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)
) -> User:
    credenciais_invalidas = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Não foi possível validar as credenciais",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = decodificar_token(token)
        subject = payload.get("sub")
        if subject is None:
            raise credenciais_invalidas
        user_id = UUID(subject)
    except (JWTError, ValueError):
        raise credenciais_invalidas

    user = db.get(User, user_id)
    if user is None:
        raise credenciais_invalidas
    return user


def requer_role(*roles: RoleEnum):
    """Dependência que exige que o usuário tenha um dos perfis informados."""

    def _checar(usuario: User = Depends(get_current_user)) -> User:
        if usuario.role not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Operação não permitida para este perfil",
            )
        return usuario

    return _checar
