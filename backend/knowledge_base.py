"""
Government services knowledge base and agentic service definitions.
"""

# Government Services Knowledge Base
GOVERNMENT_SERVICES = {
    "jpn": {
        "name": "Jabatan Pendaftaran Negara (JPN)",
        "name_en": "National Registration Department",
        "services": ["MyKad", "Birth Certificate", "Death Certificate", "Marriage Registration"],
        "website": "https://www.jpn.gov.my",
        "hotline": "03-8000 8000",
        "search_term": "Jabatan Pendaftaran Negara JPN"
    },
    "immigration": {
        "name": "Jabatan Imigresen Malaysia",
        "name_en": "Immigration Department of Malaysia",
        "services": ["Passport", "Visa", "Travel Document", "Entry Permit"],
        "website": "https://www.imi.gov.my",
        "hotline": "03-8000 8000",
        "search_term": "Jabatan Imigresen Malaysia Immigration"
    },
    "jpj": {
        "name": "Jabatan Pengangkutan Jalan (JPJ)",
        "name_en": "Road Transport Department",
        "services": ["Driver's License", "Vehicle Registration", "Road Tax"],
        "website": "https://www.jpj.gov.my",
        "hotline": "03-8000 8000",
        "search_term": "Jabatan Pengangkutan Jalan JPJ"
    },
    "lhdn": {
        "name": "Lembaga Hasil Dalam Negeri (LHDN)",
        "name_en": "Inland Revenue Board",
        "services": ["Income Tax", "Tax Filing", "Tax Refund"],
        "website": "https://www.hasil.gov.my",
        "hotline": "03-8911 1000",
        "search_term": "Lembaga Hasil Dalam Negeri LHDN"
    },
    "kwsp": {
        "name": "Kumpulan Wang Simpanan Pekerja (KWSP/EPF)",
        "name_en": "Employees Provident Fund",
        "services": ["EPF Withdrawal", "EPF Statement", "i-Saraan"],
        "website": "https://www.kwsp.gov.my",
        "hotline": "03-8922 6000",
        "search_term": "KWSP EPF Malaysia"
    },
    "perkeso": {
        "name": "Pertubuhan Keselamatan Sosial (PERKESO/SOCSO)",
        "name_en": "Social Security Organization",
        "services": ["SOCSO Claims", "Employment Injury", "Invalidity Pension"],
        "website": "https://www.perkeso.gov.my",
        "hotline": "1-300-22-8000",
        "search_term": "PERKESO SOCSO Malaysia"
    }
}

