from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime, date
from enum import Enum


class TestCategoryEnum(str, Enum):
    SPEECH_LANGUAGE = "speech_language"
    COGNITIVE_MEMORY = "cognitive_memory"
    MOTOR_FUNCTIONS = "motor_functions"
    GAIT_MOVEMENT = "gait_movement"
    FACIAL_ANALYSIS = "facial_analysis"


class TestStatusEnum(str, Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    FAILED = "failed"


class RiskLevelEnum(str, Enum):
    LOW = "low"
    MODERATE = "moderate"
    HIGH = "high"
    CRITICAL = "critical"


# ============== Test Result Schemas (Individual Items) ==============

class TestResultCreate(BaseModel):
    """Schema for submitting a single test item result."""
    item_name: str = Field(..., max_length=100, description="e.g., 'word_1', 'spiral_drawing'")
    item_type: str = Field(..., description="audio, image, numeric, text")
    raw_value: Optional[str] = None  # File path or text value
    processed_value: Optional[float] = None  # Numeric processed value


class TestResultResponse(BaseModel):
    """Schema for test result response."""
    id: str
    test_id: str
    item_name: str
    item_type: str
    raw_value: Optional[str]
    processed_value: Optional[float]
    score: Optional[float]
    is_abnormal: bool
    notes: Optional[str]
    created_at: datetime
    
    class Config:
        from_attributes = True


class TestResultListResponse(BaseModel):
    """Schema for list of test results."""
    results: List[TestResultResponse]
    total: int
    abnormal_count: int


# ============== Test Schemas ==============

class TestCreate(BaseModel):
    """Schema for creating a new test session."""
    category: TestCategoryEnum
    test_name: str = Field(..., max_length=100)
    device_info: Optional[Dict[str, Any]] = None
    app_version: Optional[str] = None


class TestStart(BaseModel):
    """Schema for starting a test."""
    test_id: str


class TestDataSubmit(BaseModel):
    """Schema for submitting multiple test items at once."""
    items: List[TestResultCreate]


class TestComplete(BaseModel):
    """Schema for completing a test."""
    raw_data: Optional[Dict[str, Any]] = None


class TestResponse(BaseModel):
    """Schema for test response."""
    id: str
    category: TestCategoryEnum
    test_name: str
    status: TestStatusEnum
    score: Optional[float]
    risk_level: Optional[RiskLevelEnum]
    risk_percentage: Optional[float]
    confidence_score: Optional[float]
    started_at: Optional[datetime]
    completed_at: Optional[datetime]
    duration_seconds: Optional[int]
    created_at: datetime
    
    class Config:
        from_attributes = True


class TestDetailResponse(TestResponse):
    """Schema for detailed test response with AI analysis."""
    ai_prediction: Optional[Dict[str, Any]] = None
    biomarkers: Optional[Dict[str, Any]] = None
    shap_values: Optional[List[Dict[str, Any]]] = None
    feature_importance: Optional[List[Dict[str, Any]]] = None
    results: Optional[List[TestResultResponse]] = None  # Individual item results
    
    class Config:
        from_attributes = True


class TestListResponse(BaseModel):
    """Schema for list of tests."""
    tests: List[TestResponse]
    total: int
    completed: int
    pending: int


# ============== Speech Test Specific ==============

class SpeechTestData(BaseModel):
    """Schema for speech test data."""
    audio_file_path: str
    duration_seconds: float
    sample_rate: int = 16000
    
    # Extracted features
    pause_count: Optional[int] = None
    avg_pause_duration: Optional[float] = None
    speech_rate: Optional[float] = None
    pitch_variance: Optional[float] = None
    voice_tremor_score: Optional[float] = None


# ============== Motor Test Specific ==============

class MotorTestData(BaseModel):
    """Schema for motor function test data."""
    drawing_file_path: Optional[str] = None
    tap_data: Optional[List[Dict[str, Any]]] = None
    
    # Extracted features
    tremor_amplitude: Optional[float] = None
    drawing_speed: Optional[float] = None
    line_smoothness: Optional[float] = None
    pressure_variance: Optional[float] = None
    tap_accuracy: Optional[float] = None
    tap_regularity: Optional[float] = None


# ============== Cognitive Test Specific ==============

class CognitiveTestData(BaseModel):
    """Schema for cognitive test data."""
    responses: List[Dict[str, Any]]
    
    # Extracted features
    avg_response_time: Optional[float] = None
    recall_accuracy: Optional[float] = None
    stroop_interference: Optional[float] = None
    working_memory_score: Optional[float] = None
    attention_score: Optional[float] = None


# ============== XAI Schemas ==============

class XAIResponse(BaseModel):
    """Schema for XAI (Explainable AI) data."""
    test_id: str
    category: TestCategoryEnum
    shap_values: List[Dict[str, Any]]
    feature_importance: List[Dict[str, Any]]
    saliency_map: Optional[str] = None
    interpretation: List[str]
    confidence_score: float
    prediction_class: str


class XAIModuleData(BaseModel):
    """Schema for XAI data per module."""
    module: str
    shap_values: List[Dict[str, Any]]
    feature_importance: List[Dict[str, Any]]
    visualization_data: Dict[str, Any]
    interpretation: List[str]
    gradient_colors: List[str]


# ============== Report Schemas ==============

class ReportCreate(BaseModel):
    """Schema for creating a report."""
    report_type: str = "comprehensive"
    period_start: Optional[date] = None
    period_end: Optional[date] = None


class ReportResponse(BaseModel):
    """Schema for report response."""
    id: str
    report_type: str
    title: str
    overall_risk_level: Optional[RiskLevelEnum]
    overall_risk_score: Optional[float]
    speech_score: Optional[float]
    cognitive_score: Optional[float]
    motor_score: Optional[float]
    gait_score: Optional[float]
    facial_score: Optional[float]
    summary: Optional[str]
    recommendations: Optional[List[str]]
    ai_interpretation: Optional[str]
    key_findings: Optional[List[str]]
    period_start: Optional[date]
    period_end: Optional[date]
    pdf_path: Optional[str]
    created_at: datetime
    
    class Config:
        from_attributes = True


class ReportListResponse(BaseModel):
    """Schema for list of reports."""
    reports: List[ReportResponse]
    total: int


# ============== Dashboard Schemas ==============

class DashboardStats(BaseModel):
    """Schema for dashboard statistics."""
    overall_risk_score: float
    overall_risk_level: RiskLevelEnum
    tests_completed: int
    tests_pending: int
    last_test_date: Optional[datetime]
    speech_score: Optional[float]
    cognitive_score: Optional[float]
    motor_score: Optional[float]
    gait_score: Optional[float]
    risk_trend: str
    trend_percentage: float


class RecentTest(BaseModel):
    """Schema for recent test in dashboard."""
    id: str
    test_name: str
    category: TestCategoryEnum
    status: TestStatusEnum
    score: Optional[float]
    completed_at: Optional[datetime]


class DashboardResponse(BaseModel):
    """Schema for dashboard response."""
    stats: DashboardStats
    recent_tests: List[RecentTest]
    upcoming_tests: List[Dict[str, Any]]
    wellness_insight: Optional[str]