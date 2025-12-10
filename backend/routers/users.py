"""
User profile and validation API endpoints.
"""
from fastapi import APIRouter, HTTPException
from typing import Dict, Any
from datetime import datetime
from tinydb import Query

from database import users_table
from config import USER_PROFILE_SCHEMA, SECURITY_LEVELS, SERVICE_VALIDATION_REQUIREMENTS
from models import UserProfileUpdate

router = APIRouter(prefix="/user", tags=["Users"])


def get_field_label(field_name: str) -> str:
    """Get human-readable label for a field"""
    for category, fields in USER_PROFILE_SCHEMA.items():
        if field_name in fields:
            return fields[field_name]["label"]
    return field_name.replace("_", " ").title()


def validate_user_for_service(user_id: str, service_type: str) -> Dict[str, Any]:
    """Validate if user has all required data for a service"""
    User = Query()
    user = users_table.get(User.user_id == user_id)
    
    if not user:
        user = {"user_id": user_id}
    
    if service_type not in SERVICE_VALIDATION_REQUIREMENTS:
        return {"error": f"Unknown service type: {service_type}"}
    
    requirements = SERVICE_VALIDATION_REQUIREMENTS[service_type]
    missing_fields = []
    missing_documents = []
    present_fields = []
    
    # Check required fields
    for field in requirements["required_fields"]:
        value = user.get(field)
        if not value or (isinstance(value, str) and value.strip() == ""):
            missing_fields.append({
                "field": field,
                "label": get_field_label(field)
            })
        else:
            present_fields.append({
                "field": field,
                "label": get_field_label(field),
                "value": value
            })
    
    # Check required business fields if any
    required_business = requirements.get("required_business_fields", [])
    for field in required_business:
        value = user.get(field)
        if not value or (isinstance(value, str) and value.strip() == ""):
            missing_fields.append({
                "field": field,
                "label": get_field_label(field),
                "category": "business"
            })
    
    # Check required documents
    for doc in requirements["required_documents"]:
        if not user.get(doc):
            missing_documents.append({
                "field": doc,
                "label": get_field_label(doc)
            })
    
    # Check security level
    security_issues = []
    required_security = requirements.get("required_security_level", "basic")
    user_security = user.get("security_level", "basic")
    
    security_hierarchy = {"basic": 1, "verified": 2, "premium": 3}
    user_level_num = security_hierarchy.get(user_security, 0)
    required_level_num = security_hierarchy.get(required_security, 1)
    
    if user_level_num < required_level_num:
        security_issues.append({
            "issue": "insufficient_security_level",
            "current_level": user_security,
            "required_level": required_security,
            "message": f"This service requires '{required_security}' security level."
        })
        
        level_requirements = SECURITY_LEVELS.get(required_security, {}).get("requirements", [])
        for req in level_requirements:
            if not user.get(req):
                security_issues.append({
                    "issue": "missing_security_requirement",
                    "requirement": req,
                    "label": get_field_label(req)
                })
    
    is_valid = (len(missing_fields) == 0 and 
                len(missing_documents) == 0 and 
                len(security_issues) == 0)
    
    return {
        "valid": is_valid,
        "service_type": service_type,
        "service_description": requirements["description"],
        "missing_fields": missing_fields,
        "missing_documents": missing_documents,
        "security_issues": security_issues,
        "present_fields": present_fields,
        "user_security_level": user_security,
        "required_security_level": required_security,
        "total_required": len(requirements["required_fields"]) + len(requirements["required_documents"]),
        "total_present": len(present_fields) + (len(requirements["required_documents"]) - len(missing_documents)),
        "completion_percentage": round(
            (len(present_fields) + len(requirements["required_documents"]) - len(missing_documents)) /
            max(1, len(requirements["required_fields"]) + len(requirements["required_documents"])) * 100
        )
    }


@router.get("/profile")
def get_user_profile(user_id: str = "default"):
    """Get user profile data"""
    User = Query()
    user = users_table.get(User.user_id == user_id)
    
    if not user:
        return {
            "user_id": user_id,
            "profile": {},
            "schema": USER_PROFILE_SCHEMA,
            "completion": {
                "personal": 0,
                "passport": 0,
                "employment": 0,
                "documents": 0,
                "overall": 0
            }
        }
    
    # Calculate completion percentages
    completion = {}
    total_fields = 0
    filled_fields = 0
    
    for category, fields in USER_PROFILE_SCHEMA.items():
        category_total = len(fields)
        category_filled = sum(1 for f in fields if user.get(f))
        completion[category] = round(category_filled / max(1, category_total) * 100)
        total_fields += category_total
        filled_fields += category_filled
    
    completion["overall"] = round(filled_fields / max(1, total_fields) * 100)
    
    return {
        "user_id": user_id,
        "profile": user,
        "schema": USER_PROFILE_SCHEMA,
        "completion": completion
    }


@router.post("/profile")
def update_user_profile(user_id: str = "default", updates: dict = {}):
    """Update user profile data"""
    User = Query()
    existing = users_table.get(User.user_id == user_id)
    
    if existing:
        merged = {**existing, **updates}
        merged["updated_at"] = datetime.now().isoformat()
        users_table.update(merged, User.user_id == user_id)
    else:
        updates["user_id"] = user_id
        updates["created_at"] = datetime.now().isoformat()
        updates["updated_at"] = datetime.now().isoformat()
        users_table.insert(updates)
    
    return {"message": "Profile updated", "updated_fields": list(updates.keys())}


@router.get("/validate/{service_type}")
def validate_for_service(service_type: str, user_id: str = "default"):
    """Validate user data for a specific service"""
    return validate_user_for_service(user_id, service_type)


@router.get("/requirements/{service_type}")
def get_service_requirements(service_type: str):
    """Get requirements for a service"""
    if service_type not in SERVICE_VALIDATION_REQUIREMENTS:
        raise HTTPException(status_code=404, detail=f"Unknown service: {service_type}")
    
    requirements = SERVICE_VALIDATION_REQUIREMENTS[service_type]
    
    return {
        "service_type": service_type,
        "description": requirements["description"],
        "required_fields": [
            {"field": f, "label": get_field_label(f)} 
            for f in requirements["required_fields"]
        ],
        "required_documents": [
            {"field": d, "label": get_field_label(d)} 
            for d in requirements["required_documents"]
        ],
        "required_security_level": requirements.get("required_security_level", "basic")
    }


@router.post("/document/{document_type}")
def mark_document_uploaded(document_type: str, user_id: str = "default"):
    """Mark a document as uploaded"""
    User = Query()
    existing = users_table.get(User.user_id == user_id)
    
    if existing:
        existing[document_type] = True
        existing["updated_at"] = datetime.now().isoformat()
        users_table.update(existing, User.user_id == user_id)
    else:
        users_table.insert({
            "user_id": user_id,
            document_type: True,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        })
    
    return {"message": f"Document marked as uploaded: {document_type}"}
