"""marketplace de servicos com custodia (escrow)

Revision ID: 0003_marketplace
Revises: 0002_email_verificacao
Create Date: 2026-08-27
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "0003_marketplace"
down_revision = "0002_email_verificacao"
branch_labels = None
depends_on = None


def _enum(nome, valores):
    return sa.Enum(*valores, name=nome, native_enum=True)

def upgrade() -> None:
    op.execute("DO $$ BEGIN CREATE TYPE solicitacao_status AS ENUM ('aberto', 'aceito', 'cancelado'); EXCEPTION WHEN duplicate_object THEN null; END $$;")
    op.execute("DO $$ BEGIN CREATE TYPE proposta_status AS ENUM ('pendente', 'aceita', 'recusada', 'retirada'); EXCEPTION WHEN duplicate_object THEN null; END $$;")
    op.execute("DO $$ BEGIN CREATE TYPE pagamento_status AS ENUM ('aguardando', 'pago', 'repassado', 'restituido'); EXCEPTION WHEN duplicate_object THEN null; END $$;")
    op.execute("DO $$ BEGIN CREATE TYPE execucao_status AS ENUM ('aguardando_pagamento', 'em_andamento', 'aguardando_aprovacao', 'concluido', 'cancelado'); EXCEPTION WHEN duplicate_object THEN null; END $$;")

    solicitacao_status = postgresql.ENUM("aberto", "aceito", "cancelado", name="solicitacao_status", create_type=False)
    proposta_status = postgresql.ENUM("pendente", "aceita", "recusada", "retirada", name="proposta_status", create_type=False)
    pagamento_status = postgresql.ENUM("aguardando", "pago", "repassado", "restituido", name="pagamento_status", create_type=False)
    execucao_status = postgresql.ENUM(
        "aguardando_pagamento", "em_andamento", "aguardando_aprovacao", "concluido", "cancelado",
        name="execucao_status",
        create_type=False,
    )

    op.create_table(
        "servicos_solicitacoes",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("produtor_id", postgresql.UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("titulo", sa.String(160), nullable=False),
        sa.Column("descricao", sa.Text(), nullable=True),
        sa.Column("categoria", sa.String(60), nullable=True),
        sa.Column("cidade", sa.String(120), nullable=True),
        sa.Column("valor_estimado", sa.Numeric(12, 2), nullable=False),
        sa.Column("status", solicitacao_status, nullable=False,
                  server_default="aberto"),
        sa.Column("criado_em", sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_servicos_solicitacoes_produtor_id", "servicos_solicitacoes", ["produtor_id"])
    op.alter_column("servicos_solicitacoes", "status", server_default=None)

    op.create_table(
        "servicos_propostas",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("servico_id", postgresql.UUID(as_uuid=True),
                  sa.ForeignKey("servicos_solicitacoes.id", ondelete="CASCADE"), nullable=False),
        sa.Column("tecnico_id", postgresql.UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("valor", sa.Numeric(12, 2), nullable=False),
        sa.Column("mensagem", sa.Text(), nullable=True),
        sa.Column("status", proposta_status, nullable=False,
                  server_default="pendente"),
        sa.Column("criado_em", sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_servicos_propostas_servico_id", "servicos_propostas", ["servico_id"])
    op.create_index("ix_servicos_propostas_tecnico_id", "servicos_propostas", ["tecnico_id"])
    op.alter_column("servicos_propostas", "status", server_default=None)

    op.create_table(
        "servicos_contratos",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("servico_id", postgresql.UUID(as_uuid=True),
                  sa.ForeignKey("servicos_solicitacoes.id", ondelete="CASCADE"),
                  nullable=False, unique=True),
        sa.Column("proposta_id", postgresql.UUID(as_uuid=True),
                  sa.ForeignKey("servicos_propostas.id", ondelete="SET NULL"), nullable=True),
        sa.Column("produtor_id", postgresql.UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("tecnico_id", postgresql.UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("valor_acordado", sa.Numeric(12, 2), nullable=False),
        sa.Column("pagamento", pagamento_status, nullable=False,
                  server_default="aguardando"),
        sa.Column("execucao", execucao_status, nullable=False,
                  server_default="aguardando_pagamento"),
        sa.Column("criado_em", sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_servicos_contratos_servico_id", "servicos_contratos", ["servico_id"])
    op.create_index("ix_servicos_contratos_produtor_id", "servicos_contratos", ["produtor_id"])
    op.create_index("ix_servicos_contratos_tecnico_id", "servicos_contratos", ["tecnico_id"])
    op.alter_column("servicos_contratos", "pagamento", server_default=None)
    op.alter_column("servicos_contratos", "execucao", server_default=None)

    op.create_table(
        "servicos_mensagens",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("contrato_id", postgresql.UUID(as_uuid=True),
                  sa.ForeignKey("servicos_contratos.id", ondelete="CASCADE"), nullable=False),
        sa.Column("remetente_id", postgresql.UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("texto", sa.Text(), nullable=False),
        sa.Column("criado_em", sa.DateTime(timezone=True),
                  server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_servicos_mensagens_contrato_id", "servicos_mensagens", ["contrato_id"])
    op.create_index("ix_servicos_mensagens_remetente_id", "servicos_mensagens", ["remetente_id"])


def downgrade() -> None:
    op.drop_table("servicos_mensagens")
    op.drop_table("servicos_contratos")
    op.drop_table("servicos_propostas")
    op.drop_table("servicos_solicitacoes")

    op.execute("DROP TYPE IF EXISTS execucao_status")
    op.execute("DROP TYPE IF EXISTS pagamento_status")
    op.execute("DROP TYPE IF EXISTS proposta_status")
    op.execute("DROP TYPE IF EXISTS solicitacao_status")
