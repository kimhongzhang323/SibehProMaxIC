<div align="center">

# 🚀 Journey

### Malaysia's Next-Generation Digital Identity Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.6-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Gemini](https://img.shields.io/badge/Gemini_Pro-AI_Powered-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://deepmind.google/technologies/gemini/)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)

**Unify. Simplify. Secure.**

[Features](#-features) • [Tech Stack](#-tech-stack) • [Quick Start](#-quick-start) • [Demo](#-demo) • [Contributing](#-contributing)

---

</div>

## 🌟 Overview

**Journey** is an advanced, AI-powered digital identity application that revolutionizes how Malaysians interact with government services. By consolidating agencies like **JPN**, **JPJ**, **Immigration**, **LHDN**, **KWSP**, **PERKESO**, and **MOH** into a single unified platform, Journey eliminates the hassle of managing multiple documents and portals.

<div align="center">

| 🎯 **Unified Access** | 🤖 **AI-Powered** | 🔐 **Bank-Grade Security** | 📱 **Cross-Platform** |
|:---:|:---:|:---:|:---:|
| All government IDs in one app | Context-aware Gemini Pro assistant | AES-256 encryption & Kill Switch | Mobile app + Web portal sync |

</div>

---

## ✨ Features

### 🆔 Digital Identity Management
- **Digital MyKad** — Access your IC anytime, anywhere
- **Driving License** — JPJ-linked digital license
- **Passport Info** — Immigration status at your fingertips
- **Touch 'n Go Integration** — Check NFC balances seamlessly

### 🤖 Smart AI Assistant
- **Context-Aware Help** — Understands your current screen and needs
- **Deep-Linking** — Navigate directly to relevant services
- **Natural Conversations** — Powered by **Gemini Pro**
- **Document Guidance** — Step-by-step process assistance

### 🔒 Enterprise Security
- **AES-256 Encryption** — Military-grade data protection
- **Kill Switch** — Remote device revocation
- **Blockchain Logging** — Tamper-proof audit trails
- **Biometric Auth** — Fingerprint & Face ID support
- **Secure Storage** — Encrypted local data storage

### 🔄 Seamless Integration
- **Scan-to-Fill** — QR-based auto-complete for web forms
- **Cross-Platform Sync** — Mobile ↔ Web data transfer
- **Print Services** — Generate PDF documents on-demand

---

## 🛠 Tech Stack

<div align="center">

### Frontend
| Technology | Purpose |
|------------|---------|
| ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white) | Cross-platform UI framework |
| ![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white) | Programming language |
| ![Material 3](https://img.shields.io/badge/Material_3-757575?style=flat-square&logo=material-design&logoColor=white) | Design system |
| ![Provider](https://img.shields.io/badge/Provider-State_Mgmt-blue?style=flat-square) | State management |

### Backend
| Technology | Purpose |
|------------|---------|
| ![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=flat-square&logo=fastapi&logoColor=white) | High-performance API |
| ![Python](https://img.shields.io/badge/Python_3.10+-3776AB?style=flat-square&logo=python&logoColor=white) | Backend language |
| ![Gemini](https://img.shields.io/badge/Gemini_Pro-4285F4?style=flat-square&logo=google&logoColor=white) | AI/ML engine |

</div>

---

## 🚀 Quick Start

### Prerequisites

| Requirement | Version | Installation |
|-------------|---------|--------------|
| Flutter SDK | 3.6+ | [Install Guide](https://docs.flutter.dev/get-started/install) |
| Python | 3.10+ | [Download](https://www.python.org/downloads/) |
| Git | Latest | [Download](https://git-scm.com/) |

### ⚡ One-Click Setup

```bash
# Clone the repository
git clone https://github.com/kimhongzhang323/SibehProMaxIC.git
cd SibehProMaxIC
```

<details>
<summary><b>🔧 Backend Setup</b></summary>

```bash
# Navigate to backend
cd backend

# Create virtual environment
python -m venv venv

# Activate (Windows)
venv\Scripts\activate

# Activate (macOS/Linux)
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Start the server
uvicorn main:app --reload
```

✅ Backend running at `http://127.0.0.1:8000`

</details>

<details>
<summary><b>📱 Frontend Setup</b></summary>

```bash
# Navigate to frontend
cd frontend

# Get dependencies
flutter pub get

# Run the app
flutter run
```

✅ Choose your target device when prompted

</details>

---

## 🎮 Demo

### Scan-to-Fill Feature

Experience the magic of seamless data transfer:

1. Open `mock_website/index.html` in your browser
2. Click **"Fill with Journey"**
3. Select **"Simulate Mobile Scan"**
4. Watch forms auto-populate instantly! ✨

---

## 📁 Project Structure

```
Journey/
├── 📱 frontend/          # Flutter mobile application
│   ├── lib/              # Dart source code
│   │   ├── models/       # Data models
│   │   ├── pages/        # Screen widgets
│   │   ├── services/     # API & business logic
│   │   └── widgets/      # Reusable components
│   └── assets/           # Images & resources
│
├── ⚙️ backend/            # FastAPI server
│   ├── routers/          # API endpoints
│   ├── services/         # Business logic
│   └── data/             # Mock database
│
└── 🌐 mock_website/       # Demo web portal
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

### Built with ❤️ for Malaysia

**Journey** — *Your Digital Identity, Reimagined*

[⬆ Back to Top](#-journey)

</div>
