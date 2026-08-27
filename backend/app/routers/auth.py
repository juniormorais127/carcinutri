import json
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import HTMLResponse
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user
from ..email import enviar_email, montar_link
from ..models import User
from ..schemas import EmailRequest, RedefinirSenha, Token, UserCreate, UserOut
from ..security import criar_access_token, criar_token, hash_senha, verificar_senha

router = APIRouter()


def _html(titulo: str, corpo: str) -> HTMLResponse:
    html = f"""<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{titulo}</title>
<style>
  body {{ font-family: system-ui, Segoe UI, Roboto, sans-serif;
         background:#f4f8f5; margin:0; display:grid; place-items:center;
         min-height:100vh; color:#1b3a2b; }}
  .card {{ background:#fff; padding:40px; border-radius:16px;
          box-shadow:0 8px 30px rgba(0,0,0,.08); max-width:420px; width:92%;
          text-align:center; }}
  .icone {{ font-size:44px; }}
  h1 {{ font-size:22px; margin:12px 0 8px; }}
  p {{ color:#4b6a58; line-height:1.5; }}
  .erro {{ color:#b3261e; }}
</style></head><body><div class="card">{corpo}</div></body></html>"""
    return HTMLResponse(content=html)


# ---------------------------------------------------------------------------
# Cadastro (com verificação de e-mail) e login
# ---------------------------------------------------------------------------