# Agentic Services - Step-by-step task workflows
AGENTIC_SERVICES = {
    "visa_application": {
        "name": "Visa Application",
        "icon": "✈️",
        "description": "Apply for entry visa to Malaysia",
        "steps": [
            {
                "id": 1, 
                "title": "Check Eligibility", 
                "description": "Verify your documents and visa requirements. We'll auto-check your passport validity.",
                "url": "https://www.imi.gov.my/index.php/en/visa/visa-requirement/",
                "action": "open_link",
                "action_label": "Check Requirements",
                "autofill_fields": ["passport_number", "nationality", "date_of_birth"]
            },
            {
                "id": 2, 
                "title": "Book Appointment", 
                "description": "Book appointment at STO JPN for biometric and document submission. Your details will be pre-filled.",
                "url": "https://sto.imi.gov.my/",
                "action": "open_link",
                "action_label": "Book at STO",
                "autofill_fields": ["full_name", "ic_number", "phone", "email"]
            },
            {
                "id": 3, 
                "title": "Prepare Documents", 
                "description": "Gather: Passport (6mo validity), photos, travel itinerary, hotel booking",
                "checklist": ["Passport with 6+ months validity", "2 passport photos (35x50mm)", "Flight itinerary", "Hotel booking confirmation", "Proof of funds"],
                "action": "show_passport",
                "action_label": "View My Passport"
            },
            {
                "id": 4, 
                "title": "Submit Application", 
                "description": "Submit documents at your appointment with auto-filled application form",
                "url": "https://malaysiavisa.imi.gov.my/evisa/evisa.jsp",
                "action": "open_link",
                "action_label": "Apply Online",
                "autofill_fields": ["full_name", "passport_number", "date_of_birth", "nationality", "address", "phone", "email"]
            },
            {
                "id": 5, 
                "title": "Pay Fees", 
                "description": "Processing fee varies by visa type and nationality",
                "url": "https://malaysiavisa.imi.gov.my/evisa/payment.jsp",
                "action": "open_link",
                "action_label": "Make Payment"
            },
            {
                "id": 6, 
                "title": "Collect Visa", 
                "description": "Collect visa or check email for e-Visa",
                "action": "complete",
                "action_label": "Mark Complete"
            }
        ],
        "service": "immigration",
        "website": "https://www.imi.gov.my"
    },
    "passport_renewal": {
        "name": "Passport Renewal",
        "icon": "📘",
        "description": "Renew Malaysian passport",
        "steps": [
            {"id": 1, "title": "Book Online Appointment", "description": "Book slot at UTC/JPN via STO portal", "url": "https://sto.imi.gov.my/", "action": "open_link", "action_label": "Book Appointment"},
            {"id": 2, "title": "Prepare Documents", "description": "Gather: Old passport, MyKad, recent photos", "checklist": ["Old passport", "MyKad (original)", "1 passport photo"]},
            {"id": 3, "title": "Visit Counter", "description": "Attend appointment with documents"},
            {"id": 4, "title": "Pay Fee", "description": "RM200 (5 years) or RM100 (2 years)", "url": "https://www.imi.gov.my", "action": "open_link", "action_label": "Fee Details"},
            {"id": 5, "title": "Collect Passport", "description": "Usually ready in 1-2 working days"}
        ],
        "service": "immigration",
        "website": "https://www.imi.gov.my"
    },
    "ic_replacement": {
        "name": "MyKad (IC) Replacement",
        "icon": "🪪",
        "description": "Replace lost or damaged MyKad",
        "steps": [
            {"id": 1, "title": "Make Police Report", "description": "For lost IC, make report at police station or online", "url": "https://ereporting.rmp.gov.my/", "action": "open_link", "action_label": "Make Report Online"},
            {"id": 2, "title": "Book JPN Appointment", "description": "Book slot at nearest JPN branch", "url": "https://www.jpn.gov.my/en/appointment/", "action": "open_link", "action_label": "Book at JPN"},
            {"id": 3, "title": "Prepare Documents", "description": "Police report, birth cert, old IC photo (if available)", "checklist": ["Police report", "Birth certificate", "2 passport photos"]},
            {"id": 4, "title": "Visit JPN", "description": "Submit documents and take photo/fingerprint"},
            {"id": 5, "title": "Pay Fee", "description": "RM10 (first replacement), RM100+ (subsequent)", "url": "https://www.jpn.gov.my", "action": "open_link", "action_label": "Fee Details"},
            {"id": 6, "title": "Collect IC", "description": "Same day or next day collection"}
        ],
        "service": "jpn",
        "website": "https://www.jpn.gov.my"
    },
    "foreign_worker_permit": {
        "name": "Foreign Worker Permit",
        "icon": "👷",
        "description": "Apply for foreign worker employment permit",
        "steps": [
            {
                "id": 1, 
                "title": "Register MyIMMS Account", 
                "description": "Create employer account on MyIMMS portal. Your company info will be auto-filled.",
                "url": "https://myimms.imi.gov.my/myimms/register",
                "action": "open_link",
                "action_label": "Register at MyIMMS",
                "autofill_fields": ["company_name", "ssm_number", "employer_name", "employer_ic", "phone", "email"]
            },
            {
                "id": 2, 
                "title": "Verify Company with SSM", 
                "description": "Check your company registration status on SSM portal",
                "url": "https://www.ssm.com.my/Pages/e-Search.aspx",
                "action": "open_link",
                "action_label": "Verify SSM Registration",
                "autofill_fields": ["ssm_number"]
            },
            {
                "id": 3, 
                "title": "Submit Permit Application", 
                "description": "Fill out the work permit application form with worker details",
                "url": "https://myimms.imi.gov.my/myimms/newApplication",
                "action": "open_link",
                "action_label": "Start Application",
                "autofill_fields": ["employer_name", "company_name", "worker_name", "worker_passport", "worker_nationality"],
                "form_fields": [
                    {"name": "worker_name", "label": "Worker Full Name", "type": "text"},
                    {"name": "worker_passport", "label": "Passport Number", "type": "text"},
                    {"name": "worker_nationality", "label": "Nationality", "type": "select"},
                    {"name": "job_position", "label": "Job Position", "type": "text"},
                    {"name": "salary", "label": "Monthly Salary (RM)", "type": "number"}
                ]
            },
            {
                "id": 4, 
                "title": "Upload Worker Documents", 
                "description": "Upload all required worker and employer documents",
                "requires_upload": True,
                "action": "upload",
                "action_label": "Upload Documents",
                "required_docs": ["Worker passport (all pages)", "Offer letter", "Employment contract", "FOMEMA medical report", "Employer SSM certificate"]
            },
            {
                "id": 5, 
                "title": "Pay Levy & Fees", 
                "description": "Pay processing fee and annual levy",
                "url": "https://myimms.imi.gov.my/myimms/payment",
                "action": "open_link",
                "action_label": "Make Payment",
                "fee_breakdown": [
                    {"item": "Annual Levy (Manufacturing)", "amount": "RM1,850"},
                    {"item": "Annual Levy (Service)", "amount": "RM1,490"},
                    {"item": "Annual Levy (Agriculture)", "amount": "RM640"},
                    {"item": "Processing Fee", "amount": "RM125"},
                    {"item": "Visa Fee", "amount": "RM30"}
                ]
            },
            {
                "id": 6, 
                "title": "Biometric Enrollment", 
                "description": "Worker must complete biometric at Immigration",
                "url": "https://myimms.imi.gov.my/myimms/appointment",
                "action": "open_link",
                "action_label": "Book Biometric Slot"
            },
            {
                "id": 7, 
                "title": "Collect Work Permit", 
                "description": "Permit issued, track status online",
                "url": "https://myimms.imi.gov.my/myimms/status",
                "action": "open_link",
                "action_label": "Check Status"
            }
        ],
        "service": "immigration",
        "website": "https://myimms.imi.gov.my"
    },
    "tax_filing": {
        "name": "Tax Filing (e-Filing)",
        "icon": "📊",
        "description": "File annual income tax return online",
        "steps": [
            {
                "id": 1, 
                "title": "Register/Login MyTax", 
                "description": "Access LHDN MyTax portal with your ID",
                "url": "https://mytax.hasil.gov.my/",
                "action": "open_link",
                "action_label": "Open MyTax",
                "autofill_fields": ["ic_number", "full_name"]
            },
            {
                "id": 2, 
                "title": "Gather Documents", 
                "description": "Collect all required tax documents",
                "checklist": ["EA Form from employer", "Interest statements", "Insurance receipts", "Medical receipts", "Education receipts", "Donation receipts"]
            },
            {
                "id": 3, 
                "title": "Calculate Income", 
                "description": "Use LHDN calculator to estimate your tax",
                "url": "https://www.hasil.gov.my/bt_go498xMTUzOXMx49.php",
                "action": "open_link",
                "action_label": "Open Tax Calculator"
            },
            {
                "id": 4, 
                "title": "Upload Documents", 
                "description": "Upload receipts and supporting documents",
                "requires_upload": True,
                "action": "upload",
                "action_label": "Upload Documents"
            },
            {
                "id": 5, 
                "title": "Submit Return", 
                "description": "Complete and submit your ITRF (Form BE/B/M)",
                "url": "https://mytax.hasil.gov.my/",
                "action": "open_link",
                "action_label": "Submit Tax Return",
                "deadline": "April 30 (employed) / June 30 (business)"
            },
            {
                "id": 6, 
                "title": "Pay Tax", 
                "description": "Pay any outstanding tax via FPX or credit card",
                "url": "https://byrhasil.hasil.gov.my/",
                "action": "open_link",
                "action_label": "Pay Tax Online"
            }
        ],
        "service": "lhdn",
        "website": "https://mytax.hasil.gov.my"
    }
}

