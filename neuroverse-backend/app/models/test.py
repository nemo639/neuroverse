from sqlalchemy import Column, String, Boolean, DateTime, Date, Enum, Text, Float, Integer, JSON, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime
import uuid
import enum

from app.db.database import Base


class TestCategoryEnum(str, enum.Enum):
    SPEECH_LANGUAGE = "speech_language"
    COGNITIVE_MEMORY = "cognitive_memory"
    MOTOR_FUNCTIONS = "motor_functions"
    GAIT_MOVEMENT = "gait_movement"
    FACIAL_ANALYSIS = "facial_analysis"


class TestStatusEnum(str, enum.Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    FAILED = "failed"


class RiskLevelEnum(str, enum.Enum):
    LOW = "low"
    MODERATE = "moderate"
    HIGH = "high"
    CRITICAL = "critical"


class Test(Base):
    __tablename__ = "tests"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    
    # Test Information
    category = Column(Enum(TestCategoryEnum), nullable=False)
    test_name = Column(String(100), nullable=False)
    status = Column(Enum(TestStatusEnum), default=TestStatusEnum.PENDING)
    
    # Test Data
    raw_data = Column(JSON, nullable=True)  # Store raw test data (audio paths, drawings, etc.)
    processed_data = Column(JSON, nullable=True)  # Store processed/analyzed data
    
    # Results
    score = Column(Float, nullable=True)  # Overall score 0-100
    risk_level = Column(Enum(RiskLevelEnum), nullable=True)
    risk_percentage = Column(Float, nullable=True)  # 0-100
    
    # AI Analysis
    ai_prediction = Column(JSON, nullable=True)  # Model predictions
    confidence_score = Column(Float, nullable=True)  # Model confidence 0-1
    biomarkers = Column(JSON, nullable=True)  # Extracted biomarkers
    
    # XAI Data
    shap_values = Column(JSON, nullable=True)  # SHAP values for explainability
    saliency_map = Column(Text, nullable=True)  # Base64 encoded saliency map
    feature_importance = Column(JSON, nullable=True)  # Feature rankings
    
    # Timing
    started_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    duration_seconds = Column(Integer, nullable=True)
    
    # Metadata
    device_info = Column(JSON, nullable=True)
    app_version = Column(String(20), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="tests")
    results = relationship("TestResult", back_populates="test", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<Test {self.test_name} - {self.category}>"


class TestResult(Base):
    """Store individual test item results within a test session."""
    __tablename__ = "test_results"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    test_id = Column(String(36), ForeignKey("tests.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # Result Information
    item_name = Column(String(100), nullable=False)  # e.g., "word_1", "spiral_drawing", "response_time"
    item_type = Column(String(50), nullable=False)  # audio, image, numeric, text
    
    # Data
    raw_value = Column(Text, nullable=True)  # Raw input (file path or value)
    processed_value = Column(Float, nullable=True)  # Processed numeric value
    
    # Analysis
    score = Column(Float, nullable=True)  # Individual item score 0-100
    is_abnormal = Column(Boolean, default=False)  # Flag for concerning results
    notes = Column(Text, nullable=True)  # AI notes for this item
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    test = relationship("Test", back_populates="results")
    
    def __repr__(self):
        return f"<TestResult {self.item_name} - Score: {self.score}>"


class Report(Base):
    __tablename__ = "reports"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    
    # Report Information
    report_type = Column(String(50), nullable=False)  # weekly, monthly, comprehensive
    title = Column(String(200), nullable=False)
    
    # Risk Assessment
    overall_risk_level = Column(Enum(RiskLevelEnum), nullable=True)
    overall_risk_score = Column(Float, nullable=True)
    
    # Category Scores
    speech_score = Column(Float, nullable=True)
    cognitive_score = Column(Float, nullable=True)
    motor_score = Column(Float, nullable=True)
    gait_score = Column(Float, nullable=True)
    facial_score = Column(Float, nullable=True)
    
    # Analysis
    summary = Column(Text, nullable=True)
    recommendations = Column(JSON, nullable=True)
    trend_data = Column(JSON, nullable=True)  # Historical comparison
    
    # AI Insights
    ai_interpretation = Column(Text, nullable=True)
    key_findings = Column(JSON, nullable=True)
    
    # Report Period
    period_start = Column(Date, nullable=True)
    period_end = Column(Date, nullable=True)
    
    # File
    pdf_path = Column(String(500), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User", back_populates="reports")
    
    def __repr__(self):
        return f"<Report {self.title}>"