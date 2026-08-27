from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import or_, select
from sqlalchemy.orm import Session, joinedload

from ..database import get_db
from ..deps import get_current_user, requer_role
from ..models import (
    ContratoServico,
    ExecucaoStatus,
    PagamentoStatus,
    PropostaStatus,
    RoleEnum,
    ServicoMensagem,
    ServicoProposta,
    ServicoSolicitacao,
    SolicitacaoStatus,
    User,
)
from ..schemas import (
    ContratoOut,
    MensagemCreate,
    MensagemOut,
    PropostaCreate,
    PropostaOut,
    ServicoOut,
    ServicoSolicitacaoCreate,
)

router = APIRouter()


def _servico_out(s: ServicoSolicitacao) -> ServicoOut:
    return ServicoOut(
        id=s.id,
        produtor_id=s.produtor_id,
        produtor_nome=s.produtor.nome if s.produtor else "",
        titulo=s.titulo,
        descricao=s.descricao,
        categoria=s.categoria,
        cidade=s.cidade,
        valor_estimado=float(s.valor_estimado),
        status=s.status,
        criado_em=s.criado_em,
    )


def _proposta_out(p: ServicoProposta) -> PropostaOut:
    return PropostaOut(
        id=p.id,
        servico_id=p.servico_id,
        tecnico_id=p.tecnico_id,
        tecnico_nome=p.tecnico.nome if p.tecnico else "",
        valor=float(p.valor),
        mensagem=p.mensagem,
        status=p.status,
        criado_em=p.criado_em,
    )


def _contrato_out(c: ContratoServico) -> ContratoOut:
    liberada = c.pagamento in (PagamentoStatus.pago, PagamentoStatus.repassado)
    return ContratoOut(
        id=c.id,
        servico_id=c.servico_id,
        servico_titulo=c.servico.titulo if c.servico else "",
        produtor_id=c.produtor_id,
        produtor_nome=c.produtor.nome if c.produtor else "",
        tecnico_id=c.tecnico_id,
        tecnico_nome=c.tecnico.nome if c.tecnico else "",
        valor_acordado=float(c.valor_acordado),
        pagamento=c.pagamento,
        execucao=c.execucao,
        comunicacao_liberada=liberada,
        criado_em=c.criado_em,
    )


def _mensagem_out(m: ServicoMensagem) -> MensagemOut:
    return MensagemOut(
        id=m.id,
        contrato_id=m.contrato_id,
        remetente_id=m.remetente_id,
        remetente_nome=m.remetente.nome if m.remetente else "",
        texto=m.texto,
        criado_em=m.criado_em,
    )


# ---------------------------------------------------------------------------
# Marketplace: Solicitações de Serviços
# ---------------------------------------------------------------------------


