"""Script idempotente para semear dados de demonstração."""
from sqlalchemy import select

from .database import SessionLocal
from .models import RoleEnum, ServicoSolicitacao, SolicitacaoStatus, User
from .security import hash_senha


def seed() -> None:
    db = SessionLocal()
    try:
        # Produtor Demo
        email = "demo@carcinutri.com"
        stmt = select(User).where(User.email == email)
        produtor = db.scalars(stmt).first()
        if not produtor:
            produtor = User(
                email=email,
                password_hash=hash_senha("demo123"),
                nome="Produtor Demo",
                telefone="(85) 99999-0001",
                cidade="Aracati",
                regiao="Litoral Leste",
                role=RoleEnum.produtor,
                email_verificado=True,
            )
            db.add(produtor)
            db.commit()
            db.refresh(produtor)
            print(f"Produtor demo criado: {email}")
        else:
            print(f"Produtor demo já existe: {email}")

        # Solicitação de exemplo
        sol_stmt = select(ServicoSolicitacao).where(
            ServicoSolicitacao.produtor_id == produtor.id,
            ServicoSolicitacao.titulo == "Manutenção no sistema de bombeamento",
        )
        solicitacao = db.scalars(sol_stmt).first()
        if not solicitacao:
            solicitacao = ServicoSolicitacao(
                produtor_id=produtor.id,
                titulo="Manutenção no sistema de bombeamento",
                descricao="Revisão preventiva e reparo nas bombas de captação e recirculação de água do setor A.",
                categoria="Manutenção",
                cidade="Aracati - CE",
                valor_estimado=1500.00,
                status=SolicitacaoStatus.aberto,
            )
            db.add(solicitacao)
            db.commit()
            print("Solicitação de serviço de exemplo criada.")
        else:
            print("Solicitação de serviço de exemplo já existe.")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
