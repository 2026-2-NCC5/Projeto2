from typing import List, Dict
from pydantic import BaseModel


class CategoryStat(BaseModel):
    category: str
    count: int
    percentage: float


class FeedbackSummary(BaseModel):
    total_feedbacks: int
    helpful_count: int
    unhelpful_count: int
    satisfaction_rate: float  # porcentagem útil


class DailyMetric(BaseModel):
    date: str
    total_messages: int
    abstentions: int


class DashboardStatsResponse(BaseModel):
    total_conversations: int
    total_messages: int
    total_abstentions: int
    abstention_rate: float  # porcentagem de abstenções
    total_escalations: int
    pending_escalations: int
    resolved_escalations: int
    feedback: FeedbackSummary
    top_categories: List[CategoryStat]
    daily_metrics: List[DailyMetric]