@router.get("/servicos", response_model=list[ServicoOut])
def listar_servicos_abertos(
    categoria: Optional[str] = None,
    cidade: Optional[str] = None,
    usuario: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Lista todas as solicitações abertas no marketplace (pública para técnicos e produtores)."""
    stmt = (
        select(ServicoSolicitacao)
        .options(joinedload(ServicoSolicitacao.produtor))
        .where(ServicoSolicitacao.status == SolicitacaoStatus.aberto)
    )
    if categoria:
        stmt = stmt.where(ServicoSolicitacao.categoria == categoria)
    if cidade:
        stmt = stmt.where(ServicoSolicitacao.cidade == cidade)
    stmt = stmt.order_by(ServicoSolicitacao.criado_em.desc())

    itens = db.scalars(stmt).all()
    return [_servico_out(s) for s in itens]


@router.get("/servicos/meus", response_model=list[ServicoOut])
def listar_minhas_solicitacoes(
    usuario: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Lista as solicitações criadas pelo usuário logado."""
    stmt = (
        select(ServicoSolicitacao)
        .options(joinedload(ServicoSolicitacao.produtor))
        .where(ServicoSolicitacao.produtor_id == usuario.id)
        .order_by(ServicoSolicitacao.criado_em.desc())
    )
    itens = db.scalars(stmt).all()
    return [_servico_out(s) for s in itens]


@router.post("/servicos", response_model=ServicoOut, status_code=status.HTTP_201_CREATED)
def criar_solicitacao(
    payload: ServicoSolicitacaoCreate,
    usuario: User = Depends(requer_role(RoleEnum.produtor)),
    db: Session = Depends(get_db),
):
    """Cria uma nova solicitação de serviço (apenas produtores)."""
    solicitacao = ServicoSolicitacao(
        produtor_id=usuario.id,
        titulo=payload.titulo,
        descricao=payload.descricao,
        categoria=payload.categoria,
        cidade=payload.cidade,
        valor_estimado=payload.valor_estimado,
        status=SolicitacaoStatus.aberto,
    )
    db.add(solicitacao)
    db.commit()
    db.refresh(solicitacao)
    return _servico_out(solicitacao)


@router.get("/servicos/{servico_id}", response_model=ServicoOut)
def obter_servico(
    servico_id: UUID,
    usuario: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Detalhes de uma solicitação de serviço."""
    stmt = (
        select(ServicoSolicitacao)
        .options(joinedload(ServicoSolicitacao.produtor))
        .where(ServicoSolicitacao.id == servico_id)
    )
    servico = db.scalars(stmt).first()
    if not servico:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Solicitação de serviço não encontrada",
        )
    return _servico_out(servico)


@router.get("/servicos/{servico_id}/propostas", response_model=list[PropostaOut])
def listar_propostas_servico(
    servico_id: UUID,
    usuario: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Lista as propostas de uma solicitação."""
    servico = db.get(ServicoSolicitacao, servico_id)
    if not servico:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Solicitação de serviço não encontrada",
        )

    stmt = (
        select(ServicoProposta)
        .options(joinedload(ServicoProposta.tecnico))
        .where(ServicoProposta.servico_id == servico_id)
    )
    # Se for técnico e não for o produtor dono, vê apenas a sua própria proposta
    if usuario.role == RoleEnum.tecnico and servico.produtor_id != usuario.id:
        stmt = stmt.where(ServicoProposta.tecnico_id == usuario.id)

    stmt = stmt.order_by(ServicoProposta.criado_em.desc())
    itens = db.scalars(stmt).all()
    return [_proposta_out(p) for p in itens]


@router.post(
    "/servicos/{servico_id}/propostas",
    response_model=PropostaOut,
    status_code=status.HTTP_201_CREATED,
)
def criar_proposta(
    servico_id: UUID,
    payload: PropostaCreate,
    usuario: User = Depends(requer_role(RoleEnum.tecnico)),
    db: Session = Depends(get_db),
):
    """Cria uma contraproposta para uma solicitação aberta (apenas técnicos)."""
    servico = db.get(ServicoSolicitacao, servico_id)
    if not servico:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Solicitação de serviço não encontrada",
        )
    if servico.status != SolicitacaoStatus.aberto:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Esta solicitação não está aberta para propostas",
        )

    # Verifica se já existe proposta pendente deste técnico
    stmt = select(ServicoProposta).where(
        ServicoProposta.servico_id == servico_id,
        ServicoProposta.tecnico_id == usuario.id,
        ServicoProposta.status == PropostaStatus.pendente,
    )
    existente = db.scalars(stmt).first()
    if existente:
        existente.valor = payload.valor
        existente.mensagem = payload.mensagem
        db.commit()
        db.refresh(existente)
        return _proposta_out(existente)

    proposta = ServicoProposta(
        servico_id=servico_id,
        tecnico_id=usuario.id,
        valor=payload.valor,
        mensagem=payload.mensagem,
        status=PropostaStatus.pendente,
    )
    db.add(proposta)
    db.commit()
    db.refresh(proposta)
    return _proposta_out(proposta)


@router.post(
    "/servicos/{servico_id}/propostas/{proposta_id}/aceitar",
    response_model=ContratoOut,
)
def aceitar_proposta(
    servico_id: UUID,
    proposta_id: UUID,
    usuario: User = Depends(requer_role(RoleEnum.produtor)),
    db: Session = Depends(get_db),
):
    """O produtor dono da solicitação aceita a proposta -> cria o contrato com custódia."""
    servico = db.get(ServicoSolicitacao, servico_id)
    if not servico:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Solicitação de serviço não encontrada",
        )
    if servico.produtor_id != usuario.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Apenas o produtor responsável pode aceitar propostas para este serviço",
        )
    if servico.status != SolicitacaoStatus.aberto:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Esta solicitação não está mais aberta",
        )

    proposta = db.get(ServicoProposta, proposta_id)
    if not proposta or proposta.servico_id != servico_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Proposta não encontrada para esta solicitação",
        )
    if proposta.status != PropostaStatus.pendente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Esta proposta não está pendente",
        )

    # 1. Atualiza a proposta aceita
    proposta.status = PropostaStatus.aceita

    # 2. Recusa as demais propostas da solicitação
    outras_stmt = select(ServicoProposta).where(
        ServicoProposta.servico_id == servico_id,
        ServicoProposta.id != proposta_id,
        ServicoProposta.status == PropostaStatus.pendente,
    )
    for p in db.scalars(outras_stmt).all():
        p.status = PropostaStatus.recusada

    # 3. Atualiza o status da solicitação
    servico.status = SolicitacaoStatus.aceito

    # 4. Cria o contrato com status aguardando pagamento
    contrato = ContratoServico(
        servico_id=servico.id,
        proposta_id=proposta.id,
        produtor_id=usuario.id,
        tecnico_id=proposta.tecnico_id,
        valor_acordado=proposta.valor,
        pagamento=PagamentoStatus.aguardando,
        execucao=ExecucaoStatus.aguardando_pagamento,
    )
    db.add(contrato)
    db.commit()
    db.refresh(contrato)

    return _contrato_out(contrato)


