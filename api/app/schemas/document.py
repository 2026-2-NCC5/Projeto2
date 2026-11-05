from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel


class DocumentBase(BaseModel):
    title: str
    slug: str
    category: str
    official_source: str
    section: str
    version: str = "v1.0"
    summary: Optional[str] = None
    is_active: bool = True


class DocumentCreate(DocumentBase):
    content: str
    file_path: Optional[str] = None


class DocumentToggleActiveRequest(BaseModel):
    is_active: bool


class DocumentResponse(DocumentBase):
    id: int
    file_path: str
    updated_at: datetime
    created_at: datetime

    class Config:
        from_attributes = True


class DocumentChunkSchema(BaseModel):
    document_slug: str
    document_title: str
    official_source: str
    section: str
    updated_at: str
    content: str
    similarity_score: float


class StudentDocumentResponse(BaseModel):
    id: int
    user_id: int
    filename: str
    original_filename: str
    file_size: int
    mime_type: str
    category: str
    status: str
    analysis_notes: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class StudentDocumentUploadResponse(BaseModel):
    document: StudentDocumentResponse
    message: str
    ai_feedback: Optional[str] = None

