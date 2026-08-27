"""initial schema

Revision ID: 0001_initial
Revises:
Create Date: 2026-08-27
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "0001_initial"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("email", sa.String(255), nullable=False),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("nome", sa.String(120), nullable=False),
        sa.Column("telefone", sa.String(40), nullable=True),
        sa.Column("cidade", sa.String(120), nullable=True),
        sa.Column("regiao", sa.String(120), nullable=True),
        sa.Column(
            "role",
            sa.Enum("produtor", "tecnico", name="user_role", native_enum=True),
            nullable=False,
        ),
        sa.Column("perfil", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column(
            "criado_em",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.UniqueConstraint("email"),
    )
    op.create_index("ix_users_email", "users", ["email"])

    op.create_table(
        "fazendas",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "usuario_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("nome", sa.String(160), nullable=False),
        sa.Column("cidade", sa.String(120), nullable=True),
        sa.Column("regiao", sa.String(120), nullable=True),
        sa.Column(
            "criado_em",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
    )
    op.create_index("ix_fazendas_usuario_id", "fazendas", ["usuario_id"])

    op.create_table(
        "viveiros",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "usuario_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "fazenda_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("fazendas.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("nome", sa.String(160), nullable=False),
        sa.Column("area_ha", sa.Numeric(10, 3), nullable=False),
        sa.Column("densidade_padrao", sa.Numeric(8, 2), nullable=True),
        sa.Column("marca_racao", sa.String(120), nullable=True),
        sa.Column("data_povoamento", sa.Date(), nullable=True),
        sa.Column(
            "criado_em",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
    )
    op.create_index("ix_viveiros_usuario_id", "viveiros", ["usuario_id"])
    op.create_index("ix_viveiros_fazenda_id", "viveiros", ["fazenda_id"])

    op.create_table(
        "biometrias",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "usuario_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "viveiro_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("viveiros.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("data", sa.Date(), nullable=False),
        sa.Column("peso_amostra_kg", sa.Numeric(10, 4), nullable=False),
        sa.Column("n_amostrado", sa.Integer(), nullable=False),
        sa.Column("peso_medio", sa.Numeric(10, 2), nullable=True),
        sa.Column(
            "criado_em",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
    )
    op.create_index("ix_biometrias_usuario_id", "biometrias", ["usuario_id"])
    op.create_index("ix_biometrias_viveiro_id", "biometrias", ["viveiro_id"])
    op.create_index(
        "ix_biometrias_viveiro_data", "biometrias", ["viveiro_id", "data"]
    )

    op.create_table(
        "qualidade_agua",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "usuario_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "viveiro_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("viveiros.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("data", sa.Date(), nullable=False),
        sa.Column("od", sa.Numeric(6, 2), nullable=True),
        sa.Column("ph", sa.Numeric(4, 2), nullable=True),
        sa.Column("temperatura", sa.Numeric(5, 2), nullable=True),
        sa.Column("amonia", sa.Numeric(6, 3), nullable=True),
        sa.Column("nitrito", sa.Numeric(6, 3), nullable=True),
        sa.Column("alcalinidade", sa.Numeric(8, 2), nullable=True),
        sa.Column(
            "criado_em",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
    )
    op.create_index("ix_qualidade_agua_usuario_id", "qualidade_agua", ["usuario_id"])
    op.create_index("ix_qualidade_agua_viveiro_id", "qualidade_agua", ["viveiro_id"])
    op.create_index(
        "ix_qualidade_viveiro_data", "qualidade_agua", ["viveiro_id", "data"]
    )

    op.create_table(
        "calculos",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "usuario_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "viveiro_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("viveiros.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("tipo", sa.String(40), nullable=False),
        sa.Column("entradas", sa.JSON(), nullable=False),
        sa.Column("resultado", sa.JSON(), nullable=False),
        sa.Column(
            "criado_em",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
    )
    op.create_index("ix_calculos_usuario_id", "calculos", ["usuario_id"])
    op.create_index("ix_calculos_viveiro_id", "calculos", ["viveiro_id"])

    op.create_table(
        "visitas_tecnicas",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "usuario_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "fazenda_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("fazendas.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column(
            "produtor_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("data", sa.Date(), nullable=False),
        sa.Column("relatorio", sa.Text(), nullable=True),
        sa.Column("proxima_visita", sa.Date(), nullable=True),
        sa.Column(
            "criado_em",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
    )
    op.create_index("ix_visitas_tecnicas_usuario_id", "visitas_tecnicas", ["usuario_id"])
    op.create_index("ix_visitas_tecnicas_fazenda_id", "visitas_tecnicas", ["fazenda_id"])
    op.create_index("ix_visitas_tecnicas_produtor_id", "visitas_tecnicas", ["produtor_id"])


def downgrade() -> None:
    op.drop_table("visitas_tecnicas")
    op.drop_table("calculos")
    op.drop_table("qualidade_agua")
    op.drop_table("biometrias")
    op.drop_table("viveiros")
    op.drop_table("fazendas")
    op.drop_table("users")
    op.execute("DROP TYPE IF EXISTS user_role")