# ---------------------------------------------------------------------------
# Contratos e Custódia (Escrow)
# ---------------------------------------------------------------------------


@router.get("/contratos/meus", response_model=list[ContratoOut])
def listar_meus_contratos(
    usuario: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Lista todos os contratos onde o usuário é produtor ou técnico."""
    stmt = (
        select(ContratoServico)
        .options(
            joinedload(ContratoServico.servico),
            joinedload(ContratoServico.produtor),
            joinedload(ContratoServico.tecnico),
        )
        .where(
            or_(
                ContratoServico.produtor_id == usuario.id,
                ContratoServico.tecnico_id == usuario.id,
            )
        )
        .order_by(ContratoServico.criado_em.desc())
    )
    itens = db.scalars(stmt).all()
    return [_contrato_out(c) for c in itens]


@router.get("/contratos/{contrato_id}", response_model=ContratoOut)
def obter_contrato(
    contrato_id: UUID,
    usuario: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Detalhes de um contrato."""
    stmt = (
        select(ContratoServico)
        .options(
            joinedload(ContratoServico.servico),
            joinedload(ContratoServico.produtor),
            joinedload(ContratoServico.tecnico),
        )
        .where(ContratoServico.id == contrato_id)
    )
    contrato = db.scalars(stmt).first()
    if not contrato:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contrato não encontrado",
        )
    if contrato.produtor_id != usuario.id and contrato.tecnico_id != usuario.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acesso não autorizado a este contrato",
        )
    return _contrato_out(contrato)


