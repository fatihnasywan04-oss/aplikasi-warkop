from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Category, Menu, Order, OrderItem, User
from app.routers.auth import require_admin
from app.schemas import (
    CategoryCreate,
    CategoryResponse,
    MenuCreate,
    MenuResponse,
    OrderResponse,
)

router = APIRouter(
    prefix="/api/admin",
    tags=["Admin"],
    dependencies=[Depends(require_admin)],
)


@router.get("/dashboard")
def dashboard(db: Session = Depends(get_db)):
    total_menus = db.query(Menu).count()
    total_categories = db.query(Category).count()
    total_orders = db.query(Order).count()

    total_revenue = (
        db.query(func.coalesce(func.sum(Order.total), 0))
        .filter(Order.status == "completed")
        .scalar()
    )

    return {
        "total_menus": total_menus,
        "total_categories": total_categories,
        "total_orders": total_orders,
        "total_revenue": float(total_revenue or 0),
    }


@router.get("/categories", response_model=list[CategoryResponse])
def list_categories(db: Session = Depends(get_db)):
    return db.query(Category).order_by(Category.id.desc()).all()


@router.post(
    "/categories",
    response_model=CategoryResponse,
    status_code=201,
)
def create_category(
    data: CategoryCreate,
    db: Session = Depends(get_db),
):
    existing = (
        db.query(Category)
        .filter(func.lower(Category.name) == data.name.strip().lower())
        .first()
    )

    if existing:
        raise HTTPException(status_code=409, detail="Kategori sudah ada")

    category = Category(
        name=data.name.strip(),
        description=data.description,
    )

    db.add(category)
    db.commit()
    db.refresh(category)

    return category


@router.delete("/categories/{category_id}")
def delete_category(
    category_id: int,
    db: Session = Depends(get_db),
):
    category = db.query(Category).filter(Category.id == category_id).first()

    if not category:
        raise HTTPException(status_code=404, detail="Kategori tidak ditemukan")

    if category.menus:
        raise HTTPException(
            status_code=409,
            detail="Hapus atau pindahkan menu dalam kategori ini terlebih dahulu",
        )

    db.delete(category)
    db.commit()

    return {"message": "Kategori berhasil dihapus"}


@router.get("/menus", response_model=list[MenuResponse])
def list_menus(db: Session = Depends(get_db)):
    return db.query(Menu).order_by(Menu.id.desc()).all()


@router.post("/menus", response_model=MenuResponse, status_code=201)
def create_menu(
    data: MenuCreate,
    db: Session = Depends(get_db),
):
    category = (
        db.query(Category)
        .filter(Category.id == data.category_id)
        .first()
    )

    if not category:
        raise HTTPException(status_code=404, detail="Kategori tidak ditemukan")

    menu = Menu(**data.model_dump())

    db.add(menu)
    db.commit()
    db.refresh(menu)

    return menu


@router.delete("/menus/{menu_id}")
def delete_menu(
    menu_id: int,
    db: Session = Depends(get_db),
):
    menu = db.query(Menu).filter(Menu.id == menu_id).first()

    if not menu:
        raise HTTPException(status_code=404, detail="Menu tidak ditemukan")

    has_order_history = (
        db.query(OrderItem).filter(OrderItem.menu_id == menu_id).first()
    )

    if has_order_history:
        raise HTTPException(
            status_code=409,
            detail="Menu memiliki riwayat pesanan dan tidak bisa dihapus",
        )

    db.delete(menu)
    db.commit()

    return {"message": "Menu berhasil dihapus"}


@router.get("/orders", response_model=list[OrderResponse])
def list_orders(db: Session = Depends(get_db)):
    return db.query(Order).order_by(Order.created_at.desc()).all()


@router.patch("/orders/{order_id}/status")
def update_order_status(
    order_id: int,
    status_value: str,
    db: Session = Depends(get_db),
):
    allowed_statuses = {"pending", "processing", "completed", "cancelled"}

    if status_value not in allowed_statuses:
        raise HTTPException(
            status_code=422,
            detail=f"Status harus salah satu dari: {', '.join(sorted(allowed_statuses))}",
        )

    order = db.query(Order).filter(Order.id == order_id).first()

    if not order:
        raise HTTPException(status_code=404, detail="Pesanan tidak ditemukan")

    order.status = status_value
    db.commit()

    return {
        "message": "Status pesanan berhasil diperbarui",
        "order_id": order.id,
        "status": order.status,
    }