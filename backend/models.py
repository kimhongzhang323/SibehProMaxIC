"""
Pydantic models for API requests and responses.
"""
from pydantic import BaseModel
from typing import List, Optional, Dict, Any


class ChatRequest(BaseModel):
    message: str
    language: str = "english"


class TaskCreateRequest(BaseModel):
    task_type: str
    user_id: Optional[str] = "default"


class TaskStepRequest(BaseModel):
    task_id: str
    step_data: Optional[Dict[str, Any]] = None


class ChatHistoryRequest(BaseModel):
    session_id: str
    user_id: Optional[str] = "default"
    messages: List[Dict[str, Any]]
    title: Optional[str] = None


class UserProfileUpdate(BaseModel):
    """Model for updating user profile"""
    full_name: Optional[str] = None
    ic_number: Optional[str] = None
    date_of_birth: Optional[str] = None
    gender: Optional[str] = None
    nationality: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    passport_number: Optional[str] = None
    passport_expiry: Optional[str] = None
    passport_issue_date: Optional[str] = None
    employer_name: Optional[str] = None
    company_name: Optional[str] = None
    ssm_number: Optional[str] = None
    job_title: Optional[str] = None
    monthly_income: Optional[str] = None
