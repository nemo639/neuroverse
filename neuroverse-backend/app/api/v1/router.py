from fastapi import APIRouter

from app.api.v1.endpoints import auth, users, tests, wellness

api_router = APIRouter(prefix="/api/v1")

# Include all endpoint routers
api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(tests.router)
api_router.include_router(wellness.router)