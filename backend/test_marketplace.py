"""Testes de integração do fluxo do marketplace e custódia."""
import sys
from fastapi.testclient import TestClient
from app.main import app
from app.database import SessionLocal
from app.models import User, RoleEnum
from app.security import hash_senha

client = TestClient(app)

def run_tests():
    # 1. Login com produtor demo
    resp = client.post(
        "/auth/login",
        data={"username": "demo@carcinutri.com", "password": "demo123"},
    )
    assert resp.status_code == 200, f"Login produtor falhou: {resp.text}"
    produtor_token = resp.json()["access_token"]
    produtor_headers = {"Authorization": f"Bearer {produtor_token}"}

    # 2. Criar ou autenticar técnico de teste
    db = SessionLocal()
    tec = db.query(User).filter(User.email == "tecnico.demo@carcinutri.com").first()
    if not tec:
        tec = User(
            email="tecnico.demo@carcinutri.com",
            password_hash=hash_senha("demo123"),
            nome="Tecnico Teste",
            role=RoleEnum.tecnico,
            email_verificado=True,
        )
        db.add(tec)
        db.commit()
    db.close()

    resp = client.post(
        "/auth/login",
        data={"username": "tecnico.demo@carcinutri.com", "password": "demo123"},
    )
    assert resp.status_code == 200, f"Login tecnico falhou: {resp.text}"
    tecnico_token = resp.json()["access_token"]
    tecnico_headers = {"Authorization": f"Bearer {tecnico_token}"}

    # 3. Listar serviços abertos (como técnico)
    resp = client.get("/servicos", headers=tecnico_headers)
    assert resp.status_code == 200, resp.text
    servicos = resp.json()
    assert len(servicos) > 0, "Deveria ter pelo menos o servico demo"
    servico_demo = servicos[0]
    servico_id = servico_demo["id"]
    print("[OK] Listagem de servicos abertos")

    # 4. Listar minhas solicitações (como produtor)
    resp = client.get("/servicos/meus", headers=produtor_headers)
    assert resp.status_code == 200
    meus = resp.json()
    assert any(s["id"] == servico_id for s in meus)
    print("[OK] Listar /servicos/meus")

    # 5. Produtor tenta criar proposta -> deve retornar 403
    resp = client.post(
        f"/servicos/{servico_id}/propostas",
        headers=produtor_headers,
        json={"valor": 1200.0, "mensagem": "Sou produtor querendo propor"},
    )
    assert resp.status_code == 403, f"Produtor nao pode propor: {resp.status_code}"
    print("[OK] Permissao: Produtor bloqueado de criar proposta")

    # 6. Técnico cria proposta
    resp = client.post(
        f"/servicos/{servico_id}/propostas",
        headers=tecnico_headers,
        json={"valor": 1350.0, "mensagem": "Consigo realizar a manutencao amanha."},
    )
    assert resp.status_code in (200, 201), resp.text
    proposta = resp.json()
    proposta_id = proposta["id"]
    assert proposta["valor"] == 1350.0
    assert proposta["status"] == "pendente"
    print("[OK] Tecnico criou proposta")

    # 7. Produtor visualiza propostas do seu serviço
    resp = client.get(f"/servicos/{servico_id}/propostas", headers=produtor_headers)
    assert resp.status_code == 200
    propostas = resp.json()
    assert any(p["id"] == proposta_id for p in propostas)
    print("[OK] Produtor visualizou propostas")

    # 8. Produtor aceita a proposta -> Contrato criado
    resp = client.post(
        f"/servicos/{servico_id}/propostas/{proposta_id}/aceitar",
        headers=produtor_headers,
    )
    assert resp.status_code == 200, resp.text
    contrato = resp.json()
    contrato_id = contrato["id"]
    assert contrato["pagamento"] == "aguardando"
    assert contrato["execucao"] == "aguardando_pagamento"
    assert contrato["comunicacao_liberada"] is False
    print("[OK] Produtor aceitou proposta -> Contrato gerado")

    # 9. Chat bloqueado antes do pagamento (403)
    resp = client.get(f"/contratos/{contrato_id}/mensagens", headers=produtor_headers)
    assert resp.status_code == 403, f"Esperava 403 mas veio: {resp.status_code}"
    resp = client.post(
        f"/contratos/{contrato_id}/mensagens",
        headers=produtor_headers,
        json={"texto": "Ola tecnico"},
    )
    assert resp.status_code == 403
    print("[OK] Chat bloqueado antes do pagamento em custodia (403)")

    # 10. Produtor efetua pagamento simulado (custódia mock)
    resp = client.post(f"/contratos/{contrato_id}/pagar", headers=produtor_headers)
    assert resp.status_code == 200, resp.text
    contrato = resp.json()
    assert contrato["pagamento"] == "pago"
    assert contrato["execucao"] == "em_andamento"
    assert contrato["comunicacao_liberada"] is True
    print("[OK] Pagamento efetuado (custodia mock)")

    # 11. Chat liberado pós-pagamento! Envio e recebimento
    resp = client.post(
        f"/contratos/{contrato_id}/mensagens",
        headers=produtor_headers,
        json={"texto": "Ola, pagamento em custodia confirmado! Pode vir."},
    )
    assert resp.status_code == 201, resp.text
    msg = resp.json()
    assert msg["texto"] == "Ola, pagamento em custodia confirmado! Pode vir."

    resp = client.post(
        f"/contratos/{contrato_id}/mensagens",
        headers=tecnico_headers,
        json={"texto": "Perfeito! Ja estou a caminho com os equipamentos."},
    )
    assert resp.status_code == 201, resp.text

    resp = client.get(f"/contratos/{contrato_id}/mensagens", headers=tecnico_headers)
    assert resp.status_code == 200
    msgs = resp.json()
    assert len(msgs) == 2
    print("[OK] Chat pos-pagamento (envio e listagem de mensagens)")

    # 12. Técnico finaliza serviço
    resp = client.post(f"/contratos/{contrato_id}/finalizar", headers=tecnico_headers)
    assert resp.status_code == 200, resp.text
    contrato = resp.json()
    assert contrato["execucao"] == "aguardando_aprovacao"
    print("[OK] Tecnico finalizou execucao")

    # 13. Produtor aprova serviço -> pagamento repassado e concluído
    resp = client.post(f"/contratos/{contrato_id}/aprovar", headers=produtor_headers)
    assert resp.status_code == 200, resp.text
    contrato = resp.json()
    assert contrato["pagamento"] == "repassado"
    assert contrato["execucao"] == "concluido"
    print("[OK] Produtor aprovou conclusao -> pagamento repassado")

    # 14. Testar sync offline de novas solicitações
    import uuid
    novo_id = str(uuid.uuid4())
    sync_payload = [
        {
            "id": novo_id,
            "titulo": "Instalacao de aeradores",
            "descricao": "Instalar 4 novos aeradores no viveiro 2",
            "categoria": "Instalacao",
            "cidade": "Aracati",
            "valor_estimado": 800.0,
            "status": "aberto",
        }
    ]
    resp = client.post("/sync/servicos", headers=produtor_headers, json=sync_payload)
    assert resp.status_code == 200, resp.text
    assert resp.json()["sincronizados"] == 1

    resp = client.get("/servicos", headers=tecnico_headers)
    assert resp.status_code == 200
    assert any(s["id"] == novo_id for s in resp.json())
    print("[OK] Sincronizacao offline-first de solicitacoes")

    print("\nTODOS OS TESTES DO BACKEND PASSARAM COM SUCESSO!")

if __name__ == "__main__":
    run_tests()
