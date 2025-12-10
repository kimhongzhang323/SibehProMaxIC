"""
Auto-verification agent for eligibility checks.
"""
from datetime import datetime
from typing import Dict, Any
from tinydb import Query

from database import users_table
from config import SECURITY_LEVELS, USER_PROFILE_SCHEMA
from knowledge_base import ELIGIBILITY_RULES


def get_field_label(field_name: str) -> str:
    """Get human-readable label for a field"""
    for category, fields in USER_PROFILE_SCHEMA.items():
        if field_name in fields:
            return fields[field_name]["label"]
    return field_name.replace("_", " ").title()


def run_auto_verification(user_id: str, service_type: str) -> Dict[str, Any]:
    """Auto-verification agent that checks all eligibility rules"""
    User = Query()
    user = users_table.get(User.user_id == user_id)
    
    if not user:
        user = {"user_id": user_id}
    
    rules = ELIGIBILITY_RULES.get(service_type, [])
    if not rules:
        return {"error": "No eligibility rules defined for this service"}
    
    verification_results = []
    passed_count = 0
    failed_count = 0
    warnings_count = 0
    
    for rule in rules:
        result = {
            "rule_id": rule["rule_id"],
            "name": rule["name"],
            "description": rule["description"],
            "severity": rule["severity"],
            "status": "pending",
            "message": "",
            "value_found": None
        }
        
        check_fields = rule["check_field"].split(",")
        
        if rule["rule_id"] == "passport_valid":
            passport_expiry = user.get("passport_expiry", "")
            if passport_expiry:
                try:
                    expiry_date = datetime.fromisoformat(passport_expiry)
                    months_remaining = (expiry_date - datetime.now()).days / 30
                    result["value_found"] = passport_expiry
                    if months_remaining >= 6:
                        result["status"] = "passed"
                        result["message"] = f"✅ Passport valid until {passport_expiry} ({int(months_remaining)} months remaining)"
                        passed_count += 1
                    else:
                        result["status"] = "failed"
                        result["message"] = f"❌ Passport expires too soon ({passport_expiry}). Need at least 6 months validity."
                        failed_count += 1
                except:
                    result["status"] = "failed"
                    result["message"] = "❌ Invalid passport expiry date format"
                    failed_count += 1
            else:
                result["status"] = "failed"
                result["message"] = "❌ No passport expiry date on record"
                failed_count += 1
        
        elif rule["rule_id"] == "passport_expiry_check":
            passport_expiry = user.get("passport_expiry", "")
            if passport_expiry:
                try:
                    expiry_date = datetime.fromisoformat(passport_expiry)
                    months_remaining = (expiry_date - datetime.now()).days / 30
                    result["value_found"] = passport_expiry
                    if months_remaining <= 0:
                        result["status"] = "passed"
                        result["message"] = f"✅ Passport expired on {passport_expiry} - renewal eligible"
                        passed_count += 1
                    elif months_remaining <= 6:
                        result["status"] = "passed"
                        result["message"] = f"✅ Passport expiring soon ({passport_expiry}) - renewal eligible"
                        passed_count += 1
                    else:
                        result["status"] = "warning"
                        result["message"] = f"⚠️ Passport still valid until {passport_expiry}. Early renewal available."
                        warnings_count += 1
                except:
                    result["status"] = "warning"
                    result["message"] = "⚠️ Could not parse passport expiry"
                    warnings_count += 1
            else:
                result["status"] = "passed"
                result["message"] = "✅ No existing passport - new application"
                passed_count += 1
        
        elif rule["rule_id"] == "age_check":
            dob = user.get("date_of_birth", "")
            if dob:
                try:
                    birth_date = datetime.fromisoformat(dob)
                    age = (datetime.now() - birth_date).days // 365
                    result["value_found"] = f"{age} years old"
                    if age >= 18:
                        result["status"] = "passed"
                        result["message"] = f"✅ Age verified: {age} years old"
                        passed_count += 1
                    else:
                        result["status"] = "failed"
                        result["message"] = f"❌ Must be 18+ years old. Current age: {age}"
                        failed_count += 1
                except:
                    result["status"] = "failed"
                    result["message"] = "❌ Invalid date of birth format"
                    failed_count += 1
            else:
                result["status"] = "failed"
                result["message"] = "❌ Date of birth not on record"
                failed_count += 1
        
        elif rule["rule_id"] == "nationality_check":
            nationality = user.get("nationality", "")
            result["value_found"] = nationality
            if nationality and nationality.lower() == "malaysian":
                result["status"] = "passed"
                result["message"] = f"✅ Nationality verified: {nationality}"
                passed_count += 1
            else:
                result["status"] = "failed"
                result["message"] = f"❌ Must be Malaysian citizen. Found: {nationality or 'Not specified'}"
                failed_count += 1
        
        elif rule["rule_id"] == "security_level":
            level = user.get("security_level", "basic")
            result["value_found"] = level
            if level in ["verified", "premium"]:
                result["status"] = "passed"
                result["message"] = f"✅ Security level: {level}"
                passed_count += 1
            else:
                result["status"] = "failed"
                result["message"] = f"❌ Need 'verified' or 'premium' level. Current: {level}"
                failed_count += 1
        
        elif rule["rule_id"] == "security_premium":
            level = user.get("security_level", "basic")
            result["value_found"] = level
            if level == "premium":
                result["status"] = "passed"
                result["message"] = "✅ Premium security level verified"
                passed_count += 1
            else:
                result["status"] = "failed"
                result["message"] = f"❌ Premium security required. Current: {level}"
                failed_count += 1
        
        elif rule["rule_id"] == "biometric_check":
            biometric = user.get("biometric_registered", False)
            result["value_found"] = str(biometric)
            if biometric:
                result["status"] = "passed"
                result["message"] = "✅ Biometric data on file"
                passed_count += 1
            else:
                result["status"] = "warning"
                result["message"] = "⚠️ Biometric not registered - will need to capture at office"
                warnings_count += 1
        
        else:
            # Generic field presence check
            all_found = True
            values = []
            for field in check_fields:
                value = user.get(field.strip())
                if value and (not isinstance(value, str) or value.strip()):
                    values.append(f"{field}: {value}")
                else:
                    all_found = False
            
            if all_found:
                result["status"] = "passed"
                result["value_found"] = ", ".join(values)
                result["message"] = f"✅ {rule['name']} verified"
                passed_count += 1
            elif rule["severity"] == "critical":
                result["status"] = "failed"
                result["message"] = f"❌ {rule['name']} - Required field(s) missing"
                failed_count += 1
            else:
                result["status"] = "warning"
                result["message"] = f"⚠️ {rule['name']} - Optional field(s) missing"
                warnings_count += 1
        
        verification_results.append(result)
    
    overall_eligible = failed_count == 0
    
    return {
        "eligible": overall_eligible,
        "service_type": service_type,
        "verification_timestamp": datetime.now().isoformat(),
        "summary": {
            "total_checks": len(rules),
            "passed": passed_count,
            "failed": failed_count,
            "warnings": warnings_count,
            "pass_rate": round(passed_count / max(1, len(rules)) * 100)
        },
        "results": verification_results,
        "recommendation": "Proceed with application" if overall_eligible else "Please fix the failed checks before proceeding"
    }
