from datetime import date, datetime
from typing import Any, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from .models import RoleEnum


class UserCreate(BaseModel):
    email: EmailStr
    senha: str = Field(min_length=6)
    nome: str = Field(min_length=1, max_length=120)
    telefone: Optional[str] = None
    cidade: Optional[str] = None
    regiao: Optional[str] = None
    role: RoleEnum
    perfil: Optional[dict[str, Any]] = None


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    email: EmailStr
    nome: str
    telefone: Optional[str] = None
    cidade: Optional[str] = None
    regiao: Optional[str] = None
    role: RoleEnum
    perfil: Optional[dict[str, Any]] = None
    email_verificado: bool = False
    criado_em: datetime


class EmailRequest(BaseModel):
    """Usado em /reenviar-verificacao e /esqueci-senha."""

    email: EmailStr


class RedefinirSenha(BaseModel):
    token: str
    nova_senha: str = Field(min_length=6)


class UserLogin(BaseModel):
    email: EmailStr
    senha: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


# ---------------------------------------------------------------------------
# Sync (offline-first): registros de domínio enviados do app para o servidor.
# O id é o UUID gerado no aparelho; o servidor faz upsert escopado ao usuário.
# ---------------------------------------------------------------------------


class ViveiroSync(BaseModel):
    id: UUID
    fazenda_id: Optional[UUID] = None
    nome: str
    area_ha: float
    densidade_padrao: Optional[float] = None
    marca_racao: Optional[str] = None
    data_povoamento: Optional[date] = None
    criado_em: Optional[datetime] = None


class BiometriaSync(BaseModel):
    id: UUID
    viveiro_id: UUID
    data: date
    peso_amostra_kg: float
    n_amostrado: int
    peso_medio: Optional[float] = None
    criado_em: Optional[datetime] = None


class QualidadeAguaSync(BaseModel):
    id: UUID
    viveiro_id: UUID
    data: date
    od: Optional[float] = None
    ph: Optional[float] = None
    temperatura: Optional[float] = None
    amonia: Optional[float] = None
    nitrito: Optional[float] = None
    alcalinidade: Optional[float] = None
    criado_em: Optional[datetime] = None


class CalculoSync(BaseModel):
    id: UUID
    viveiro_id: Optional[UUID] = None
    tipo: str
    entradas: dict[str, Any]
    resultado: dict[str, Any]
    criado_em: Optional[datetime] = None


class ResultadoSync(BaseModel):
    recebidos: int
    sincronizados: int
