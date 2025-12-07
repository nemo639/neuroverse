from sqlalchemy import Column, String, DateTime, Date, Float, Integer, JSON, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from app.db.database import Base


class WellnessData(Base):
    """Store daily digital wellness data."""
    __tablename__ = "wellness_data"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    
    # Date
    date = Column(Date, nullable=False, index=True)
    
    # Screen Time (in minutes)
    total_screen_time = Column(Integer, nullable=True)  # Total minutes
    gaming_time = Column(Integer, nullable=True)
    social_media_time = Column(Integer, nullable=True)
    productivity_time = Column(Integer, nullable=True)
    other_screen_time = Column(Integer, nullable=True)
    
    # Sleep Data (in minutes)
    sleep_duration = Column(Integer, nullable=True)
    sleep_quality_score = Column(Float, nullable=True)  # 0-100
    bedtime = Column(DateTime(timezone=True), nullable=True)
    wake_time = Column(DateTime(timezone=True), nullable=True)
    
    # Activity
    steps_count = Column(Integer, nullable=True)
    active_minutes = Column(Integer, nullable=True)
    
    # App Usage Breakdown (JSON)
    app_usage = Column(JSON, nullable=True)  # {"app_name": minutes}
    
    # Device Info
    device_type = Column(String(50), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="wellness_data")
    
    def __repr__(self):
        return f"<WellnessData {self.date} for user {self.user_id}>"


class WellnessGoal(Base):
    """User's wellness goals and limits."""
    __tablename__ = "wellness_goals"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    
    # Screen Time Limits (in minutes)
    daily_screen_limit = Column(Integer, default=360)  # 6 hours
    gaming_limit = Column(Integer, default=120)  # 2 hours
    social_media_limit = Column(Integer, default=60)  # 1 hour
    
    # Sleep Goals
    target_sleep_duration = Column(Integer, default=480)  # 8 hours
    target_bedtime = Column(String(10), nullable=True)  # "22:00"
    target_wake_time = Column(String(10), nullable=True)  # "06:00"
    
    # Activity Goals
    daily_steps_goal = Column(Integer, default=10000)
    active_minutes_goal = Column(Integer, default=30)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    def __repr__(self):
        return f"<WellnessGoal for user {self.user_id}>"
