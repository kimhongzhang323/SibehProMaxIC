"""
Configuration settings and schema definitions for the Digital ID API.
"""
import os
from dotenv import load_dotenv

load_dotenv()

# API Keys
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
ELEVENLABS_API_KEY = os.getenv("ELEVENLABS_API_KEY")
GOOGLE_MAPS_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY")

# Voice IDs for TTS
VOICE_IDS = {
    "malay": "lvNyQwaZPcGFiNUWWiVa",
    "chinese": "9lHjugDhwqoxA5MhX0az",
    "tamil": "Z0ocGS7BSRxFSMhV00nB",
    "english": "21m00Tcm4TlvDq8ikWAM",
}

# User profile schema - fields required for various services
USER_PROFILE_SCHEMA = {
    "personal": {
        "full_name": {"label": "Full Name", "required": True},
        "ic_number": {"label": "IC Number (MyKad)", "required": True},
        "date_of_birth": {"label": "Date of Birth", "required": True},
        "gender": {"label": "Gender", "required": True},
        "nationality": {"label": "Nationality", "required": True},
        "phone": {"label": "Phone Number", "required": True},
        "email": {"label": "Email Address", "required": True},
        "address": {"label": "Home Address", "required": False},
    },
    "passport": {
        "passport_number": {"label": "Passport Number", "required": False},
        "passport_expiry": {"label": "Passport Expiry Date", "required": False},
        "passport_issue_date": {"label": "Passport Issue Date", "required": False},
    },
    "employment": {
        "employer_name": {"label": "Employer Name", "required": False},
        "company_name": {"label": "Company Name", "required": False},
        "ssm_number": {"label": "SSM Registration Number", "required": False},
        "job_title": {"label": "Job Title", "required": False},
        "monthly_income": {"label": "Monthly Income", "required": False},
    },
    "business": {
        "business_type": {"label": "Business Type", "required": False},
        "business_sector": {"label": "Business Sector", "required": False},
        "business_registration_date": {"label": "Business Registration Date", "required": False},
        "authorized_capital": {"label": "Authorized Capital (RM)", "required": False},
        "paid_up_capital": {"label": "Paid-Up Capital (RM)", "required": False},
        "num_employees": {"label": "Number of Employees", "required": False},
        "contractor_license": {"label": "Contractor License (CIDB)", "required": False},
        "contractor_grade": {"label": "Contractor Grade", "required": False},
    },
    "security": {
        "security_level": {"label": "Security Verification Level", "required": False},
        "biometric_registered": {"label": "Biometric Registered", "required": False},
        "two_factor_enabled": {"label": "Two-Factor Authentication", "required": False},
        "account_status": {"label": "Account Status", "required": False},
        "last_login": {"label": "Last Login", "required": False},
    },
    "documents": {
        "birth_cert_uploaded": {"label": "Birth Certificate", "required": False},
        "ic_uploaded": {"label": "IC Copy", "required": False},
        "passport_uploaded": {"label": "Passport Copy", "required": False},
        "photo_uploaded": {"label": "Passport Photo", "required": False},
        "ssm_cert_uploaded": {"label": "SSM Certificate", "required": False},
        "business_license_uploaded": {"label": "Business License", "required": False},
    }
}

# Security level requirements
SECURITY_LEVELS = {
    "basic": {
        "description": "Basic account - email verified only",
        "allowed_services": ["tax_filing"],
        "transaction_limit": 1000,
        "requirements": ["email"]
    },
    "verified": {
        "description": "Verified account - IC and biometric verified",
        "allowed_services": ["tax_filing", "passport_renewal", "ic_replacement", "visa_application"],
        "transaction_limit": 50000,
        "requirements": ["email", "ic_number", "biometric_registered"]
    },
    "premium": {
        "description": "Premium account - Full verification with 2FA",
        "allowed_services": ["tax_filing", "passport_renewal", "ic_replacement", "visa_application", "foreign_worker_permit"],
        "transaction_limit": 500000,
        "requirements": ["email", "ic_number", "biometric_registered", "two_factor_enabled"]
    }
}

# Validation requirements for each service type
SERVICE_VALIDATION_REQUIREMENTS = {
    "visa_application": {
        "required_fields": ["full_name", "ic_number", "nationality", "passport_number", "passport_expiry", "phone", "email"],
        "required_documents": ["passport_uploaded", "photo_uploaded"],
        "required_security_level": "verified",
        "description": "Visa Application"
    },
    "passport_renewal": {
        "required_fields": ["full_name", "ic_number", "date_of_birth", "phone", "email", "passport_number"],
        "required_documents": ["ic_uploaded", "photo_uploaded"],
        "required_security_level": "verified",
        "description": "Passport Renewal"
    },
    "ic_replacement": {
        "required_fields": ["full_name", "ic_number", "date_of_birth", "phone", "email", "address"],
        "required_documents": ["birth_cert_uploaded", "photo_uploaded"],
        "required_security_level": "verified",
        "description": "IC Replacement"
    },
    "foreign_worker_permit": {
        "required_fields": ["full_name", "ic_number", "phone", "email", "employer_name", "company_name", "ssm_number"],
        "required_documents": ["ic_uploaded", "ssm_cert_uploaded"],
        "required_security_level": "premium",
        "required_business_fields": ["business_type", "business_registration_date"],
        "description": "Foreign Worker Permit"
    },
    "tax_filing": {
        "required_fields": ["full_name", "ic_number", "phone", "email", "monthly_income"],
        "required_documents": [],
        "required_security_level": "basic",
        "description": "Tax Filing"
    }
}
