from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import settings
from .routers import auth, servicos, sync, users

app = FastAPI(title="CARCINUTRI API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(users.router, prefix="/users", tags=["users"])
app.include_router(sync.router, prefix="/sync", tags=["sync"])
app.include_router(servicos.router, tags=["servicos"])


@app.get("/health")
def health():
    return {"status": "ok"}
