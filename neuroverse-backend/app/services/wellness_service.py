from datetime import datetime, date, timedelta
from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, func, desc
from fastapi import HTTPException, status

from app.models.wellness import WellnessData, WellnessGoal
from app.schemas.wellness import (
    WellnessDataCreate, WellnessDataUpdate, WellnessDataResponse,
    WellnessGoalCreate, WellnessGoalUpdate, WellnessGoalResponse,
    TodayWellness, WeeklyPattern, WellnessDashboard
)


class WellnessService:
    """Service for handling wellness data operations."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    # ============== Wellness Data ==============
    
    async def create_or_update_wellness_data(
        self,
        user_id: str,
        data: WellnessDataCreate
    ) -> WellnessData:
        """Create or update wellness data for a date."""
        # Check if entry exists for date
        existing = await self._get_wellness_data_by_date(user_id, data.date)
        
        if existing:
            # Update existing
            update_dict = data.model_dump(exclude_unset=True, exclude={"date"})
            for field, value in update_dict.items():
                if value is not None:
                    setattr(existing, field, value)
            await self.db.flush()
            return existing
        
        # Create new
        wellness_data = WellnessData(
            user_id=user_id,
            **data.model_dump()
        )
        
        self.db.add(wellness_data)
        await self.db.flush()
        
        return wellness_data
    
    async def get_wellness_data(
        self,
        user_id: str,
        target_date: date
    ) -> Optional[WellnessDataResponse]:
        """Get wellness data for a specific date."""
        data = await self._get_wellness_data_by_date(user_id, target_date)
        
        if not data:
            return None
        
        return WellnessDataResponse.model_validate(data)
    
    async def get_wellness_history(
        self,
        user_id: str,
        start_date: date,
        end_date: date
    ) -> List[WellnessDataResponse]:
        """Get wellness data for a date range."""
        result = await self.db.execute(
            select(WellnessData).where(
                and_(
                    WellnessData.user_id == user_id,
                    WellnessData.date >= start_date,
                    WellnessData.date <= end_date
                )
            ).order_by(WellnessData.date)
        )
        data_list = result.scalars().all()
        
        return [WellnessDataResponse.model_validate(d) for d in data_list]
    
    async def delete_wellness_data(
        self,
        user_id: str,
        target_date: date
    ) -> None:
        """Delete wellness data for a date."""
        data = await self._get_wellness_data_by_date(user_id, target_date)
        
        if data:
            await self.db.delete(data)
            await self.db.flush()
    
    # ============== Wellness Goals ==============
    
    async def create_or_update_goals(
        self,
        user_id: str,
        goals_data: WellnessGoalCreate
    ) -> WellnessGoal:
        """Create or update wellness goals."""
        existing = await self._get_wellness_goals(user_id)
        
        if existing:
            # Update existing
            update_dict = goals_data.model_dump(exclude_unset=True)
            for field, value in update_dict.items():
                if value is not None:
                    setattr(existing, field, value)
            await self.db.flush()
            return existing
        
        # Create new
        goals = WellnessGoal(
            user_id=user_id,
            **goals_data.model_dump()
        )
        
        self.db.add(goals)
        await self.db.flush()
        
        return goals
    
    async def get_goals(self, user_id: str) -> WellnessGoalResponse:
        """Get user's wellness goals."""
        goals = await self._get_wellness_goals(user_id)
        
        if not goals:
            # Return default goals
            return WellnessGoalResponse(
                id="default",
                daily_screen_limit=360,
                gaming_limit=120,
                social_media_limit=60,
                target_sleep_duration=480,
                target_bedtime="22:00",
                target_wake_time="06:00",
                daily_steps_goal=10000,
                active_minutes_goal=30
            )
        
        return WellnessGoalResponse.model_validate(goals)
    
    async def update_goals(
        self,
        user_id: str,
        goals_data: WellnessGoalUpdate
    ) -> WellnessGoalResponse:
        """Update wellness goals."""
        goals = await self._get_wellness_goals(user_id)
        
        if not goals:
            # Create with defaults + updates
            create_data = WellnessGoalCreate(**goals_data.model_dump(exclude_unset=True))
            goals = await self.create_or_update_goals(user_id, create_data)
        else:
            update_dict = goals_data.model_dump(exclude_unset=True)
            for field, value in update_dict.items():
                if value is not None:
                    setattr(goals, field, value)
            await self.db.flush()
        
        return WellnessGoalResponse.model_validate(goals)
    
    # ============== Dashboard ==============
    
    async def get_wellness_dashboard(self, user_id: str) -> WellnessDashboard:
        """Get wellness dashboard data."""
        today = date.today()
        
        # Get today's data
        today_data = await self._get_wellness_data_by_date(user_id, today)
        
        # Get goals
        goals = await self.get_goals(user_id)
        
        # Get weekly data
        week_start = today - timedelta(days=6)
        weekly_data = await self.get_wellness_history(user_id, week_start, today)
        
        # Build today's summary
        if today_data:
            screen_time = today_data.total_screen_time or 0
            sleep = today_data.sleep_duration or 0
            
            today_summary = TodayWellness(
                total_screen_time=screen_time,
                screen_time_hours=round(screen_time / 60, 1),
                gaming_time=today_data.gaming_time or 0,
                sleep_duration=sleep,
                sleep_hours=round(sleep / 60, 1),
                steps_count=today_data.steps_count or 0,
                active_minutes=today_data.active_minutes or 0,
                screen_time_vs_limit=round((screen_time / goals.daily_screen_limit) * 100, 1) if goals.daily_screen_limit > 0 else 0,
                is_below_limit=screen_time <= goals.daily_screen_limit,
                sleep_vs_target=round((sleep / goals.target_sleep_duration) * 100, 1) if goals.target_sleep_duration > 0 else 0,
                steps_vs_goal=round((today_data.steps_count or 0) / goals.daily_steps_goal * 100, 1) if goals.daily_steps_goal > 0 else 0
            )
        else:
            today_summary = TodayWellness(
                total_screen_time=0,
                screen_time_hours=0,
                gaming_time=0,
                sleep_duration=0,
                sleep_hours=0,
                steps_count=0,
                active_minutes=0,
                screen_time_vs_limit=0,
                is_below_limit=True,
                sleep_vs_target=0,
                steps_vs_goal=0
            )
        
        # Build weekly patterns
        weekly_patterns = []
        day_names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        
        for i in range(7):
            current_date = week_start + timedelta(days=i)
            day_data = next((d for d in weekly_data if d.date == current_date), None)
            
            screen_time = day_data.total_screen_time if day_data else 0
            
            weekly_patterns.append(WeeklyPattern(
                day=day_names[current_date.weekday()],
                date=current_date,
                screen_time=screen_time,
                screen_time_hours=round(screen_time / 60, 1),
                is_today=current_date == today
            ))
        
        # Generate insight
        if today_summary.is_below_limit:
            insight = f"Great job! You're {round(100 - today_summary.screen_time_vs_limit)}% below your daily screen time limit."
            trend = "improving"
        elif today_summary.screen_time_vs_limit > 120:
            insight = "You've exceeded your screen time limit. Consider taking a break."
            trend = "declining"
        else:
            insight = "You're close to your daily limit. Be mindful of your screen usage."
            trend = "stable"
        
        recommendations = [
            "Take regular breaks every 30 minutes of screen time",
            "Avoid screens 1 hour before bedtime",
            "Try to get at least 7-8 hours of sleep"
        ]
        
        return WellnessDashboard(
            today=today_summary,
            weekly_patterns=weekly_patterns,
            goals=goals,
            insight_message=insight,
            trend=trend,
            recommendations=recommendations
        )
    
    # ============== Private Methods ==============
    
    async def _get_wellness_data_by_date(
        self,
        user_id: str,
        target_date: date
    ) -> Optional[WellnessData]:
        """Get wellness data by user and date."""
        result = await self.db.execute(
            select(WellnessData).where(
                and_(
                    WellnessData.user_id == user_id,
                    WellnessData.date == target_date
                )
            )
        )
        return result.scalar_one_or_none()
    
    async def _get_wellness_goals(self, user_id: str) -> Optional[WellnessGoal]:
        """Get wellness goals for user."""
        result = await self.db.execute(
            select(WellnessGoal).where(WellnessGoal.user_id == user_id)
        )
        return result.scalar_one_or_none()
