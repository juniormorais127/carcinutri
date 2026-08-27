from datetime import date, datetime
from typing import Any, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from .models import (
    ExecucaoStatus,
    PagamentoStatus,
    PropostaStatus,
    RoleEnum,
    SolicitacaoStatus,
)


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


# ---------------------------------------------------------------------------
# Marketplace de serviços (produtor ↔ técnico) com custódia
# ---------------------------------------------------------------------------


class ServicoSolicitacaoCreate(BaseModel):
    titulo: str = Field(min_length=3, max_length=160)
    descricao: Optional[str] = None
    categoria: Optional[str] = None
    cidade: Optional[str] = None
    valor_estimado: float


class ServicoOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    produtor_id: UUID
    produtor_nome: str
    titulo: str
    descricao: Optional[str] = None
    categoria: Optional[str] = None
    cidade: Optional[str] = None
    valor_estimado: float
    status: SolicitacaoStatus
    criado_em: datetime


class ServicoSync(BaseModel):
    id: UUID
    titulo: str
    descricao: Optional[str] = None
    categoria: Optional[str] = None
    cidade: Optional[str] = None
    valor_estimado: float
    status: SolicitacaoStatus = SolicitacaoStatus.aberto
    criado_em: Optional[datetime] = None


class PropostaCreate(BaseModel):
    valor: float
    mensagem: Optional[str] = None


class PropostaOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    servico_id: UUID
    tecnico_id: UUID
    tecnico_nome: str
    valor: float
    mensagem: Optional[str] = None
    status: PropostaStatus
    criado_em: datetime


class ContratoOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    servico_id: UUID
    servico_titulo: str
    produtor_id: UUID
    produtor_nome: str
    tecnico_id: UUID
    tecnico_nome: str
    valor_acordado: float
    pagamento: PagamentoStatus
    execucao: ExecucaoStatus
    comunicacao_liberada: bool = False
    foto_visita: Optional[str] = None
    foto_solucao: Optional[str] = None
    descricao_solucao: Optional[str] = None
    criado_em: datetime


class FinalizarServicoPayload(BaseModel):
    foto_visita: Optional[str] = None
    foto_solucao: Optional[str] = None
    descricao_solucao: Optional[str] = None


class MensagemCreate(BaseModel):
    texto: str = Field(min_length=1, max_length=2000)


class MensagemOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    contrato_id: UUID
    remetente_id: UUID
    remetente_nome: str
    texto: str
    criado_em: datetime
