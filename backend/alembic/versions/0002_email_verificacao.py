"""verificacao de email e recuperacao de senha

Revision ID: 0002_email_verificacao
Revises: 0001_initial
Create Date: 2026-08-27
"""
from alembic import op
import sqlalchemy as sa

revision = "0002_email_verificacao"
down_revision = "0001_initial"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("email_verificado", sa.Boolean(), nullable=False, server_default=sa.false()),
    )
    op.add_column("users", sa.Column("token_verificacao", sa.String(64), nullable=True))
    op.add_column("users", sa.Column("token_reset", sa.String(64), nullable=True))
    op.add_column(
        "users",
        sa.Column("token_reset_expira", sa.DateTime(timezone=True), nullable=True),
    )
    # Remove o default do servidor: quem insere no Python já define o valor.
    op.alter_column("users", "email_verificado", server_default=None)


def downgrade() -> None:
    op.drop_column("users", "token_reset_expira")
    op.drop_column("users", "token_reset")
    op.drop_column("users", "token_verificacao")
    op.drop_column("users", "email_verificado")
