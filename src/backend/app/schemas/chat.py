from typing import Optional, List, Any
from datetime import datetime
from pydantic import BaseModel
from app.models.chat import MessageSender


class RetrievedChunkSchema(BaseModel):
    document_title: str
    official_source: str
    section: str
    updated_at: str
    snippet: str
    similarity: float


class ChatQueryRequest(BaseModel):
    conversation_id: Optional[str] = None
    query: str


class ChatMessageResponse(BaseModel):
    id: str
    conversation_id: str
    sender: MessageSender
    content: str
    is_abstained: bool = False
    confidence_score: Optional[float] = None
    threshold_used: Optional[float] = None
    retrieved_chunks: Optional[List[dict]] = None
    source_citation: Optional[str] = None
    suggested_action: Optional[str] = None
    agent_version: str
    created_at: datetime
    feedback: Optional["FeedbackInMessage"] = None

    class Config:
        from_attributes = True


class FeedbackInMessage(BaseModel):
    id: int
    is_helpful: bool
    comment: Optional[str] = None

    class Config:
        from_attributes = True


class ConversationSummaryResponse(BaseModel):
    id: str
    title: str
    created_at: datetime
    updated_at: datetime
    last_message: Optional[str] = None

    class Config:
        from_attributes = True


class ConversationDetailResponse(BaseModel):
    id: str
    title: str
    created_at: datetime
    updated_at: datetime
    messages: List[ChatMessageResponse]

    class Config:
        from_attributes = True


ChatMessageResponse.model_rebuild()
