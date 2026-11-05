from typing import Optional
from datetime import datetime
from pydantic import BaseModel


class FeedbackCreateRequest(BaseModel):
    message_id: str
    is_helpful: bool
    comment: Optional[str] = None


class FeedbackResponse(BaseModel):
    id: int
    message_id: str
    user_id: int
    is_helpful: bool
    comment: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
