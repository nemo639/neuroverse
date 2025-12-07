from fastapi import APIRouter, Depends, HTTPException, status, Query, Body
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional, List

from app.db.database import get_db
from app.services.test_service import TestService
from app.schemas.test import (
    TestCreate,
    TestResponse,
    TestDetailResponse,
    TestListResponse,
    TestResultCreate,
    TestResultResponse,
    TestResultListResponse,
    TestDataSubmit,
    ReportCreate,
    ReportResponse,
    ReportListResponse,
    DashboardResponse,
    XAIModuleData,
    TestCategoryEnum,
    TestStatusEnum
)
from app.schemas.user import MessageResponse
from app.core.security import get_current_user_id

router = APIRouter(prefix="/tests", tags=["Tests"])


# ============== Dashboard ==============

@router.get("/dashboard", response_model=DashboardResponse)
async def get_dashboard(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Get user dashboard with stats and recent tests.
    """
    test_service = TestService(db)
    return await test_service.get_dashboard(user_id)


# ============== Reports (BEFORE /{test_id} routes!) ==============

@router.post("/reports", response_model=ReportResponse, status_code=status.HTTP_201_CREATED)
async def create_report(
    report_data: ReportCreate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Generate a comprehensive health report.
    """
    test_service = TestService(db)
    report = await test_service.create_report(user_id, report_data)
    return ReportResponse.model_validate(report)


@router.get("/reports", response_model=ReportListResponse)
async def get_reports(
    limit: int = Query(20, ge=1, le=100),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Get user's health reports.
    """
    test_service = TestService(db)
    reports = await test_service.get_user_reports(user_id, limit)
    
    return ReportListResponse(
        reports=reports,
        total=len(reports)
    )


# ============== XAI (BEFORE /{test_id} routes!) ==============

@router.get("/xai/{category}", response_model=XAIModuleData)
async def get_xai_data(
    category: TestCategoryEnum,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Get XAI (Explainable AI) data for a test category.
    
    Returns SHAP values, feature importance, and interpretations.
    """
    test_service = TestService(db)
    return await test_service.get_xai_data(user_id, category)


# ============== Tests ==============

@router.post("/", response_model=TestResponse, status_code=status.HTTP_201_CREATED)
async def create_test(
    test_data: TestCreate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Create a new test session.
    """
    test_service = TestService(db)
    test = await test_service.create_test(user_id, test_data)
    return TestResponse.model_validate(test)


@router.get("/", response_model=TestListResponse)
async def get_tests(
    category: Optional[TestCategoryEnum] = Query(None),
    status: Optional[TestStatusEnum] = Query(None),
    limit: int = Query(50, ge=1, le=100),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Get user's tests with optional filters.
    """
    test_service = TestService(db)
    return await test_service.get_user_tests(user_id, category, status, limit)


# ============== Test by ID (MUST be LAST - catches all /{test_id} patterns) ==============

@router.get("/{test_id}", response_model=TestDetailResponse)
async def get_test(
    test_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Get test details with AI analysis and individual results.
    """
    test_service = TestService(db)
    return await test_service.get_test(test_id, user_id)


@router.post("/{test_id}/start", response_model=TestResponse)
async def start_test(
    test_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Start a test session.
    """
    test_service = TestService(db)
    test = await test_service.start_test(test_id, user_id)
    return TestResponse.model_validate(test)


# ============== Test Results (Individual Items) ==============

@router.post("/{test_id}/items", response_model=TestResultResponse, status_code=status.HTTP_201_CREATED)
async def submit_test_item(
    test_id: str,
    item_data: TestResultCreate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Submit a single test item result.
    
    Use this to submit individual items during a test:
    - word_1, word_2 for recall tests
    - spiral_drawing for motor tests
    - response_time for cognitive tests
    
    Example:
    {
        "item_name": "word_1",
        "item_type": "text",
        "raw_value": "apple",
        "processed_value": 1.0
    }
    """
    test_service = TestService(db)
    result = await test_service.submit_test_item(test_id, user_id, item_data)
    return TestResultResponse.model_validate(result)


@router.post("/{test_id}/items/batch", response_model=List[TestResultResponse], status_code=status.HTTP_201_CREATED)
async def submit_test_items_batch(
    test_id: str,
    data: TestDataSubmit,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Submit multiple test item results at once.
    
    Example:
    {
        "items": [
            {"item_name": "word_1", "item_type": "text", "raw_value": "apple", "processed_value": 1.0},
            {"item_name": "word_2", "item_type": "text", "raw_value": "house", "processed_value": 1.0},
            {"item_name": "word_3", "item_type": "text", "raw_value": null, "processed_value": 0.0}
        ]
    }
    """
    test_service = TestService(db)
    results = await test_service.submit_test_items(test_id, user_id, data.items)
    return [TestResultResponse.model_validate(r) for r in results]


@router.get("/{test_id}/items", response_model=TestResultListResponse)
async def get_test_results(
    test_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Get all individual results for a test.
    
    Returns list of all submitted items with their scores and analysis.
    """
    test_service = TestService(db)
    return await test_service.get_test_results(test_id, user_id)


@router.post("/{test_id}/complete", response_model=TestDetailResponse)
async def complete_test(
    test_id: str,
    raw_data: Optional[dict] = Body(default=None),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Complete a test and get AI analysis results.
    
    This calculates the overall score from individual items (if any),
    generates AI predictions, biomarkers, and XAI data.
    """
    test_service = TestService(db)
    test = await test_service.complete_test(test_id, user_id, raw_data)
    return await test_service.get_test(test_id, user_id)