# CARCINUTRI — Backend (FastAPI + PostgreSQL)

API própria de cadastro e login da plataforma CARCINUTRI, com dois perfis de
usuário: **produtor** e **técnico de campo**.

> O app Flutter continua **offline-first** (dados locais em sembast). O backend
> é responsável por cadastro/login/autenticação e já prepara o banco para uma
> futura sincronização de dados.

## Subir (Docker)

```bash
cd backend
docker compose up --build
```

- API: http://localhost:8000 (docs interativas em `/docs`)
- Postgres: localhost:5432 (usuário `postgres` / senha `postgres` / db `carcinutri`)

O compose sobe o Postgres, roda as migrações (Alembic) e inicia o uvicorn.

## Subir sem Docker (local no Windows)

Se não tiver Docker instalado, dá pra rodar direto com o PostgreSQL local:

```bash
cd backend

# 1. ambiente virtual + dependências
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt

# 2. configurar .env apontando para o Postgres local
copy .env.example .env
#   no .env, deixe ATIVA a linha com @localhost:5432:
#   DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/carcinutri

# 3. criar o banco (uma vez)
psql -U postgres -c "CREATE DATABASE carcinutri;"   # senha: postgres

# 4. rodar as migrações (cria as tabelas)
alembic upgrade head

# 5. subir a API
uvicorn app.main:app --reload --port 8000
```

Depois, o app Flutter:
```bash
cd ..                                  # volta para a raiz do projeto
flutter pub get
flutter run -d chrome                  # app web aponta para http://localhost:8000
# ou: flutter build web && python -m http.server 8080 -d build/web
```

## Testar a API

```bash
# Cadastrar um produtor
curl -X POST http://localhost:8000/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"email":"a@b.com","senha":"secret123","nome":"Ana","role":"produtor"}'

# Cadastrar um técnico
curl -X POST http://localhost:8000/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"email":"t@b.com","senha":"secret123","nome":"Tom","role":"tecnico"}'

# Login
curl -X POST http://localhost:8000/auth/login \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'username=a@b.com&password=secret123'

# Quem sou eu (Bearer token)
curl http://localhost:8000/auth/me -H "Authorization: Bearer SEU_TOKEN"

# Verificação de e-mail e recuperação de senha
# Confirmar e-mail (link enviado por e-mail / impresso no console em modo dev)
curl "http://localhost:8000/auth/verificar-email?token=SEU_TOKEN"

# Reenviar confirmação
curl -X POST http://localhost:8000/auth/reenviar-verificacao \
  -H 'Content-Type: application/json' -d '{"email":"a@b.com"}'

# Esqueci a senha (envia link de recuperação)
curl -X POST http://localhost:8000/auth/esqueci-senha \
  -H 'Content-Type: application/json' -d '{"email":"a@b.com"}'

# Redefinir senha com o token recebido
curl -X POST http://localhost:8000/auth/redefinir-senha \
  -H 'Content-Type: application/json' \
  -d '{"token":"SEU_TOKEN","nova_senha":"nova12345"}'
```

## E-mail (verificação + recuperação)

O envio usa a **API da Resend**. Configure no `.env`:
- `RESEND_API_KEY`: sua chave da Resend (plano gratuito).
- `EMAIL_FROM`: remetente (para testar sem domínio, use `onboarding@resend.dev`).
- `PUBLIC_BASE_URL`: base dos links nos e-mails (ex.: `http://localhost:8000`).

**Sem `RESEND_API_KEY`** o backend entra em **modo dev**: os links não são
enviados, são impressos no console do uvicorn — útil para testar o fluxo local.

## Rodar Alembic no host (fora do Docker)

```bash
# Use DATABASE_URL apontando para localhost no seu .env
alembic upgrade head
```

## Configuração

Copie `.env.example` para `.env` e ajuste. O `.env` é ignorado pelo git.
- `DATABASE_URL` dentro do container usa `@db:5432`; no host usa `@localhost:5432`.
- `JWT_SECRET`: troque por uma chave longa e aleatória em produção.
- `RESEND_API_KEY`/`EMAIL_FROM`/`PUBLIC_BASE_URL`: e-mail (ver seção acima).

## Estrutura

```
backend/
  app/
    main.py          # FastAPI + CORS + rotas
    config.py        # configuração (.env)
    database.py      # engine, sessão, Base
    models.py        # modelos SQLAlchemy
    schemas.py       # schemas Pydantic
    security.py      # hash bcrypt + JWT
    deps.py          # dependências (get_current_user)
    routers/
      auth.py        # /auth/register, /auth/login, /auth/me
      users.py       # /users (mínimo)
  alembic/           # migrações
```

## Nota: passlib + bcrypt

O `requirements.txt` fixa `bcrypt==4.0.1` para evitar o aviso de
incompatibilidade conhecido entre `passlib` e o `bcrypt` 4.1+.
