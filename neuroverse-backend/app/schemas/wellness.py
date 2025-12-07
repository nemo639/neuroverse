from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime, date, time


# ============== Wellness Data Schemas ==============

class WellnessDataCreate(BaseModel):
    """Schema for creating wellness data entry."""
    date: date
    
    # Screen Time (in minutes)
    total_screen_time: Optional[int] = Field(None, ge=0)
    gaming_time: Optional[int] = Field(None, ge=0)
    social_media_time: Optional[int] = Field(None, ge=0)
    productivity_time: Optional[int] = Field(None, ge=0)
    other_screen_time: Optional[int] = Field(None, ge=0)
    
    # Sleep Data (in minutes)
    sleep_duration: Optional[int] = Field(None, ge=0)
    sleep_quality_score: Optional[float] = Field(None, ge=0, le=100)
    bedtime: Optional[datetime] = None
    wake_time: Optional[datetime] = None
    
    # Activity
    steps_count: Optional[int] = Field(None, ge=0)
    active_minutes: Optional[int] = Field(None, ge=0)
    
    # App Usage
    app_usage: Optional[Dict[str, int]] = None  # {"app_name": minutes}
    
    # Device
    device_type: Optional[str] = None


class WellnessDataUpdate(BaseModel):
    """Schema for updating wellness data."""
    total_screen_time: Optional[int] = Field(None, ge=0)
    gaming_time: Optional[int] = Field(None, ge=0)
    social_media_time: Optional[int] = Field(None, ge=0)
    productivity_time: Optional[int] = Field(None, ge=0)
    sleep_duration: Optional[int] = Field(None, ge=0)
    sleep_quality_score: Optional[float] = Field(None, ge=0, le=100)
    steps_count: Optional[int] = Field(None, ge=0)
    active_minutes: Optional[int] = Field(None, ge=0)
    app_usage: Optional[Dict[str, int]] = None


class WellnessDataResponse(BaseModel):
    """Schema for wellness data response."""
    id: str
    date: date
    total_screen_time: Optional[int]
    gaming_time: Optional[int]
    social_media_time: Optional[int]
    productivity_time: Optional[int]
    other_screen_time: Optional[int]
    sleep_duration: Optional[int]
    sleep_quality_score: Optional[float]
    steps_count: Optional[int]
    active_minutes: Optional[int]
    app_usage: Optional[Dict[str, int]]
    
    class Config:
        from_attributes = True


# ============== Wellness Goals Schemas ==============

class WellnessGoalCreate(BaseModel):
    """Schema for creating wellness goals."""
    daily_screen_limit: int = Field(360, ge=0)  # 6 hours default
    gaming_limit: int = Field(120, ge=0)  # 2 hours default
    social_media_limit: int = Field(60, ge=0)  # 1 hour default
    target_sleep_duration: int = Field(480, ge=0)  # 8 hours default
    target_bedtime: Optional[str] = None  # "22:00"
    target_wake_time: Optional[str] = None  # "06:00"
    daily_steps_goal: int = Field(10000, ge=0)
    active_minutes_goal: int = Field(30, ge=0)


class WellnessGoalUpdate(BaseModel):
    """Schema for updating wellness goals."""
    daily_screen_limit: Optional[int] = Field(None, ge=0)
    gaming_limit: Optional[int] = Field(None, ge=0)
    social_media_limit: Optional[int] = Field(None, ge=0)
    target_sleep_duration: Optional[int] = Field(None, ge=0)
    target_bedtime: Optional[str] = None
    target_wake_time: Optional[str] = None
    daily_steps_goal: Optional[int] = Field(None, ge=0)
    active_minutes_goal: Optional[int] = Field(None, ge=0)


class WellnessGoalResponse(BaseModel):
    """Schema for wellness goal response."""
    id: str
    daily_screen_limit: int
    gaming_limit: int
    social_media_limit: int
    target_sleep_duration: int
    target_bedtime: Optional[str]
    target_wake_time: Optional[str]
    daily_steps_goal: int
    active_minutes_goal: int
    
    class Config:
        from_attributes = True


# ============== Dashboard Schemas ==============

class TodayWellness(BaseModel):
    """Schema for today's wellness summary."""
    total_screen_time: int  # minutes
    screen_time_hours: float  # hours
    gaming_time: int
    sleep_duration: int
    sleep_hours: float
    steps_count: int
    active_minutes: int
    
    # Comparison with goals
    screen_time_vs_limit: float  # percentage (e.g., 87% of limit)
    is_below_limit: bool
    sleep_vs_target: float  # percentage
    steps_vs_goal: float  # percentage


class WeeklyPattern(BaseModel):
    """Schema for weekly pattern data."""
    day: str  # "Mon", "Tue", etc.
    date: date
    screen_time: int  # minutes
    screen_time_hours: float
    is_today: bool


class WellnessDashboard(BaseModel):
    """Schema for wellness dashboard response."""
    today: TodayWellness
    weekly_patterns: List[WeeklyPattern]
    goals: WellnessGoalResponse
    
    # Insights
    insight_message: str
    trend: str  # "improving", "stable", "declining"
    recommendations: List[str]


class WellnessHistory(BaseModel):
    """Schema for wellness history."""
    data: List[WellnessDataResponse]
    total_days: int
    avg_screen_time: float
    avg_sleep: float
    avg_steps: int
