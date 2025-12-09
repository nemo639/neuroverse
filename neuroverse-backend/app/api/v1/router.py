"""
API v1 Router - Combines all endpoint routers
"""

from fastapi import APIRouter

from app.api.v1.endpoints import auth, users, tests, wellness, reports

api_router = APIRouter(prefix="/api/v1")

# Include all endpoint routers
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(users.router, prefix="/users", tags=["Users"])
api_router.include_router(tests.router, prefix="/tests", tags=["Tests"])
api_router.include_router(wellness.router, prefix="/wellness", tags=["Wellness"])
api_router.include_router(reports.router, prefix="/reports", tags=["Reports"])
