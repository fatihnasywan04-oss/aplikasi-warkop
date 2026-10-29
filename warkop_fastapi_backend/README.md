# Warkop Digital API (FastAPI)

Backend starter for the Warkop Digital Admin/Kasir Flutter app and future QR customer website.

## Included
- Admin login with JWT bearer token
- Public menu/category endpoints for QR customers
- Public order creation and order status lookup
- Admin menu/category management
- Admin order status and payment confirmation
- Expense tracking and dashboard summary
- SQLite for local development; PostgreSQL-ready via `DATABASE_URL`
- Render deployment blueprint (`render.yaml`) and Dockerfile

## Run locally
Requires Python 3.11+ (3.12 recommended).

```bash
python -m venv .venv
# Windows CMD:
.venv\Scripts\activate
# macOS/Linux:
source .venv/bin/activate

pip install -r requirements.txt
copy .env.example .env
uvicorn app.main:app --reload
```

Open http://127.0.0.1:8000/docs

Default local demo credentials from `.env.example`:
- Email: `admin@warkop.com`
- Password: `change-this-password-before-deploy`

Change the password in `.env` before starting for real local use. Environment variables are read when the app starts.

## Deploy online with Render
1. Create a GitHub repository and upload these project files.
2. Create a Render account and connect the repository.
3. In Render, choose **New + → Blueprint** and select the repository containing `render.yaml`.
4. Set `ADMIN_PASSWORD` to a strong unique password when prompted.
5. Render creates the web service and PostgreSQL database from the blueprint. Wait for deploy to finish.
6. Open the service URL, then append `/docs` to test the API.
7. Save the base URL, e.g. `https://your-service.onrender.com`, for the Flutter app.

The actual deployment requires your own Render/GitHub account authorization and cannot be completed by this package alone. Do not put secrets in source control. For a real deployment, set restrictive `CORS_ORIGINS` to the actual web frontend origin when available.

## Key endpoints
Public:
- `GET /health`
- `GET /api/public/categories`
- `GET /api/public/menus`
- `POST /api/public/orders`
- `GET /api/public/orders/{order_number}`

Auth:
- `POST /api/auth/login`
- `GET /api/auth/me`

Admin (send header `Authorization: Bearer <access_token>`):
- `GET /api/admin/dashboard`
- `GET/POST /api/admin/categories`
- `GET/POST /api/admin/menus`
- `PUT /api/admin/menus/{menu_id}`
- `DELETE /api/admin/menus/{menu_id}` (soft-disable)
- `GET /api/admin/orders`
- `PATCH /api/admin/orders/{order_id}/status`
- `POST /api/admin/orders/{order_id}/payment`
- `GET/POST /api/admin/expenses`
- `DELETE /api/admin/expenses/{expense_id}`

## Important production notes
- This is a starter backend, not a fully audited accounting system.
- First-admin seeding uses `ADMIN_EMAIL` and `ADMIN_PASSWORD` when no admin with that email exists. Changing the environment password later does not reset an existing admin's password.
- The public order endpoints intentionally allow customer orders without login. Add rate limiting, spam protection, and stronger order-number access controls before a high-traffic public launch.
- Dashboard `estimated_balance` is paid revenue minus recorded expenses; it is **not net profit** because menu cost of goods sold and stock usage are not modeled yet.
- Payment endpoint only records cashier-confirmed payment. It does not process online payments or QRIS automatically.
- Database schema creation uses `create_all` for starter simplicity. Use Alembic migrations before significant schema changes.