@router.post("/register", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def registrar(dados: UserCreate, db: Session = Depends(get_db)):
    email = dados.email.lower()
    existente = db.scalar(select(User).where(User.email == email))
    if existente:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Já existe uma conta com este email",
        )

    token = criar_token()
    user = User(
        email=email,
        password_hash=hash_senha(dados.senha),
        nome=dados.nome,
        telefone=dados.telefone,
        cidade=dados.cidade,
        regiao=dados.regiao,
        role=dados.role,
        perfil=dados.perfil,
        email_verificado=False,
        token_verificacao=token,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    link = montar_link("/auth/verificar-email", token)
    corpo_email = (
        f"<p>Olá, <strong>{dados.nome}</strong>!</p>"
        f"<p>Confirme seu e-mail clicando no botão abaixo para ativar sua conta "
        f"na CARCINUTRI.</p>"
        f'<p style="text-align:center;margin:24px 0">'
        f'<a href="{link}" style="background:#2e7d5b;color:#fff;padding:12px 24px;'
        f'border-radius:8px;text-decoration:none;font-weight:600">'
        f"CONFIRMAR E-MAIL</a></p>"
        f'<p style="font-size:13px;color:#6b7f73">Ou abra o link: <br>'
        f'<a href="{link}" style="color:#2e7d5b">{link}</a></p>'
    )
    enviar_email(email, "Carcinutri — confirme seu e-mail", corpo_email)

    return user


@router.post("/login", response_model=Token)
def login(
    form: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)
):
    email = form.username.lower()
    user = db.scalar(select(User).where(User.email == email))
    if not user or not verificar_senha(form.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email ou senha incorretos",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = criar_access_token(subject=str(user.id), role=user.role.value)
    return Token(access_token=token, user=UserOut.model_validate(user))


@router.get("/me", response_model=UserOut)
def me(usuario: User = Depends(get_current_user)):
    return usuario


# ---------------------------------------------------------------------------
# Verificação de e-mail
# ---------------------------------------------------------------------------


@router.get("/verificar-email", response_class=HTMLResponse)
def verificar_email(token: str, db: Session = Depends(get_db)):
    user = db.scalar(select(User).where(User.token_verificacao == token))
    if not user:
        return _html(
            "Link inválido",
            '<div class="icone">⚠️</div><h1>Link inválido ou já usado</h1>'
            "<p>Solicite um novo e-mail de confirmação no app.</p>",
        )
    user.email_verificado = True
    user.token_verificacao = None
    db.commit()
    return _html(
        "E-mail confirmado",
        '<div class="icone">✅</div><h1>E-mail confirmado!</h1>'
        "<p>Sua conta CARCINUTRI está ativa. Você já pode entrar no app.</p>",
    )


@router.post("/reenviar-verificacao")
def reenviar_verificacao(
    dados: EmailRequest, db: Session = Depends(get_db)
):
    email = dados.email.lower()
    user = db.scalar(select(User).where(User.email == email))
    # Não revela se o e-mail existe; responde sempre com sucesso.
    if user and not user.email_verificado:
        user.token_verificacao = criar_token()
        db.commit()
        db.refresh(user)
        link = montar_link("/auth/verificar-email", user.token_verificacao)
        corpo_email = (
            f"<p>Olá, <strong>{user.nome}</strong>!</p>"
            f"<p>Confirme seu e-mail clicando no botão abaixo.</p>"
            f'<p style="text-align:center;margin:24px 0">'
            f'<a href="{link}" style="background:#2e7d5b;color:#fff;padding:12px 24px;'
            f'border-radius:8px;text-decoration:none;font-weight:600">'
            f"CONFIRMAR E-MAIL</a></p>"
            f'<p style="font-size:13px;color:#6b7f73"><a href="{link}" '
            f'style="color:#2e7d5b">{link}</a></p>'
        )
        enviar_email(email, "Carcinutri — confirme seu e-mail", corpo_email)
    return {"message": "Se o e-mail existir, uma nova confirmação foi enviada."}


# ---------------------------------------------------------------------------
# Esqueci senha / redefinir senha
# ---------------------------------------------------------------------------


@router.post("/esqueci-senha")
def esqueci_senha(dados: EmailRequest, db: Session = Depends(get_db)):
    email = dados.email.lower()
    user = db.scalar(select(User).where(User.email == email))
    # Não revela se o e-mail existe; responde sempre com sucesso.
    if user:
        user.token_reset = criar_token()
        user.token_reset_expira = datetime.now(timezone.utc) + timedelta(hours=1)
        db.commit()
        db.refresh(user)
        link = montar_link("/auth/redefinir-senha", user.token_reset)
        corpo_email = (
            f"<p>Olá, <strong>{user.nome}</strong>!</p>"
            f"<p>Recebemos um pedido para redefinir sua senha. Clique no botão "
            f"para criar uma nova. Este link expira em <strong>1 hora</strong>.</p>"
            f'<p style="text-align:center;margin:24px 0">'
            f'<a href="{link}" style="background:#2e7d5b;color:#fff;padding:12px 24px;'
            f'border-radius:8px;text-decoration:none;font-weight:600">'
            f"REDEFINIR SENHA</a></p>"
            f'<p style="font-size:13px;color:#6b7f73"><a href="{link}" '
            f'style="color:#2e7d5b">{link}</a></p>'
        )
        enviar_email(email, "Carcinutri — redefinir senha", corpo_email)
    return {"message": "Se o e-mail existir, um link de recuperação foi enviado."}


@router.post("/redefinir-senha")
def redefinir_senha(dados: RedefinirSenha, db: Session = Depends(get_db)):
    user = db.scalar(select(User).where(User.token_reset == dados.token))
    if not user:
        raise HTTPException(status_code=400, detail="Link inválido ou já usado.")
    if user.token_reset_expira and user.token_reset_expira < datetime.now(timezone.utc):
        raise HTTPException(status_code=400, detail="Este link expirou. Solicite um novo.")
    user.password_hash = hash_senha(dados.nova_senha)
    user.token_reset = None
    user.token_reset_expira = None
    db.commit()
    return {"message": "Senha redefinida com sucesso."}


@router.get("/redefinir-senha", response_class=HTMLResponse)
def pagina_redefinir_senha(token: str):
    # Página simples (web / navegador do celular): envia a nova senha via fetch
    # e mostra o resultado.
    return _html(
        "Redefinir senha",
        '<div class="icone">🔑</div><h1>Nova senha</h1>'
        f'<input type="password" id="senha" placeholder="Nova senha (mín. 6)" '
        f'style="width:100%;padding:12px;border:1px solid #c6d6cc;'
        f'border-radius:8px;margin:8px 0" />'
        f'<input type="password" id="senha2" placeholder="Confirmar senha" '
        f'style="width:100%;padding:12px;border:1px solid #c6d6cc;'
        f'border-radius:8px;margin:8px 0" />'
        f'<button onclick="enviar()" style="width:100%;background:#2e7d5b;'
        f'color:#fff;border:0;padding:14px;border-radius:8px;'
        f'font-weight:600;font-size:16px;margin-top:8px;cursor:pointer">'
        f"Salvar nova senha</button>"
        f'<p id="msg" style="margin-top:16px"></p>'
        f"<script>"
        f'async function enviar() {{'
        f'  const s = document.getElementById("senha").value;'
        f'  const s2 = document.getElementById("senha2").value;'
        f'  const msg = document.getElementById("msg");'
        f'  if (s.length < 6) {{ msg.textContent = "Mínimo 6 caracteres."; return; }}'
        f'  if (s !== s2) {{ msg.textContent = "As senhas não coincidem."; return; }}'
        f'  const r = await fetch("/auth/redefinir-senha", {{'
        f'    method: "POST",'
        f'    headers: {{"Content-Type": "application/json"}},'
        f'    body: JSON.stringify({{token: {json.dumps(token)}, nova_senha: s}})'
        f'  }});'
        f'  const j = await r.json().catch(() => ({{}}));'
        f'  if (r.ok) {{'
        f'    msg.style.color = "#2e7d5b";'
        f'    msg.textContent = "Senha redefinida! Você já pode entrar no app.";'
        f'  }} else {{'
        f'    msg.style.color = "#b3261e";'
        f'    msg.textContent = j.detail || "Erro ao redefinir a senha.";'
        f'  }}'
        f'}}</script>',
    )
