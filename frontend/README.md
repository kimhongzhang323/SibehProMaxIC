<div align="center">

# 📱 Journey Frontend

### Flutter Mobile Application

[![Flutter](https://img.shields.io/badge/Flutter-3.6-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Material 3](https://img.shields.io/badge/Material_3-Design-757575?style=for-the-badge&logo=material-design&logoColor=white)](https://m3.material.io/)

</div>

---

## 📖 Overview

The frontend is a cross-platform Flutter application that provides a unified interface for managing Malaysian digital identities, complete with AI assistance, biometric security, and seamless web integration.

---

## 🏗️ Architecture

```
frontend/
├── lib/
│   ├── main.dart              # Application entry point
│   ├── api_service.dart       # Backend API client
│   │
│   ├── # Core Pages
│   ├── landing_page.dart      # Home dashboard
│   ├── id_page.dart           # Digital ID display
│   ├── profile_page.dart      # User profile
│   ├── scanner_page.dart      # QR code scanner
│   ├── chat_page.dart         # AI assistant
│   │
│   ├── # Government Services
│   ├── jpn_page.dart          # JPN services
│   ├── jpj_page.dart          # JPJ services
│   ├── immigration_page.dart  # Immigration
│   ├── lhdn_page.dart         # LHDN tax services
│   ├── kwsp_page.dart         # KWSP/EPF
│   ├── perkeso_page.dart      # PERKESO/SOCSO
│   ├── moh_page.dart          # MOH health services
│   │
│   ├── # Utilities
│   ├── print_ic_page.dart     # PDF generation
│   ├── replace_ic_page.dart   # IC replacement
│   ├── verification_page.dart # Document verification
│   │
│   ├── models/                # Data models
│   ├── pages/                 # Additional screens
│   ├── services/              # Business logic
│   └── widgets/               # Reusable components
│
└── assets/
    └── images/                # App images & icons
```

---

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.6+
- Android Studio / Xcode (for emulators)
- VS Code with Flutter extension (recommended)

### Installation

```bash
# Navigate to frontend directory
cd frontend

# Get dependencies
flutter pub get

# Check Flutter setup
flutter doctor
```

### Running the App

```bash
# List available devices
flutter devices

# Run on default device
flutter run

# Run on specific device
flutter run -d <device_id>

# Run in release mode
flutter run --release
```

---

## 📦 Key Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `http` | API communication |
| `mobile_scanner` | QR code scanning |
| `flutter_secure_storage` | Encrypted storage |
| `local_auth` | Biometric authentication |
| `qr_flutter` | QR code generation |
| `pdf` & `printing` | PDF document generation |
| `flutter_markdown` | Markdown rendering |
| `crypto` | Encryption utilities |

---

## 🎨 Design System

The app uses **Material 3** with a custom theme:

- **Primary Color**: Malaysian Blue
- **Typography**: Clean, modern fonts
- **Components**: Rounded corners, subtle shadows
- **Dark Mode**: Full support

---

## 📱 Supported Platforms

| Platform | Status |
|----------|--------|
| Android | ✅ Fully Supported |
| iOS | ✅ Fully Supported |
| Web | 🧪 Experimental |
| Windows | 🧪 Experimental |
| macOS | 🧪 Experimental |
| Linux | 🧪 Experimental |

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

---

## 🔨 Build

```bash
# Build APK (Android)
flutter build apk --release

# Build App Bundle (Android)
flutter build appbundle --release

# Build IPA (iOS)
flutter build ipa --release

# Build for Web
flutter build web --release
```

---

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Material 3 Guidelines](https://m3.material.io/)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)

---

<div align="center">

**[← Back to Main README](../README.md)**

</div>
