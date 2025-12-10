"""
Digital ID Pro Max - Backend API
FastAPI application for Malaysian Government Digital Services Assistant

Modular Structure:
- config.py: API keys, schemas, validation requirements
- database.py: TinyDB setup and helpers
- models.py: Pydantic request/response models
- knowledge_base.py: Government services, agentic tasks, eligibility rules
- prompts.py: AI system prompts in multiple languages
- routers/: API endpoint modules
  - chat.py: Chat, TTS, and location endpoints
  - tasks.py: Task management endpoints  
  - users.py: User profile and validation endpoints
  - verification.py: Auto-verification agent logic
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from pydantic import BaseModel
import httpx
import json
import re
import uuid
from datetime import datetime
from typing import Dict, Any, List

# Import configuration
from config import (
    GEMINI_API_KEY, 
    ELEVENLABS_API_KEY, 
    GOOGLE_MAPS_API_KEY,
    VOICE_IDS,
    USER_PROFILE_SCHEMA,
    SERVICE_VALIDATION_REQUIREMENTS
)

# Import database
from database import users_table, Query

# Import knowledge base
from knowledge_base import GOVERNMENT_SERVICES, AGENTIC_SERVICES

# Import prompts
from prompts import SYSTEM_PROMPTS

# Import models
from models import ChatRequest, TaskCreateRequest, ChatHistoryRequest

# Initialize FastAPI app
app = FastAPI(
    title="Digital ID Pro Max API",
    description="Malaysian Government Digital Services Assistant",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory storage
active_tasks: Dict[str, Dict[str, Any]] = {}
chat_history: Dict[str, Dict[str, Any]] = {}
uploaded_documents: Dict[str, List[Dict[str, Any]]] = {}


# ============== UTILITY FUNCTIONS ==============

def sanitize_input(text: str) -> str:
    """Sanitize user input to prevent prompt injection"""
    dangerous_patterns = [
        r'ignore\s+(all\s+)?(previous\s+)?instructions?',
        r'forget\s+instructions?',
        r'system\s*:',
        r'<\/?system'
    ]
    sanitized = text
    for pattern in dangerous_patterns:
        sanitized = re.sub(pattern, '[filtered]', sanitized, flags=re.IGNORECASE)
    return sanitized


def get_field_label(field_name: str) -> str:
    """Get human-readable label for a field"""
    for category, fields in USER_PROFILE_SCHEMA.items():
        if field_name in fields:
            return fields[field_name]["label"]
    return field_name.replace("_", " ").title()


# ============== HEALTH CHECK ==============

@app.get("/")
def health_check():
    return {"status": "ok", "service": "Digital ID Pro Max API", "version": "1.0.0"}


@app.get("/health")
def health():
    return {"status": "healthy"}


# ============== CHAT ENDPOINTS ==============

@app.post("/chat")
async def chat(request: ChatRequest):
    """Main chat endpoint with Gemini AI"""
    if not GEMINI_API_KEY:
        raise HTTPException(status_code=500, detail="Gemini API key not configured")
    
    language = request.language.lower()
    if language not in SYSTEM_PROMPTS:
        language = "english"
    
    sanitized_message = sanitize_input(request.message)
    system_prompt = SYSTEM_PROMPTS[language]
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(
            f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={GEMINI_API_KEY}",
            json={
                "contents": [
                    {"role": "user", "parts": [{"text": f"{system_prompt}\n\nUser message: {sanitized_message}"}]}
                ],
                "generationConfig": {
                    "temperature": 0.7,
                    "maxOutputTokens": 1024,
                }
            }
        )
        
        if response.status_code != 200:
            raise HTTPException(status_code=response.status_code, detail="Gemini API error")
        
        data = response.json()
        text = data.get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "")
        
        try:
            json_match = re.search(r'\{[\s\S]*\}', text)
            if json_match:
                return json.loads(json_match.group())
        except json.JSONDecodeError:
            pass
        
        return {"response": text, "type": "text"}


@app.post("/chat/simple")
async def simple_chat(request: ChatRequest):
    """Simple chat returning text only"""
    result = await chat(request)
    if isinstance(result, dict) and "response" in result:
        return {"response": result["response"]}
    return {"response": str(result)}


class TTSRequest(BaseModel):
    text: str
    language: str = "english"


@app.post("/tts")
async def text_to_speech(request: TTSRequest):
    """Text-to-speech using ElevenLabs"""
    if not ELEVENLABS_API_KEY:
        raise HTTPException(status_code=500, detail="ElevenLabs API key not configured")
    
    voice_id = VOICE_IDS.get(request.language.lower(), VOICE_IDS["english"])
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(
            f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}",
            headers={
                "xi-api-key": ELEVENLABS_API_KEY,
                "Content-Type": "application/json"
            },
            json={
                "text": request.text,
                "model_id": "eleven_multilingual_v2",
                "voice_settings": {"stability": 0.5, "similarity_boost": 0.75}
            }
        )
        
        if response.status_code != 200:
            raise HTTPException(status_code=response.status_code, detail="TTS API error")
        
        return Response(content=response.content, media_type="audio/mpeg")


# ============== LOCATION ENDPOINTS ==============

@app.get("/locations/{service}")
async def get_locations(service: str, lat: float = 3.139, lng: float = 101.6869):
    """Get nearby government office locations"""
    if not GOOGLE_MAPS_API_KEY:
        raise HTTPException(status_code=500, detail="Google Maps API key not configured")
    
    service_info = GOVERNMENT_SERVICES.get(service.lower())
    if not service_info:
        raise HTTPException(status_code=404, detail=f"Unknown service: {service}")
    
    async with httpx.AsyncClient(timeout=15.0) as client:
        response = await client.get(
            "https://maps.googleapis.com/maps/api/place/nearbysearch/json",
            params={
                "location": f"{lat},{lng}",
                "radius": 10000,
                "keyword": service_info["search_term"],
                "key": GOOGLE_MAPS_API_KEY
            }
        )
        
        if response.status_code != 200:
            raise HTTPException(status_code=response.status_code, detail="Maps API error")
        
        data = response.json()
        locations = []
        for place in data.get("results", [])[:5]:
            locations.append({
                "name": place.get("name"),
                "address": place.get("vicinity"),
                "lat": place.get("geometry", {}).get("location", {}).get("lat"),
                "lng": place.get("geometry", {}).get("location", {}).get("lng"),
                "rating": place.get("rating"),
                "open_now": place.get("opening_hours", {}).get("open_now")
            })
        
        return {
            "service": service_info["name"],
            "locations": locations,
            "website": service_info["website"],
            "hotline": service_info["hotline"]
        }


class FindOfficeRequest(BaseModel):
    service: str
    latitude: float = 3.139
    longitude: float = 101.6869


@app.post("/find-office")
async def find_office(request: FindOfficeRequest):
    """Find nearby government office - POST version for frontend"""
    if not GOOGLE_MAPS_API_KEY:
        raise HTTPException(status_code=500, detail="Google Maps API key not configured")
    
    service_info = GOVERNMENT_SERVICES.get(request.service.lower())
    if not service_info:
        raise HTTPException(status_code=404, detail=f"Unknown service: {request.service}")
    
    async with httpx.AsyncClient(timeout=15.0) as client:
        response = await client.get(
            "https://maps.googleapis.com/maps/api/place/nearbysearch/json",
            params={
                "location": f"{request.latitude},{request.longitude}",
                "radius": 10000,
                "keyword": service_info["search_term"],
                "key": GOOGLE_MAPS_API_KEY
            }
        )
        
        if response.status_code != 200:
            raise HTTPException(status_code=response.status_code, detail="Maps API error")
        
        data = response.json()
        results = []
        for place in data.get("results", [])[:5]:
            results.append({
                "name": place.get("name"),
                "address": place.get("vicinity"),
                "lat": place.get("geometry", {}).get("location", {}).get("lat"),
                "lng": place.get("geometry", {}).get("location", {}).get("lng"),
                "rating": place.get("rating"),
                "open_now": place.get("opening_hours", {}).get("open_now")
            })
        
        return {
            "service": service_info["name"],
            "results": results,
            "website": service_info["website"],
            "hotline": service_info["hotline"]
        }


# ============== TASK ENDPOINTS ==============

@app.post("/task/create")
def create_task(request: TaskCreateRequest):
    """Create a new task"""
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
    return {"message": f"Task created: {service['name']}", "task": task}


@app.post("/task/start-with-verification")
def start_task_with_verification(request: TaskCreateRequest):
    """Start task with auto-verification"""
    from routers.verification import run_auto_verification
    from routers.users import validate_user_for_service
    
    user_id = request.user_id or "default"
    
    verification = run_auto_verification(user_id, request.task_type)
    
    if not verification.get("eligible", False):
        return {
            "success": False,
            "message": "Eligibility check failed",
            "auto_verification": verification,
            "action_required": "Please update your profile to fix the failed checks"
        }
    
    validation = validate_user_for_service(user_id, request.task_type)
    
    if not validation["valid"]:
        return {
            "success": False,
            "message": "Profile validation failed",
            "auto_verification": verification,
            "validation": validation,
            "missing_info": {
                "fields": validation["missing_fields"],
                "documents": validation["missing_documents"]
            },
            "action_required": "Please complete your profile"
        }
    
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
        "current_step": 2,
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


@app.get("/task/{task_id}")
def get_task(task_id: str):
    """Get task details"""
    task = active_tasks.get(task_id)
    if not task:
        raise HTTPException(status_code=404, detail=f"Task not found: {task_id}")
    return task


@app.get("/tasks")
def get_tasks(user_id: str = "default"):
    """Get all tasks for user"""
    return {"tasks": [t for t in active_tasks.values() if t.get("user_id") == user_id]}


@app.post("/task/{task_id}/advance")
def advance_task(task_id: str):
    """Advance to next step"""
    task = active_tasks.get(task_id)
    if not task:
        raise HTTPException(status_code=404, detail=f"Task not found: {task_id}")
    
    if task["current_step"] >= task["total_steps"]:
        task["status"] = "completed"
        task["updated_at"] = datetime.now().isoformat()
        return {"completed": True, "message": f"🎉 Task completed!", "task": task}
    
    task["current_step"] += 1
    task["updated_at"] = datetime.now().isoformat()
    
    return {
        "completed": False,
        "message": f"Moved to step {task['current_step']}",
        "task": task,
        "next_step": task["steps"][task["current_step"] - 1] if task["current_step"] <= len(task["steps"]) else None
    }


@app.post("/task/{task_id}/cancel")
def cancel_task(task_id: str):
    """Cancel a task"""
    task = active_tasks.get(task_id)
    if not task:
        raise HTTPException(status_code=404, detail=f"Task not found: {task_id}")
    task["status"] = "cancelled"
    task["updated_at"] = datetime.now().isoformat()
    return {"message": f"Task cancelled", "task": task}


@app.delete("/task/{task_id}")
def delete_task(task_id: str):
    """Delete a task"""
    if task_id not in active_tasks:
        raise HTTPException(status_code=404, detail=f"Task not found: {task_id}")
    del active_tasks[task_id]
    return {"message": f"Task deleted: {task_id}"}


# ============== USER ID ENDPOINTS ==============

@app.get("/user/id")
def get_digital_id(user_id: str = "default"):
    """Get digital ID data for ID page"""
    User = Query()
    user = users_table.get(User.user_id == user_id)
    
    if user:
        return {
            "name": user.get("full_name", "Unknown"),
            "id_number": user.get("ic_number", "000000-00-0000"),
            "country": "Malaysia",
            "qr_data": f"did:my:{user.get('ic_number', '')}:verify",
            "valid_until": "2030-12-31"
        }
    
    # Return sample data if no user found
    return {
        "name": "Ahmad bin Abdullah",
        "id_number": "900115-14-5678",
        "country": "Malaysia",
        "qr_data": "did:my:900115145678:verify",
        "valid_until": "2030-12-31"
    }


# ============== USER PROFILE ENDPOINTS ==============

@app.get("/user/profile")
def get_user_profile(user_id: str = "default"):
    """Get user profile"""
    User = Query()
    user = users_table.get(User.user_id == user_id)
    
    if not user:
        return {"user_id": user_id, "profile": {}, "schema": USER_PROFILE_SCHEMA}
    
    completion = {}
    for category, fields in USER_PROFILE_SCHEMA.items():
        filled = sum(1 for f in fields if user.get(f))
        completion[category] = round(filled / max(1, len(fields)) * 100)
    
    return {"user_id": user_id, "profile": user, "schema": USER_PROFILE_SCHEMA, "completion": completion}


@app.post("/user/profile")
def update_user_profile(user_id: str = "default", updates: dict = {}):
    """Update user profile"""
    User = Query()
    existing = users_table.get(User.user_id == user_id)
    
    if existing:
        merged = {**existing, **updates, "updated_at": datetime.now().isoformat()}
        users_table.update(merged, User.user_id == user_id)
    else:
        updates["user_id"] = user_id
        updates["created_at"] = datetime.now().isoformat()
        users_table.insert(updates)
    
    return {"message": "Profile updated", "updated_fields": list(updates.keys())}


@app.get("/user/validate/{service_type}")
def validate_for_service(service_type: str, user_id: str = "default"):
    """Validate user for service"""
    from routers.users import validate_user_for_service
    return validate_user_for_service(user_id, service_type)


@app.get("/agent/verify/{service_type}")
def verify_eligibility(service_type: str, user_id: str = "default"):
    """Auto-verification agent"""
    from routers.verification import run_auto_verification
    return run_auto_verification(user_id, service_type)


# ============== CHAT HISTORY ENDPOINTS ==============

@app.post("/history/save")
def save_chat_history(request: ChatHistoryRequest):
    """Save chat history"""
    chat_history[request.session_id] = {
        "session_id": request.session_id,
        "user_id": request.user_id,
        "messages": request.messages,
        "title": request.title or f"Chat {datetime.now().strftime('%Y-%m-%d %H:%M')}",
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat()
    }
    return {"message": "History saved", "session_id": request.session_id}


@app.get("/history/{session_id}")
def get_chat_history(session_id: str):
    """Get chat history"""
    history = chat_history.get(session_id)
    if not history:
        raise HTTPException(status_code=404, detail="History not found")
    return history


@app.get("/history")
def list_chat_history(user_id: str = "default"):
    """List all chat histories"""
    return {"histories": [h for h in chat_history.values() if h.get("user_id") == user_id]}


@app.delete("/history/{session_id}")
def delete_chat_history(session_id: str):
    """Delete chat history"""
    if session_id in chat_history:
        del chat_history[session_id]
    return {"message": "History deleted"}


# ============== VALIDATION SCHEMA ==============

@app.get("/validation/schema")
def get_validation_schema():
    """Get user profile schema"""
    return {"schema": USER_PROFILE_SCHEMA, "service_requirements": SERVICE_VALIDATION_REQUIREMENTS}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
