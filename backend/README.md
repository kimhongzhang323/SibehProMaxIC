<div align="center">

# ⚙️ Journey Backend

### FastAPI-Powered API Server

[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org/)
[![Gemini](https://img.shields.io/badge/Gemini_Pro-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://deepmind.google/technologies/gemini/)

</div>

---

## 📖 Overview

The backend powers Journey's core functionality, providing RESTful APIs for user management, AI-powered chat, document verification, and security features.

---

## 🏗️ Architecture

```
backend/
├── main.py              # FastAPI application entry point
├── config.py            # Configuration settings
├── database.py          # Database operations
├── models.py            # Pydantic data models
├── prompts.py           # AI prompt templates
├── knowledge_base.py    # AI knowledge management
│
├── routers/             # API endpoint modules
│   ├── chat.py          # AI chatbot endpoints
│   ├── security.py      # Security & encryption
│   ├── tasks.py         # Task management
│   ├── users.py         # User operations
│   └── verification.py  # Document verification
│
├── services/            # Business logic
│   ├── ai_engine.py     # Gemini Pro integration
│   └── blockchain.py    # Blockchain-style logging
│
└── data/                # Mock database files
    ├── database.json    # User data
    ├── permissions.json # Access control
    └── scan_logs.json   # Audit logs
```

---

## 🚀 Quick Start

### Prerequisites

- Python 3.10 or higher
- pip (Python package manager)

### Installation

```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows
venv\Scripts\activate
# macOS/Linux
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Running the Server

```bash
# Development mode with auto-reload
uvicorn main:app --reload

# Production mode
uvicorn main:app --host 0.0.0.0 --port 8000
```

✅ Server running at `http://127.0.0.1:8000`

---

## 📡 API Endpoints

### Interactive Documentation

Once the server is running, access:

| Documentation | URL |
|---------------|-----|
| **Swagger UI** | [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs) |
| **ReDoc** | [http://127.0.0.1:8000/redoc](http://127.0.0.1:8000/redoc) |

### Key Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/chat` | AI chatbot interaction |
| `GET` | `/users/{id}` | Get user information |
| `POST` | `/verify` | Document verification |
| `POST` | `/security/encrypt` | Data encryption |
| `GET` | `/tasks` | List user tasks |

---

## 🔧 Configuration

Create a `.env` file in the backend directory:

```env
# AI Configuration
GEMINI_API_KEY=your_api_key_here

# Server Settings
DEBUG=true
HOST=127.0.0.1
PORT=8000
```

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `fastapi` | Web framework |
| `uvicorn` | ASGI server |
| `pydantic` | Data validation |
| `httpx` | HTTP client |
| `python-dotenv` | Environment variables |
| `tinydb` | JSON database |

---

## 🧪 Testing

```bash
# Run tests (if available)
pytest

# Run with coverage
pytest --cov=.
```

---

<div align="center">

**[← Back to Main README](../README.md)**

</div>
