from fastapi import APIRouter, Depends

from ..deps import get_current_user
from ..models import User
from ..schemas import UserOut

router = APIRouter()


@router.get("/me", response_model=UserOut)
def me(usuario: User = Depends(get_current_user)):
    """Alias de /auth/me; retorna o usuário autenticado."""
    return usuario
