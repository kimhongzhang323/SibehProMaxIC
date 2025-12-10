"""
Task management API endpoints.
"""
from fastapi import APIRouter, HTTPException, UploadFile, File
from typing import Dict, Any, List
from datetime import datetime
import uuid

from models import TaskCreateRequest, TaskStepRequest
from knowledge_base import AGENTIC_SERVICES
from database import users_table, Query
from routers.verification import run_auto_verification
from routers.users import validate_user_for_service

router = APIRouter(prefix="/task", tags=["Tasks"])

# In-memory storage for active tasks
active_tasks: Dict[str, Dict[str, Any]] = {}
uploaded_documents: Dict[str, List[Dict[str, Any]]] = {}


@router.post("/create")
def create_task(request: TaskCreateRequest):
    """Create a new agentic task"""
    if request.task_type not in AGENTIC_SERVICES:
        raise HTTPException(status_code=400, detail=f"Unknown task type: {request.task_type}")
    
    service = AGENTIC_SERVICES[request.task_type]
    task_id = str(uuid.uuid4())[:8]
    
    task = {
        "id": task_id,
        "type": request.task_type,
        "name": service["name"],
        "icon": service["icon"],
        "description": service["description"],
        "steps": service["steps"],
        "current_step": 1,
        "total_steps": len(service["steps"]),
        "status": "in_progress",
        "user_id": request.user_id or "default",
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat(),
        "documents": []
    }
    
    active_tasks[task_id] = task
    
    return {
        "message": f"Task created: {service['name']}",
        "task": task
    }


@router.post("/start-with-verification")
def start_task_with_auto_verification(request: TaskCreateRequest):
    """Start a task with automatic eligibility verification"""
    user_id = request.user_id or "default"
    
    # Run auto-verification
    verification = run_auto_verification(user_id, request.task_type)
    
    if not verification.get("eligible", False):
        return {
            "success": False,
            "message": "Eligibility check failed",
            "auto_verification": verification,
            "action_required": "Please update your profile to fix the failed checks"
        }
    
    # Also run the standard validation
    validation = validate_user_for_service(user_id, request.task_type)
    
    if not validation["valid"]:
        return {
            "success": False,
            "message": "Profile validation failed",
            "auto_verification": verification,
            "validation": validation,
            "action_required": "Please complete your profile with the missing information"
        }
    
    # Both passed - create the task
    if request.task_type not in AGENTIC_SERVICES:
        raise HTTPException(status_code=400, detail=f"Unknown task type: {request.task_type}")
    
    service = AGENTIC_SERVICES[request.task_type]
    task_id = str(uuid.uuid4())[:8]
    
    task = {
        "id": task_id,
        "type": request.task_type,
        "name": service["name"],
        "icon": service["icon"],
        "description": service["description"],
        "steps": service["steps"],
        "current_step": 2,  # Skip step 1 (eligibility check)
        "total_steps": len(service["steps"]),
        "status": "in_progress",
        "user_id": user_id,
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat(),
        "documents": [],
        "auto_verification": verification,
        "user_data": validation["present_fields"]
    }
    
    active_tasks[task_id] = task
    
    return {
        "success": True,
        "message": f"✅ Eligibility verified! Task started: {service['name']}",
        "task": task,
        "auto_verification": verification,
        "skipped_step": "Step 1 (Eligibility Check) - Auto-completed by agent",
        "current_step": service["steps"][1] if len(service["steps"]) > 1 else None,
        "autofill_data": {f["field"]: f["value"] for f in validation["present_fields"]}
    }


@router.get("/{task_id}")
def get_task(task_id: str):
    """Get task details"""
    task = active_tasks.get(task_id)
    if not task:
        raise HTTPException(status_code=404, detail=f"Task not found: {task_id}")
    return task


@router.get("s")
def get_all_tasks(user_id: str = "default"):
    """Get all tasks for a user"""
    user_tasks = [t for t in active_tasks.values() if t.get("user_id") == user_id]
    return {"tasks": user_tasks}


@router.post("/{task_id}/advance")
def advance_task(task_id: str):
    """Advance to next step"""
    task = active_tasks.get(task_id)
    if not task:
        raise HTTPException(status_code=404, detail=f"Task not found: {task_id}")
    
    if task["current_step"] >= task["total_steps"]:
        task["status"] = "completed"
        task["updated_at"] = datetime.now().isoformat()
        return {
            "completed": True,
            "message": f"🎉 Task completed: {task['name']}!",
            "task": task
        }
    
    task["current_step"] += 1
    task["updated_at"] = datetime.now().isoformat()
    
    next_step = task["steps"][task["current_step"] - 1] if task["current_step"] <= len(task["steps"]) else None
    
    return {
        "completed": False,
        "message": f"Moved to step {task['current_step']}",
        "task": task,
        "next_step": next_step
    }


@router.post("/{task_id}/cancel")
def cancel_task(task_id: str):
    """Cancel a task"""
    task = active_tasks.get(task_id)
    if not task:
        raise HTTPException(status_code=404, detail=f"Task not found: {task_id}")
    
    task["status"] = "cancelled"
    task["updated_at"] = datetime.now().isoformat()
    
    return {"message": f"Task cancelled: {task['name']}", "task": task}


@router.delete("/{task_id}")
def delete_task(task_id: str):
    """Delete a task"""
    if task_id not in active_tasks:
        raise HTTPException(status_code=404, detail=f"Task not found: {task_id}")
    del active_tasks[task_id]
    return {"message": f"Task deleted: {task_id}"}


@router.post("/{task_id}/upload")
async def upload_document(task_id: str, file: UploadFile = File(...)):
    """Upload document for a task"""
    task = active_tasks.get(task_id)
    if not task:
        raise HTTPException(status_code=404, detail=f"Task not found: {task_id}")
    
    doc_id = str(uuid.uuid4())[:8]
    doc = {
        "id": doc_id,
        "filename": file.filename,
        "content_type": file.content_type,
        "uploaded_at": datetime.now().isoformat()
    }
    
    task["documents"].append(doc)
    
    if task_id not in uploaded_documents:
        uploaded_documents[task_id] = []
    uploaded_documents[task_id].append(doc)
    
    return {"message": f"Document uploaded: {file.filename}", "document": doc}


@router.get("/{task_id}/documents")
def get_task_documents(task_id: str):
    """Get documents for a task"""
    return {"documents": uploaded_documents.get(task_id, [])}
