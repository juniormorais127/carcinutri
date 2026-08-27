from typing import Any, Type

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user
from ..models import (
    Biometria,
    Calculo,
    QualidadeAgua,
    ServicoSolicitacao,
    User,
    Viveiro,
)
from ..schemas import (
    BiometriaSync,
    CalculoSync,
    QualidadeAguaSync,
    ResultadoSync,
    ServicoSync,
    ViveiroSync,
)

router = APIRouter()


def _upsert_list(
    db: Session,
    model: Type[Any],
    itens: list[Any],
    usuario_id,
) -> int:
    """Upsert de uma lista de registros escopados ao usuário (offline-first).

    Cada registro chega com o UUID gerado no aparelho. Se já existe para este
    usuário, atualiza; senão cria. Nenhum registro alheio é tocado.
    """
    contagem = 0
    for item in itens:
        data = item.model_dump(exclude_unset=True)
        ident = data.pop("id")
        data.pop("criado_em", None)

        existente = db.get(model, ident)
        if existente is not None and existente.usuario_id == usuario_id:
            for campo, valor in data.items():
                setattr(existente, campo, valor)
        else:
            db.add(model(id=ident, usuario_id=usuario_id, **data))
        contagem += 1
    db.commit()
    return contagem


@router.post("/viveiros", response_model=ResultadoSync)
def sync_viveiros(
    itens: list[ViveiroSync], usuario: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    n = _upsert_list(db, Viveiro, itens, usuario.id)
    return ResultadoSync(recebidos=len(itens), sincronizados=n)


@router.post("/biometrias", response_model=ResultadoSync)
def sync_biometrias(
    itens: list[BiometriaSync], usuario: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    n = _upsert_list(db, Biometria, itens, usuario.id)
    return ResultadoSync(recebidos=len(itens), sincronizados=n)


@router.post("/qualidade-agua", response_model=ResultadoSync)
def sync_qualidade_agua(
    itens: list[QualidadeAguaSync], usuario: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    n = _upsert_list(db, QualidadeAgua, itens, usuario.id)
    return ResultadoSync(recebidos=len(itens), sincronizados=n)


@router.post("/calculos", response_model=ResultadoSync)
def sync_calculos(
    itens: list[CalculoSync], usuario: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    n = _upsert_list(db, Calculo, itens, usuario.id)
    return ResultadoSync(recebidos=len(itens), sincronizados=n)


@router.post("/servicos", response_model=ResultadoSync)
def sync_servicos(
    itens: list[ServicoSync],
    usuario: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Sincroniza solicitações criadas offline pelo produtor."""
    contagem = 0
    for item in itens:
        data = item.model_dump(exclude_unset=True)
        ident = data.pop("id")
        data.pop("criado_em", None)

        existente = db.get(ServicoSolicitacao, ident)
        if existente is not None and existente.produtor_id == usuario.id:
            for campo, valor in data.items():
                setattr(existente, campo, valor)
        elif existente is None:
            db.add(ServicoSolicitacao(id=ident, produtor_id=usuario.id, **data))
        contagem += 1
    db.commit()
    return ResultadoSync(recebidos=len(itens), sincronizados=contagem)

