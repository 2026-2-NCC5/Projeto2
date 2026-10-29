from typing import Optional
from datetime import datetime
from pydantic import BaseModel
from app.models.escalation import EscalationStatus, EscalationPriority


class EscalationCreateRequest(BaseModel):
    conversation_id: str
    reason: str
    user_notes: Optional[str] = None
    priority: EscalationPriority = EscalationPriority.MEDIA
    modality: str = "ONLINE"  # PRESENCIAL ou ONLINE


class EscalationResolveRequest(BaseModel):
    resolution_notes: str
    status: EscalationStatus = EscalationStatus.RESOLVIDO


class EscalationResponse(BaseModel):
    id: int
    ticket_number: Optional[str] = None
    modality: str = "ONLINE"
    conversation_id: str
    student_id: int
    student_name: Optional[str] = None
    student_ra: Optional[str] = None
    student_email: Optional[str] = None
    student_course: Optional[str] = None
    student_semester: Optional[int] = None
    student_campus: Optional[str] = None
    assigned_attendant_id: Optional[int] = None
    assigned_attendant_name: Optional[str] = None
    reason: str
    user_notes: Optional[str] = None
    priority: EscalationPriority
    status: EscalationStatus
    resolution_notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    resolved_at: Optional[datetime] = None
    service_rating: Optional[int] = None
    service_rating_comment: Optional[str] = None

    class Config:
        from_attributes = True

class EscalationRateRequest(BaseModel):
    rating: int  # 1 a 5
    comment: Optional[str] = None


class AttendantMessageRequest(BaseModel):
    content: str
