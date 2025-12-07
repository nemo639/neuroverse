from datetime import datetime, timedelta, timezone
from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, func, desc
from sqlalchemy.orm import selectinload
from fastapi import HTTPException, status
import random

from app.models.test import Test, TestResult, Report, TestCategoryEnum, TestStatusEnum, RiskLevelEnum
from app.schemas.test import (
    TestCreate, TestResponse, TestDetailResponse, TestListResponse,
    TestResultCreate, TestResultResponse, TestResultListResponse,
    ReportCreate, ReportResponse, DashboardStats, DashboardResponse, RecentTest,
    XAIResponse, XAIModuleData
)


class TestService:
    """Service for handling test operations."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    # ============== Test Management ==============
    
    async def create_test(self, user_id: str, test_data: TestCreate) -> Test:
        """Create a new test session."""
        test = Test(
            user_id=user_id,
            category=test_data.category,
            test_name=test_data.test_name,
            status=TestStatusEnum.PENDING,
            device_info=test_data.device_info,
            app_version=test_data.app_version
        )
        
        self.db.add(test)
        await self.db.flush()
        
        return test
    
    async def start_test(self, test_id: str, user_id: str) -> Test:
        """Start a test session."""
        test = await self._get_test(test_id, user_id)
        
        if test.status != TestStatusEnum.PENDING:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Test already started or completed"
            )
        
        test.status = TestStatusEnum.IN_PROGRESS
        test.started_at = datetime.now(timezone.utc)
        
        await self.db.flush()
        
        return test
    
    async def submit_test_item(
        self,
        test_id: str,
        user_id: str,
        item_data: TestResultCreate
    ) -> TestResult:
        """Submit a single test item result."""
        test = await self._get_test(test_id, user_id)
        
        if test.status != TestStatusEnum.IN_PROGRESS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Test must be in progress to submit items"
            )
        
        # Process the item and generate score
        score, is_abnormal, notes = self._analyze_test_item(
            item_data.item_name,
            item_data.item_type,
            item_data.raw_value,
            item_data.processed_value,
            test.category
        )
        
        result = TestResult(
            test_id=test_id,
            item_name=item_data.item_name,
            item_type=item_data.item_type,
            raw_value=item_data.raw_value,
            processed_value=item_data.processed_value,
            score=score,
            is_abnormal=is_abnormal,
            notes=notes
        )
        
        self.db.add(result)
        await self.db.flush()
        
        return result
    
    async def submit_test_items(
        self,
        test_id: str,
        user_id: str,
        items: List[TestResultCreate]
    ) -> List[TestResult]:
        """Submit multiple test item results at once."""
        results = []
        for item_data in items:
            result = await self.submit_test_item(test_id, user_id, item_data)
            results.append(result)
        return results
    
    async def get_test_results(
        self,
        test_id: str,
        user_id: str
    ) -> TestResultListResponse:
        """Get all results for a test."""
        # Verify test ownership
        await self._get_test(test_id, user_id)
        
        result = await self.db.execute(
            select(TestResult)
            .where(TestResult.test_id == test_id)
            .order_by(TestResult.created_at)
        )
        results = result.scalars().all()
        
        abnormal_count = sum(1 for r in results if r.is_abnormal)
        
        return TestResultListResponse(
            results=[self._result_to_response(r) for r in results],
            total=len(results),
            abnormal_count=abnormal_count
        )
    
    async def complete_test(
        self,
        test_id: str,
        user_id: str,
        raw_data: dict = None
    ) -> Test:
        """Complete a test and generate overall results."""
        test = await self._get_test(test_id, user_id)
        
        if test.status != TestStatusEnum.IN_PROGRESS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Test not in progress"
            )
        
        test.completed_at = datetime.now(timezone.utc)
        test.status = TestStatusEnum.COMPLETED
        
        if test.started_at:
            started = test.started_at
            completed = test.completed_at
            if started.tzinfo is None:
                started = started.replace(tzinfo=timezone.utc)
            test.duration_seconds = int((completed - started).total_seconds())
        
        if raw_data:
            test.raw_data = raw_data
        
        # Get all test results and calculate overall score
        result = await self.db.execute(
            select(TestResult).where(TestResult.test_id == test_id)
        )
        test_results = result.scalars().all()
        
        # Calculate overall score from individual results
        if test_results:
            scores = [r.score for r in test_results if r.score is not None]
            if scores:
                test.score = round(sum(scores) / len(scores), 1)
            else:
                test.score = round(random.uniform(60, 95), 1)
        else:
            # No individual results, generate mock score
            test.score = round(random.uniform(60, 95), 1)
        
        test.risk_percentage = round(100 - test.score, 1)
        test.confidence_score = round(random.uniform(0.85, 0.98), 2)
        
        # Set risk level
        if test.risk_percentage < 25:
            test.risk_level = RiskLevelEnum.LOW
        elif test.risk_percentage < 50:
            test.risk_level = RiskLevelEnum.MODERATE
        elif test.risk_percentage < 75:
            test.risk_level = RiskLevelEnum.HIGH
        else:
            test.risk_level = RiskLevelEnum.CRITICAL
        
        # Generate AI analysis
        await self._process_test_results(test, test_results)
        
        await self.db.flush()
        
        return test
    
    async def get_test(self, test_id: str, user_id: str) -> TestDetailResponse:
        """Get test details with results."""
        # Get test with results loaded
        result = await self.db.execute(
            select(Test)
            .options(selectinload(Test.results))
            .where(
                and_(
                    Test.id == test_id,
                    Test.user_id == user_id
                )
            )
        )
        test = result.scalar_one_or_none()
        
        if not test:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Test not found"
            )
        
        return self._to_detail_response(test)
    
    async def get_user_tests(
        self,
        user_id: str,
        category: Optional[TestCategoryEnum] = None,
        status: Optional[TestStatusEnum] = None,
        limit: int = 50
    ) -> TestListResponse:
        """Get user's tests."""
        query = select(Test).where(Test.user_id == user_id)
        
        if category:
            query = query.where(Test.category == category)
        if status:
            query = query.where(Test.status == status)
        
        query = query.order_by(desc(Test.created_at)).limit(limit)
        
        result = await self.db.execute(query)
        tests = result.scalars().all()
        
        total = len(tests)
        completed = sum(1 for t in tests if t.status == TestStatusEnum.COMPLETED)
        pending = sum(1 for t in tests if t.status == TestStatusEnum.PENDING)
        
        return TestListResponse(
            tests=[self._to_response(t) for t in tests],
            total=total,
            completed=completed,
            pending=pending
        )
    
    async def get_recent_tests(self, user_id: str, limit: int = 5) -> List[RecentTest]:
        """Get user's recent tests."""
        result = await self.db.execute(
            select(Test)
            .where(Test.user_id == user_id)
            .order_by(desc(Test.created_at))
            .limit(limit)
        )
        tests = result.scalars().all()
        
        return [
            RecentTest(
                id=t.id,
                test_name=t.test_name,
                category=t.category,
                status=t.status,
                score=t.score,
                completed_at=t.completed_at
            )
            for t in tests
        ]
    
    # ============== Dashboard ==============
    
    async def get_dashboard(self, user_id: str) -> DashboardResponse:
        """Get user dashboard data."""
        result = await self.db.execute(
            select(Test).where(
                and_(
                    Test.user_id == user_id,
                    Test.status == TestStatusEnum.COMPLETED
                )
            ).order_by(desc(Test.completed_at))
        )
        completed_tests = result.scalars().all()
        
        # Calculate category scores
        category_scores = {}
        for category in TestCategoryEnum:
            cat_tests = [t for t in completed_tests if t.category == category]
            if cat_tests:
                category_scores[category.value] = sum(t.score or 0 for t in cat_tests) / len(cat_tests)
        
        # Overall risk calculation
        if category_scores:
            avg_score = sum(category_scores.values()) / len(category_scores)
            overall_risk_score = 100 - avg_score
            
            if overall_risk_score < 25:
                risk_level = RiskLevelEnum.LOW
            elif overall_risk_score < 50:
                risk_level = RiskLevelEnum.MODERATE
            elif overall_risk_score < 75:
                risk_level = RiskLevelEnum.HIGH
            else:
                risk_level = RiskLevelEnum.CRITICAL
        else:
            overall_risk_score = 0
            risk_level = RiskLevelEnum.LOW
        
        # Pending tests count
        pending_result = await self.db.execute(
            select(func.count(Test.id)).where(
                and_(
                    Test.user_id == user_id,
                    Test.status == TestStatusEnum.PENDING
                )
            )
        )
        pending_count = pending_result.scalar() or 0
        
        stats = DashboardStats(
            overall_risk_score=round(overall_risk_score, 1),
            overall_risk_level=risk_level,
            tests_completed=len(completed_tests),
            tests_pending=pending_count,
            last_test_date=completed_tests[0].completed_at if completed_tests else None,
            speech_score=category_scores.get("speech_language"),
            cognitive_score=category_scores.get("cognitive_memory"),
            motor_score=category_scores.get("motor_functions"),
            gait_score=category_scores.get("gait_movement"),
            risk_trend="stable",
            trend_percentage=0
        )
        
        recent_tests = await self.get_recent_tests(user_id, 5)
        
        return DashboardResponse(
            stats=stats,
            recent_tests=recent_tests,
            upcoming_tests=[],
            wellness_insight="Complete all tests regularly for accurate risk assessment."
        )
    
    # ============== XAI ==============
    
    async def get_xai_data(self, user_id: str, category: TestCategoryEnum) -> XAIModuleData:
        """Get XAI (Explainable AI) data for a category."""
        result = await self.db.execute(
            select(Test)
            .options(selectinload(Test.results))
            .where(
                and_(
                    Test.user_id == user_id,
                    Test.category == category,
                    Test.status == TestStatusEnum.COMPLETED
                )
            ).order_by(desc(Test.completed_at)).limit(1)
        )
        test = result.scalar_one_or_none()
        
        return self._get_mock_xai_data(category, test)
    
    # ============== Reports ==============
    
    async def create_report(
        self,
        user_id: str,
        report_data: ReportCreate
    ) -> Report:
        """Create a comprehensive report."""
        result = await self.db.execute(
            select(Test).where(
                and_(
                    Test.user_id == user_id,
                    Test.status == TestStatusEnum.COMPLETED
                )
            )
        )
        tests = result.scalars().all()
        
        # Calculate scores
        category_scores = {}
        for category in TestCategoryEnum:
            cat_tests = [t for t in tests if t.category == category]
            if cat_tests:
                category_scores[category.value] = sum(t.score or 0 for t in cat_tests) / len(cat_tests)
        
        # Calculate overall risk
        if category_scores:
            avg_score = sum(category_scores.values()) / len(category_scores)
            risk_score = 100 - avg_score
        else:
            risk_score = 0
        
        if risk_score < 25:
            risk_level = RiskLevelEnum.LOW
        elif risk_score < 50:
            risk_level = RiskLevelEnum.MODERATE
        elif risk_score < 75:
            risk_level = RiskLevelEnum.HIGH
        else:
            risk_level = RiskLevelEnum.CRITICAL
        
        report = Report(
            user_id=user_id,
            report_type=report_data.report_type,
            title=f"{report_data.report_type.title()} Health Report",
            overall_risk_level=risk_level,
            overall_risk_score=risk_score,
            speech_score=category_scores.get("speech_language"),
            cognitive_score=category_scores.get("cognitive_memory"),
            motor_score=category_scores.get("motor_functions"),
            gait_score=category_scores.get("gait_movement"),
            facial_score=category_scores.get("facial_analysis"),
            summary="Comprehensive neurological health assessment based on multi-modal biomarker analysis.",
            recommendations=self._generate_recommendations(risk_level, category_scores),
            ai_interpretation=self._generate_ai_interpretation(risk_level, category_scores),
            key_findings=self._generate_key_findings(category_scores),
            period_start=report_data.period_start,
            period_end=report_data.period_end
        )
        
        self.db.add(report)
        await self.db.flush()
        
        return report
    
    async def get_user_reports(
        self,
        user_id: str,
        limit: int = 20
    ) -> List[ReportResponse]:
        """Get user's reports."""
        result = await self.db.execute(
            select(Report)
            .where(Report.user_id == user_id)
            .order_by(desc(Report.created_at))
            .limit(limit)
        )
        reports = result.scalars().all()
        
        return [self._report_to_response(r) for r in reports]
    
    # ============== Private Methods ==============
    
    async def _get_test(self, test_id: str, user_id: str) -> Test:
        """Get test by ID and verify ownership."""
        result = await self.db.execute(
            select(Test).where(
                and_(
                    Test.id == test_id,
                    Test.user_id == user_id
                )
            )
        )
        test = result.scalar_one_or_none()
        
        if not test:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Test not found"
            )
        
        return test
    
    def _analyze_test_item(
        self,
        item_name: str,
        item_type: str,
        raw_value: Optional[str],
        processed_value: Optional[float],
        category: TestCategoryEnum
    ) -> tuple:
        """Analyze a single test item and return (score, is_abnormal, notes)."""
        
        # If processed_value is provided, use it for scoring
        if processed_value is not None:
            # Normalize to 0-100 score (assuming processed_value is 0-1)
            if processed_value <= 1:
                score = round(processed_value * 100, 1)
            else:
                score = min(round(processed_value, 1), 100)
        else:
            # Generate mock score based on category and item type
            base_score = random.uniform(60, 95)
            score = round(base_score, 1)
        
        # Determine if abnormal (below threshold)
        is_abnormal = score < 60
        
        # Generate notes based on score
        if score >= 90:
            notes = f"Excellent performance on {item_name}"
        elif score >= 70:
            notes = f"Good performance on {item_name}"
        elif score >= 60:
            notes = f"Acceptable performance on {item_name}, room for improvement"
        else:
            notes = f"Below threshold on {item_name}, may indicate concern"
        
        return score, is_abnormal, notes
    
    async def _process_test_results(self, test: Test, results: List[TestResult]) -> None:
        """Process test results and generate AI analysis."""
        
        # Count abnormal results
        abnormal_count = sum(1 for r in results if r.is_abnormal)
        total_count = len(results) if results else 0
        
        # Mock AI prediction
        test.ai_prediction = {
            "predicted_class": test.risk_level.value if test.risk_level else "low",
            "probabilities": {
                "low": round(random.uniform(0.1, 0.3), 2),
                "moderate": round(random.uniform(0.2, 0.4), 2),
                "high": round(random.uniform(0.1, 0.3), 2),
            },
            "total_items": total_count,
            "abnormal_items": abnormal_count
        }
        
        # Mock biomarkers
        test.biomarkers = self._get_mock_biomarkers(test.category)
        
        # Mock SHAP values
        test.shap_values = self._get_mock_shap_values(test.category)
        
        # Mock feature importance
        test.feature_importance = self._get_mock_feature_importance(test.category)
    
    def _get_mock_biomarkers(self, category: TestCategoryEnum) -> dict:
        """Get mock biomarkers for a category."""
        biomarkers = {
            TestCategoryEnum.SPEECH_LANGUAGE: {
                "pause_frequency": round(random.uniform(2, 8), 1),
                "avg_pause_duration": round(random.uniform(0.5, 2.5), 2),
                "speech_rate": round(random.uniform(100, 160), 0),
                "pitch_variance": round(random.uniform(10, 50), 1),
                "voice_tremor": round(random.uniform(0, 5), 2)
            },
            TestCategoryEnum.COGNITIVE_MEMORY: {
                "response_time": round(random.uniform(0.5, 2.0), 2),
                "recall_accuracy": round(random.uniform(60, 95), 1),
                "attention_score": round(random.uniform(70, 100), 1),
                "working_memory": round(random.uniform(5, 10), 0),
                "stroop_interference": round(random.uniform(50, 150), 0)
            },
            TestCategoryEnum.MOTOR_FUNCTIONS: {
                "tremor_amplitude": round(random.uniform(0.5, 5), 2),
                "drawing_accuracy": round(random.uniform(70, 98), 1),
                "tap_regularity": round(random.uniform(80, 99), 1),
                "pressure_variance": round(random.uniform(5, 30), 1),
                "movement_speed": round(random.uniform(60, 100), 1)
            },
            TestCategoryEnum.GAIT_MOVEMENT: {
                "stride_length": round(random.uniform(50, 80), 1),
                "gait_speed": round(random.uniform(0.8, 1.4), 2),
                "step_regularity": round(random.uniform(85, 99), 1),
                "balance_score": round(random.uniform(70, 100), 1),
                "turn_speed": round(random.uniform(0.5, 1.5), 2)
            },
            TestCategoryEnum.FACIAL_ANALYSIS: {
                "blink_rate": round(random.uniform(8, 20), 0),
                "smile_velocity": round(random.uniform(0.3, 1.0), 2),
                "expression_range": round(random.uniform(60, 100), 1),
                "asymmetry_score": round(random.uniform(0, 15), 1),
                "micro_expressions": round(random.uniform(3, 10), 0)
            }
        }
        return biomarkers.get(category, {})
    
    def _get_mock_shap_values(self, category: TestCategoryEnum) -> list:
        """Get mock SHAP values for a category."""
        features = {
            TestCategoryEnum.SPEECH_LANGUAGE: [
                ("Speech Pauses", 0.24), ("Pause Duration", 0.18), ("Voice Tremor", 0.15),
                ("Articulation Rate", 0.12), ("Pitch Variance", 0.08)
            ],
            TestCategoryEnum.COGNITIVE_MEMORY: [
                ("Response Time", 0.26), ("Recall Accuracy", 0.19), ("Stroop Interference", 0.17),
                ("Working Memory", 0.11), ("Attention Span", 0.07)
            ],
            TestCategoryEnum.MOTOR_FUNCTIONS: [
                ("Tremor Amplitude", 0.28), ("Drawing Speed", 0.20), ("Line Smoothness", 0.16),
                ("Pressure Variance", 0.10), ("Spiral Accuracy", 0.09)
            ],
            TestCategoryEnum.GAIT_MOVEMENT: [
                ("Gait Speed", 0.25), ("Stride Length", 0.20), ("Step Regularity", 0.18),
                ("Balance Score", 0.12), ("Turn Speed", 0.08)
            ],
            TestCategoryEnum.FACIAL_ANALYSIS: [
                ("Blink Rate", 0.22), ("Smile Velocity", 0.19), ("Expression Range", 0.14),
                ("Eye Movement", 0.11), ("Micro Expressions", 0.08)
            ]
        }
        
        return [
            {"feature": f[0], "value": f[1], "impact": "high" if f[1] > 0.2 else "medium" if f[1] > 0.1 else "low"}
            for f in features.get(category, [])
        ]
    
    def _get_mock_feature_importance(self, category: TestCategoryEnum) -> list:
        """Get mock feature importance for a category."""
        shap_values = self._get_mock_shap_values(category)
        return [
            {"feature": sv["feature"], "importance": sv["value"], "rank": i + 1}
            for i, sv in enumerate(shap_values)
        ]
    
    def _get_mock_xai_data(self, category: TestCategoryEnum, test: Optional[Test]) -> XAIModuleData:
        """Get mock XAI data for a category."""
        module_names = {
            TestCategoryEnum.SPEECH_LANGUAGE: "speech",
            TestCategoryEnum.COGNITIVE_MEMORY: "cognitive",
            TestCategoryEnum.MOTOR_FUNCTIONS: "motor",
            TestCategoryEnum.GAIT_MOVEMENT: "gait",
            TestCategoryEnum.FACIAL_ANALYSIS: "facial"
        }
        
        gradient_colors = {
            TestCategoryEnum.SPEECH_LANGUAGE: ["#3B82F6", "#1D4ED8"],
            TestCategoryEnum.COGNITIVE_MEMORY: ["#8B5CF6", "#6D28D9"],
            TestCategoryEnum.MOTOR_FUNCTIONS: ["#F97316", "#EA580C"],
            TestCategoryEnum.GAIT_MOVEMENT: ["#10B981", "#059669"],
            TestCategoryEnum.FACIAL_ANALYSIS: ["#EC4899", "#DB2777"]
        }
        
        interpretations = {
            TestCategoryEnum.SPEECH_LANGUAGE: [
                "Speech pauses detected at higher frequency than baseline",
                "Voice tremor patterns indicate potential early markers",
                "Articulation rate within normal range"
            ],
            TestCategoryEnum.COGNITIVE_MEMORY: [
                "Response times show slight delay compared to age group",
                "Word recall accuracy below optimal threshold",
                "Working memory performance is stable"
            ],
            TestCategoryEnum.MOTOR_FUNCTIONS: [
                "Tremor amplitude elevated during fine motor tasks",
                "Drawing speed slower than baseline measurements",
                "Pressure consistency shows minor variations"
            ],
            TestCategoryEnum.GAIT_MOVEMENT: [
                "Gait speed within acceptable parameters",
                "Step regularity shows consistent patterns",
                "Balance metrics indicate good stability"
            ],
            TestCategoryEnum.FACIAL_ANALYSIS: [
                "Blink rate lower than typical range",
                "Smile formation velocity reduced",
                "Expression range within normal limits"
            ]
        }
        
        shap_values = test.shap_values if test and test.shap_values else self._get_mock_shap_values(category)
        feature_importance = test.feature_importance if test and test.feature_importance else self._get_mock_feature_importance(category)
        
        return XAIModuleData(
            module=module_names.get(category, "unknown"),
            shap_values=shap_values,
            feature_importance=feature_importance,
            visualization_data={"type": "chart", "data": []},
            interpretation=interpretations.get(category, []),
            gradient_colors=gradient_colors.get(category, ["#6B7280", "#4B5563"])
        )
    
    def _result_to_response(self, result: TestResult) -> TestResultResponse:
        """Convert TestResult model to response schema."""
        return TestResultResponse(
            id=result.id,
            test_id=result.test_id,
            item_name=result.item_name,
            item_type=result.item_type,
            raw_value=result.raw_value,
            processed_value=result.processed_value,
            score=result.score,
            is_abnormal=result.is_abnormal,
            notes=result.notes,
            created_at=result.created_at
        )
    
    def _to_response(self, test: Test) -> TestResponse:
        """Convert Test model to response schema."""
        return TestResponse(
            id=test.id,
            category=test.category,
            test_name=test.test_name,
            status=test.status,
            score=test.score,
            risk_level=test.risk_level,
            risk_percentage=test.risk_percentage,
            confidence_score=test.confidence_score,
            started_at=test.started_at,
            completed_at=test.completed_at,
            duration_seconds=test.duration_seconds,
            created_at=test.created_at
        )
    
    def _to_detail_response(self, test: Test) -> TestDetailResponse:
        """Convert Test model to detailed response schema."""
        results = None
        if hasattr(test, 'results') and test.results:
            results = [self._result_to_response(r) for r in test.results]
        
        return TestDetailResponse(
            id=test.id,
            category=test.category,
            test_name=test.test_name,
            status=test.status,
            score=test.score,
            risk_level=test.risk_level,
            risk_percentage=test.risk_percentage,
            confidence_score=test.confidence_score,
            started_at=test.started_at,
            completed_at=test.completed_at,
            duration_seconds=test.duration_seconds,
            created_at=test.created_at,
            ai_prediction=test.ai_prediction,
            biomarkers=test.biomarkers,
            shap_values=test.shap_values,
            feature_importance=test.feature_importance,
            results=results
        )
    
    def _report_to_response(self, report: Report) -> ReportResponse:
        """Convert Report model to response schema."""
        return ReportResponse(
            id=report.id,
            report_type=report.report_type,
            title=report.title,
            overall_risk_level=report.overall_risk_level,
            overall_risk_score=report.overall_risk_score,
            speech_score=report.speech_score,
            cognitive_score=report.cognitive_score,
            motor_score=report.motor_score,
            gait_score=report.gait_score,
            facial_score=report.facial_score,
            summary=report.summary,
            recommendations=report.recommendations,
            ai_interpretation=report.ai_interpretation,
            key_findings=report.key_findings,
            period_start=report.period_start,
            period_end=report.period_end,
            pdf_path=report.pdf_path,
            created_at=report.created_at
        )
    
    def _generate_recommendations(self, risk_level: RiskLevelEnum, scores: dict) -> list:
        """Generate recommendations based on risk level."""
        recommendations = [
            "Continue regular neurological assessments",
            "Maintain physical activity and mental exercises",
            "Ensure adequate sleep and nutrition"
        ]
        
        if risk_level in [RiskLevelEnum.MODERATE, RiskLevelEnum.HIGH]:
            recommendations.append("Consider consulting a neurologist for detailed evaluation")
        
        if risk_level == RiskLevelEnum.CRITICAL:
            recommendations.insert(0, "Urgent: Schedule appointment with healthcare provider")
        
        return recommendations
    
    def _generate_ai_interpretation(self, risk_level: RiskLevelEnum, scores: dict) -> str:
        """Generate AI interpretation text."""
        level_text = {
            RiskLevelEnum.LOW: "indicates minimal indicators of neurological concerns",
            RiskLevelEnum.MODERATE: "shows some markers that warrant continued monitoring",
            RiskLevelEnum.HIGH: "reveals patterns that suggest consulting a healthcare professional",
            RiskLevelEnum.CRITICAL: "indicates urgent need for professional medical evaluation"
        }
        
        return f"Based on multi-modal biomarker analysis, your assessment {level_text.get(risk_level, '')}. This is a screening tool and not a diagnosis."
    
    def _generate_key_findings(self, scores: dict) -> list:
        """Generate key findings list."""
        findings = []
        
        for category, score in scores.items():
            if score and score < 70:
                findings.append(f"{category.replace('_', ' ').title()}: Below optimal threshold")
            elif score and score >= 90:
                findings.append(f"{category.replace('_', ' ').title()}: Excellent performance")
        
        if not findings:
            findings.append("All assessments within normal ranges")
        
        return findings