# Eligibility rules for auto-verification agent
ELIGIBILITY_RULES = {
    "visa_application": [
        {"rule_id": "passport_valid", "name": "Passport Validity", "description": "Passport must be valid for at least 6 months", "check_field": "passport_expiry", "severity": "critical"},
        {"rule_id": "passport_exists", "name": "Passport Registered", "description": "Must have a valid passport number", "check_field": "passport_number", "severity": "critical"},
        {"rule_id": "age_check", "name": "Age Verification", "description": "Must be at least 18 years old", "check_field": "date_of_birth", "severity": "critical"},
        {"rule_id": "security_level", "name": "Security Verification", "description": "Account must be verified level or higher", "check_field": "security_level", "severity": "high"},
        {"rule_id": "contact_info", "name": "Contact Information", "description": "Valid phone and email required", "check_field": "phone,email", "severity": "medium"},
    ],
    "passport_renewal": [
        {"rule_id": "nationality_check", "name": "Nationality", "description": "Must be Malaysian citizen", "check_field": "nationality", "severity": "critical"},
        {"rule_id": "ic_exists", "name": "IC Registered", "description": "Must have MyKad number", "check_field": "ic_number", "severity": "critical"},
        {"rule_id": "old_passport_check", "name": "Old Passport", "description": "Old passport number for reference", "check_field": "passport_number", "severity": "high"},
        {"rule_id": "passport_expiry_check", "name": "Expiry Check", "description": "Check if passport needs renewal", "check_field": "passport_expiry", "severity": "medium"},
    ],
    "ic_replacement": [
        {"rule_id": "nationality_check", "name": "Nationality", "description": "Must be Malaysian citizen", "check_field": "nationality", "severity": "critical"},
        {"rule_id": "ic_exists", "name": "IC Number Known", "description": "Previous IC number required", "check_field": "ic_number", "severity": "critical"},
        {"rule_id": "address_check", "name": "Address Verification", "description": "Current address required", "check_field": "address", "severity": "high"},
        {"rule_id": "biometric_check", "name": "Biometric Registered", "description": "Must have biometric on file", "check_field": "biometric_registered", "severity": "medium"},
    ],
    "foreign_worker_permit": [
        {"rule_id": "employer_registered", "name": "Employer Verification", "description": "Employer must be registered", "check_field": "employer_name", "severity": "critical"},
        {"rule_id": "ssm_check", "name": "SSM Registration", "description": "Valid SSM number required", "check_field": "ssm_number", "severity": "critical"},
        {"rule_id": "business_type", "name": "Business Type", "description": "Business entity type must be specified", "check_field": "business_type", "severity": "high"},
        {"rule_id": "security_premium", "name": "Premium Security", "description": "Premium security level required for FW permit", "check_field": "security_level", "severity": "critical"},
    ],
    "tax_filing": [
        {"rule_id": "ic_check", "name": "IC Verification", "description": "Valid IC number for tax reference", "check_field": "ic_number", "severity": "critical"},
        {"rule_id": "income_declared", "name": "Income Information", "description": "Income sources must be declared", "check_field": "monthly_income", "severity": "high"},
        {"rule_id": "tax_number", "name": "Tax Number", "description": "LHDN tax number check", "check_field": "tax_number", "severity": "medium"},
    ]
}
