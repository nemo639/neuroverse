from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import date, timedelta

from app.db.database import get_db
from app.services.wellness_service import WellnessService
from app.schemas.wellness import (
    WellnessDataCreate,
    WellnessDataUpdate,
    WellnessDataResponse,
    WellnessGoalCreate,
    WellnessGoalUpdate,
    WellnessGoalResponse,
    WellnessDashboard,
    WellnessHistory
)
from app.schemas.user import MessageResponse
from app.core.security import get_current_user_id

router = APIRouter(prefix="/wellness", tags=["Digital Wellness"])


# ============== Dashboard ==============

@router.get("/dashboard", response_model=WellnessDashboard)
async def get_wellness_dashboard(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Get wellness dashboard with today's data, weekly patterns, and insights.
    """
    wellness_service = WellnessService(db)
    return await wellness_service.get_wellness_dashboard(user_id)


# ============== Wellness Data ==============

@router.post("/data", response_model=WellnessDataResponse, status_code=status.HTTP_201_CREATED)
async def create_wellness_data(
    data: WellnessDataCreate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Create or update wellness data for a specific date.
    
    If data already exists for the date, it will be updated.
    """
    wellness_service = WellnessService(db)
    wellness_data = await wellness_service.create_or_update_wellness_data(user_id, data)
    return WellnessDataResponse.model_validate(wellness_data)


@router.get("/data/today", response_model=WellnessDataResponse)
async def get_today_wellness(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Get today's wellness data.
    """
    wellness_service = WellnessService(db)
    data = await wellness_service.get_wellness_data(user_id, date.today())
    
    if not data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No wellness data for today"
        )
    
    return data


@router.get("/data/{target_date}", response_model=WellnessDataResponse)
async def get_wellness_data(
    target_date: date,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Get wellness data for a specific date.
    """
    wellness_service = WellnessService(db)
    data = await wellness_service.get_wellness_data(user_id, target_date)
    
    if not data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No wellness data for {target_date}"
        )
    
    return data


@router.get("/history", response_model=WellnessHistory)
async def get_wellness_history(
    start_date: date = Query(default=None),
    end_date: date = Query(default=None),
    days: int = Query(default=7, ge=1, le=90),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Get wellness history for a date range.
    
    Default: last 7 days.
    """
    wellness_service = WellnessService(db)
    
    if not end_date:
        end_date = date.today()
    if not start_date:
        start_date = end_date - timedelta(days=days - 1)
    
    data_list = await wellness_service.get_wellness_history(user_id, start_date, end_date)
    
    # Calculate averages
    if data_list:
        avg_screen = sum(d.total_screen_time or 0 for d in data_list) / len(data_list)
        avg_sleep = sum(d.sleep_duration or 0 for d in data_list) / len(data_list)
        avg_steps = sum(d.steps_count or 0 for d in data_list) // len(data_list)
    else:
        avg_screen = avg_sleep = avg_steps = 0
    
    return WellnessHistory(
        data=data_list,
        total_days=len(data_list),
        avg_screen_time=round(avg_screen, 1),
        avg_sleep=round(avg_sleep, 1),
        avg_steps=avg_steps
    )


@router.delete("/data/{target_date}", response_model=MessageResponse)
async def delete_wellness_data(
    target_date: date,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Delete wellness data for a specific date.
    """
    wellness_service = WellnessService(db)
    await wellness_service.delete_wellness_data(user_id, target_date)
    
    return MessageResponse(
        message=f"Wellness data for {target_date} deleted.",
        success=True
    )


# ============== Goals ==============

@router.get("/goals", response_model=WellnessGoalResponse)
async def get_wellness_goals(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Get user's wellness goals.
    """
    wellness_service = WellnessService(db)
    return await wellness_service.get_goals(user_id)


@router.post("/goals", response_model=WellnessGoalResponse, status_code=status.HTTP_201_CREATED)
async def create_wellness_goals(
    goals: WellnessGoalCreate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Create or update wellness goals.
    """
    wellness_service = WellnessService(db)
    wellness_goals = await wellness_service.create_or_update_goals(user_id, goals)
    return WellnessGoalResponse.model_validate(wellness_goals)


@router.patch("/goals", response_model=WellnessGoalResponse)
async def update_wellness_goals(
    goals: WellnessGoalUpdate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Update specific wellness goals.
    """
    wellness_service = WellnessService(db)
    return await wellness_service.update_goals(user_id, goals)
