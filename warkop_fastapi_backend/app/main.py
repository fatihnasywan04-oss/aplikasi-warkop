
import os

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, SessionLocal, engine
from app.models import User
from app.routers import admin, auth, public
from app.security import hash_password

load_dotenv()

app = FastAPI(
    title="Warkop Digital API",
    description="Backend aplikasi pemesanan Warkop Digital",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Membuat tabel yang belum ada.
# Catatan: create_all tidak menambahkan kolom ke tabel lama.
Base.metadata.create_all(bind=engine)


def create_default_admin():
    email = os.getenv(
        "ADMIN_EMAIL",
        "admin@warkop.com",
    ).strip().lower()

    password = os.getenv("ADMIN_PASSWORD")

    if not password:
        raise RuntimeError(
            "ADMIN_PASSWORD harus diatur di file .env"
        )

    db = SessionLocal()

    try:
        user = db.query(User).filter(User.email == email).first()

        if user is None:
            user = User(
                name="Administrator",
                email=email,
                password_hash=hash_password(password),
                role="admin",
                is_active=True,
            )
            db.add(user)
            db.commit()
    finally:
        db.close()


create_default_admin()

app.include_router(auth.router)
app.include_router(admin.router)
app.include_router(public.router)


@app.get("/")
def root():
    return {
        "message": "Warkop Digital API berjalan",
        "docs": "/docs",
    }


@app.get("/health")
def health():
    return {"status": "ok"}
