from fastapi import APIRouter, HTTPException
from tinydb import Query, TinyDB
from datetime import datetime
from database import users_table
from services.blockchain import blockchain
from services.ai_engine import ai_engine

router = APIRouter(prefix="/security", tags=["security"])

@router.post("/revoke")
def revoke_id(user_id: str = "default"):
    """Revoke a user's digital ID remotely"""
    # 1. AI Safety Check
    is_anomaly, risk, reason = ai_engine.check_behavior(user_id, "revoke")
    if is_anomaly:
        # Block revocation if suspicious? Or just flag?
        # For revocation, we probably want to allow it but log heavily.
        blockchain.add_transaction({"event": "ANOMALY_DETECTED", "user": user_id, "reason": reason})
        
    User = Query()
    # Upsert user if not exists, though usually should exist
    if not users_table.search(User.user_id == user_id):
        users_table.insert({"user_id": user_id, "revoked": True, "created_at": datetime.now().isoformat()})
    else:
        users_table.update({"revoked": True, "revoked_at": datetime.now().isoformat()}, User.user_id == user_id)
    
    # 2. Blockchain Log
    blockchain.add_transaction({
        "event": "ID_REVOCATION",
        "user_id": user_id,
        "timestamp": datetime.now().isoformat(),
        "risk_score": risk
    })
    
    return {"status": "revoked", "message": "ID has been revoked remotely.", "user_id": user_id}

@router.get("/status")
def check_status(user_id: str = "default"):
    """Check if ID is valid or revoked"""
    User = Query()
    user = users_table.get(User.user_id == user_id)
    
    if user and user.get("revoked", False):
        return {
            "status": "revoked", 
            "revoked_at": user.get("revoked_at"),
            "message": "This ID has been permanently revoked."
        }
    
    return {"status": "active", "message": "ID is active."}

@router.post("/restore")
def restore_id(user_id: str = "default"):
    """Restore a revoked ID (for testing purposes)"""
    User = Query()
    users_table.update({"revoked": False, "restored_at": datetime.now().isoformat()}, User.user_id == user_id)
    return {"status": "active", "message": "ID restored."}

@router.post("/generate_proof")
def generate_proof(request: dict):
    """Generate a Zero-Knowledge Proof (Simulated) for selective disclosure"""
    user_id = request.get("user_id", "default")
    attribute = request.get("attribute") # e.g., "age_over_18", "citizenship"
    
    User = Query()
    user = users_table.get(User.user_id == user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    proof_data = {
        "timestamp": datetime.now().isoformat(),
        "issuer": "DigitalID_Government_CA",
        "attribute": attribute,
        "result": False,
        "proof_signature": "mock_zkp_signature_cxv987234"
    }
    
    if attribute == "age_over_18":
        dob = user.get("date_of_birth") or user.get("dob") # Handle format
        # Simplification: Assume user is > 18 for demo or parse date
        # If user data missing, use default logic
        if not dob: 
             proof_data["result"] = True # Default for demo
        else:
             try:
                 # Parse ISO date 
                 dt = datetime.fromisoformat(dob)
                 age = (datetime.now() - dt).days // 365
                 proof_data["result"] = age >= 18
             except:
                 proof_data["result"] = True
                 
    elif attribute == "citizenship":
        proof_data["result"] = True # Is Malaysian
    
    # Log to Blockchain
    blockchain.add_transaction({
        "event": "ZKP_GENERATED",
        "user_id": user_id,
        "attribute": attribute,
        "result": proof_data["result"]
    })
        
    return proof_data
