from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Menu, Order, OrderItem
from app.schemas import OrderCreate, OrderResponse

router = APIRouter(prefix="/api/public", tags=["Public"])


@router.get("/menus")
def public_menus(db: Session = Depends(get_db)):
    menus = (
        db.query(Menu)
        .filter(Menu.is_available.is_(True))
        .order_by(Menu.name.asc())
        .all()
    )

    return [
        {
            "id": menu.id,
            "name": menu.name,
            "description": menu.description,
            "price": float(menu.price),
            "image_url": menu.image_url,
            "category_id": menu.category_id,
        }
        for menu in menus
    ]


@router.post("/orders", response_model=OrderResponse, status_code=201)
def create_order(
    data: OrderCreate,
    db: Session = Depends(get_db),
):
    menu_ids = [item.menu_id for item in data.items]

    if len(menu_ids) != len(set(menu_ids)):
        raise HTTPException(
            status_code=422,
            detail="Setiap menu cukup dicantumkan satu kali dengan quantity yang sesuai",
        )

    menus = (
        db.query(Menu)
        .filter(Menu.id.in_(menu_ids))
        .all()
    )

    menus_by_id = {menu.id: menu for menu in menus}

    if len(menus_by_id) != len(menu_ids):
        raise HTTPException(
            status_code=404,
            detail="Satu atau lebih menu tidak ditemukan",
        )

    for item in data.items:
        if not menus_by_id[item.menu_id].is_available:
            raise HTTPException(
                status_code=400,
                detail=f"Menu {menus_by_id[item.menu_id].name} sedang tidak tersedia",
            )

    total = Decimal("0.00")

    for item in data.items:
        menu = menus_by_id[item.menu_id]
        total += Decimal(str(menu.price)) * item.quantity

    order = Order(
        customer_name=data.customer_name.strip(),
        customer_phone=data.customer_phone,
        total=total,
        status="pending",
    )

    for item in data.items:
        menu = menus_by_id[item.menu_id]

        order.items.append(
            OrderItem(
                menu_id=menu.id,
                quantity=item.quantity,
                price=menu.price,
            )
        )

    db.add(order)
    db.commit()
    db.refresh(order)

    return order