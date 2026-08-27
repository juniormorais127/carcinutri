from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user
from ..models import User
from ..schemas import Token, UserCreate, UserOut
from ..security import criar_access_token, hash_senha, verificar_senha

router = APIRouter()


@router.post("/register", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def registrar(dados: UserCreate, db: Session = Depends(get_db)):
    email = dados.email.lower()
    existente = db.scalar(select(User).where(User.email == email))
    if existente:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Já existe uma conta com este email",
        )

    user = User(
        email=email,
        password_hash=hash_senha(dados.senha),
        nome=dados.nome,
        telefone=dados.telefone,
        cidade=dados.cidade,
        regiao=dados.regiao,
        role=dados.role,
        perfil=dados.perfil,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.post("/login", response_model=Token)
def login(
    form: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)
):
    email = form.username.lower()
    user = db.scalar(select(User).where(User.email == email))
    if not user or not verificar_senha(form.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email ou senha incorretos",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = criar_access_token(subject=str(user.id), role=user.role.value)
    return Token(access_token=token, user=UserOut.model_validate(user))


@router.get("/me", response_model=UserOut)
def me(usuario: User = Depends(get_current_user)):
    return usuario
