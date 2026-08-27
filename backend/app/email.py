"""Envio de e-mails (verificação de conta e recuperação de senha).

Usa a API da Resend quando `RESEND_API_KEY` está configurada no `.env`.
Sem chave, os links são impressos no console (modo dev) — nada é enviado.
Só stdlib (`urllib.request`), sem dependência nova.
"""
import json
import urllib.error
import urllib.request

from .config import settings

_RESEND_URL = "https://api.resend.com/emails"


def montar_link(caminho: str, token: str) -> str:
    """Ex.: montar_link('/auth/verificar-email', 'abc') -> http://...?token=abc"""
    return f"{settings.public_base_url.rstrip('/')}{caminho}?token={token}"


def _enviar_via_resend(destinatario: str, assunto: str, html: str) -> None:
    payload = json.dumps(
        {"from": settings.email_from, "to": [destinatario], "subject": assunto, "html": html}
    ).encode("utf-8")
    req = urllib.request.Request(
        _RESEND_URL,
        data=payload,
        method="POST",
        headers={
            "Authorization": f"Bearer {settings.resend_api_key}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            resp.read()
    except urllib.error.HTTPError as e:
        corpo = e.read().decode("utf-8", "replace")
        raise RuntimeError(f"Resend HTTP {e.code}: {corpo}") from e


def enviar_email(destinatario: str, assunto: str, html: str) -> None:
    """Envia um e-mail; sem RESEND_API_KEY, apenas loga no console (modo dev)."""
    if settings.resend_api_key:
        _enviar_via_resend(destinatario, assunto, html)
        return
    # Modo dev: imprime o conteúdo no terminal do backend.
    print("\n" + "=" * 60)
    print(f"[CARCINUTRI e-mail][{assunto}] -> {destinatario}")
    print("-" * 60)
    print(html)
    print("=" * 60 + "\n")
