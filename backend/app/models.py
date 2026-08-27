import enum
import uuid
from datetime import datetime

from sqlalchemy import (
    JSON,
    Boolean,
    Column,
    Date,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    String,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from .database import Base


def _uuid() -> uuid.UUID:
    return uuid.uuid4()


class RoleEnum(str, enum.Enum):
    produtor = "produtor"
    tecnico = "tecnico"


def _pk() -> Column:
    return Column(UUID(as_uuid=True), primary_key=True, default=_uuid)


def _criado_em() -> Column:
    return Column(DateTime(timezone=True), server_default=func.now())


class User(Base):
    __tablename__ = "users"

    id = _pk()
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    nome = Column(String(120), nullable=False)
    telefone = Column(String(40))
    cidade = Column(String(120))
    regiao = Column(String(120))
    role = Column(Enum(RoleEnum, name="user_role", native_enum=True), nullable=False)
    # Campos específicos de perfil (stub livre, evolui sem migração nesta etapa).
    perfil = Column(JSONB)
    # Verificação de e-mail + recuperação de senha.
    email_verificado = Column(Boolean, nullable=False, default=False)
    token_verificacao = Column(String(64))
    token_reset = Column(String(64))
    token_reset_expira = Column(DateTime(timezone=True))
    criado_em = _criado_em()


class Fazenda(Base):
    __tablename__ = "fazendas"

    id = _pk()
    usuario_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    nome = Column(String(160), nullable=False)
    cidade = Column(String(120))
    regiao = Column(String(120))
    criado_em = _criado_em()

    usuario = relationship("User")


class Viveiro(Base):
    __tablename__ = "viveiros"

    id = _pk()
    usuario_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    fazenda_id = Column(UUID(as_uuid=True), ForeignKey("fazendas.id", ondelete="SET NULL"), index=True)
    nome = Column(String(160), nullable=False)
    area_ha = Column(Numeric(10, 3), nullable=False)
    densidade_padrao = Column(Numeric(8, 2))
    marca_racao = Column(String(120))
    data_povoamento = Column(Date)
    criado_em = _criado_em()

    fazenda = relationship("Fazenda")


class Biometria(Base):
    __tablename__ = "biometrias"

    id = _pk()
    usuario_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    viveiro_id = Column(UUID(as_uuid=True), ForeignKey("viveiros.id", ondelete="CASCADE"), nullable=False, index=True)
    data = Column(Date, nullable=False)
    peso_amostra_kg = Column(Numeric(10, 4), nullable=False)
    n_amostrado = Column(Integer, nullable=False)
    peso_medio = Column(Numeric(10, 2))
    criado_em = _criado_em()

    viveiro = relationship("Viveiro")


class QualidadeAgua(Base):
    __tablename__ = "qualidade_agua"

    id = _pk()
    usuario_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    viveiro_id = Column(UUID(as_uuid=True), ForeignKey("viveiros.id", ondelete="CASCADE"), nullable=False, index=True)
    data = Column(Date, nullable=False)
    od = Column(Numeric(6, 2))
    ph = Column(Numeric(4, 2))
    temperatura = Column(Numeric(5, 2))
    amonia = Column(Numeric(6, 3))
    nitrito = Column(Numeric(6, 3))
    alcalinidade = Column(Numeric(8, 2))
    criado_em = _criado_em()

    viveiro = relationship("Viveiro")


class Calculo(Base):
    __tablename__ = "calculos"

    id = _pk()
    usuario_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    viveiro_id = Column(UUID(as_uuid=True), ForeignKey("viveiros.id", ondelete="SET NULL"))
    tipo = Column(String(40), nullable=False)  # mapeia TipoCalculadora.name
    entradas = Column(JSON, nullable=False)
    resultado = Column(JSON, nullable=False)
    criado_em = _criado_em()

    viveiro = relationship("Viveiro")


class VisitaTecnica(Base):
    """Fundação do perfil técnico: conexão técnico ↔ produtor ↔ fazenda."""

    __tablename__ = "visitas_tecnicas"

    id = _pk()
    # O técnico de campo dono da visita.
    usuario_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    # Fazenda do produtor visitada.
    fazenda_id = Column(UUID(as_uuid=True), ForeignKey("fazendas.id", ondelete="SET NULL"), index=True)
    # Produtor atendido.
    produtor_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), index=True)
    data = Column(Date, nullable=False)
    relatorio = Column(Text)
    proxima_visita = Column(Date)
    criado_em = _criado_em()

    fazenda = relationship("Fazenda")
    # Há duas FKs para users (usuario_id e produtor_id); especifica a do produtor.
    produtor = relationship("User", foreign_keys=[produtor_id])


# Índices compostos úteis para as consultas por dono + viveiro.
Index("ix_biometrias_viveiro_data", Biometria.viveiro_id, Biometria.data)
Index("ix_qualidade_viveiro_data", QualidadeAgua.viveiro_id, QualidadeAgua.data)