@router.post("/contratos/{contrato_id}/pagar", response_model=ContratoOut)
def pagar_contrato(
    contrato_id: UUID,
    usuario: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Simulação de pagamento pelo produtor (coloca o valor em custódia e libera o chat)."""
    stmt = (
        select(ContratoServico)
        .options(
            joinedload(ContratoServico.servico),
            joinedload(ContratoServico.produtor),
            joinedload(ContratoServico.tecnico),
        )
        .where(ContratoServico.id == contrato_id)
    )
    contrato = db.scalars(stmt).first()
    if not contrato:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contrato não encontrado",
        )
    if contrato.produtor_id != usuario.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Apenas o produtor pode efetuar o pagamento",
        )
    if contrato.pagamento != PagamentoStatus.aguardando:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="O pagamento já foi processado anteriormente",
        )

    contrato.pagamento = PagamentoStatus.pago
    contrato.execucao = ExecucaoStatus.em_andamento
    db.commit()
    db.refresh(contrato)
    return _contrato_out(contrato)


@router.post("/contratos/{contrato_id}/finalizar", response_model=ContratoOut)
def finalizar_servico(
    contrato_id: UUID,
    usuario: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """O técnico marca a execução do serviço como concluída, aguardando aprovação do produtor."""
    stmt = (
        select(ContratoServico)
        .options(
            joinedload(ContratoServico.servico),
            joinedload(ContratoServico.produtor),
            joinedload(ContratoServico.tecnico),
        )
        .where(ContratoServico.id == contrato_id)
    )
    contrato = db.scalars(stmt).first()
    if not contrato:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contrato não encontrado",
        )
    if contrato.tecnico_id != usuario.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Apenas o técnico responsável pode finalizar o serviço",
        )
    if contrato.execucao != ExecucaoStatus.em_andamento:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="O serviço não está em andamento",
        )

    contrato.execucao = ExecucaoStatus.aguardando_aprovacao
    db.commit()
    db.refresh(contrato)
    return _contrato_out(contrato)


@router.post("/contratos/{contrato_id}/aprovar", response_model=ContratoOut)
def aprovar_servico(
    contrato_id: UUID,
    usuario: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """O produtor aprova o serviço concluído -> repassa o pagamento ao técnico."""
    stmt = (
        select(ContratoServico)
        .options(
            joinedload(ContratoServico.servico),
            joinedload(ContratoServico.produtor),
            joinedload(ContratoServico.tecnico),
        )
        .where(ContratoServico.id == contrato_id)
    )
    contrato = db.scalars(stmt).first()
    if not contrato:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contrato não encontrado",
        )
    if contrato.produtor_id != usuario.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Apenas o produtor contratante pode aprovar o serviço",
        )
    if contrato.execucao != ExecucaoStatus.aguardando_aprovacao:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="O serviço não está aguardando aprovação",
        )

    contrato.pagamento = PagamentoStatus.repassado
    contrato.execucao = ExecucaoStatus.concluido
    db.commit()
    db.refresh(contrato)
    return _contrato_out(contrato)


@router.post("/contratos/{contrato_id}/rejeitar", response_model=ContratoOut)
def rejeitar_servico(
    contrato_id: UUID,
    usuario: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """O produtor rejeita o serviço -> cancela o contrato e restitui o valor."""
    stmt = (
        select(ContratoServico)
        .options(
            joinedload(ContratoServico.servico),
            joinedload(ContratoServico.produtor),
            joinedload(ContratoServico.tecnico),
        )
        .where(ContratoServico.id == contrato_id)
    )
    contrato = db.scalars(stmt).first()
    if not contrato:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contrato não encontrado",
        )
    if contrato.produtor_id != usuario.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Apenas o produtor contratante pode rejeitar o serviço",
        )
    if contrato.execucao not in (
        ExecucaoStatus.aguardando_aprovacao,
        ExecucaoStatus.em_andamento,
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="O serviço não pode ser rejeitado neste estado",
        )

    contrato.pagamento = PagamentoStatus.restituido
    contrato.execucao = ExecucaoStatus.cancelado
    db.commit()
    db.refresh(contrato)
    return _contrato_out(contrato)


# ---------------------------------------------------------------------------
# Chat entre Produtor e Técnico (Liberado pós-pagamento)
# ---------------------------------------------------------------------------


@router.get("/contratos/{contrato_id}/mensagens", response_model=list[MensagemOut])
def listar_mensagens(
    contrato_id: UUID,
    usuario: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Lista mensagens do chat do contrato. Exige pagamento em custódia efetuado."""
    contrato = db.get(ContratoServico, contrato_id)
    if not contrato:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contrato não encontrado",
        )
    if contrato.produtor_id != usuario.id and contrato.tecnico_id != usuario.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acesso não autorizado a este chat",
        )
    if contrato.pagamento not in (PagamentoStatus.pago, PagamentoStatus.repassado):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Chat liberado apenas após a confirmação do pagamento em custódia",
        )

    stmt = (
        select(ServicoMensagem)
        .options(joinedload(ServicoMensagem.remetente))
        .where(ServicoMensagem.contrato_id == contrato_id)
        .order_by(ServicoMensagem.criado_em.asc())
    )
    itens = db.scalars(stmt).all()
    return [_mensagem_out(m) for m in itens]


@router.post(
    "/contratos/{contrato_id}/mensagens",
    response_model=MensagemOut,
    status_code=status.HTTP_201_CREATED,
)
def enviar_mensagem(
    contrato_id: UUID,
    payload: MensagemCreate,
    usuario: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Envia uma mensagem no chat do contrato. Exige pagamento em custódia efetuado."""
    contrato = db.get(ContratoServico, contrato_id)
    if not contrato:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contrato não encontrado",
        )
    if contrato.produtor_id != usuario.id and contrato.tecnico_id != usuario.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acesso não autorizado a este chat",
        )
    if contrato.pagamento not in (PagamentoStatus.pago, PagamentoStatus.repassado):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Chat liberado apenas após a confirmação do pagamento em custódia",
        )

    msg = ServicoMensagem(
        contrato_id=contrato_id,
        remetente_id=usuario.id,
        texto=payload.texto,
    )
    db.add(msg)
    db.commit()
    db.refresh(msg)
    msg.remetente = usuario
    return _mensagem_out(msg)
