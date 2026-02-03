# AuraVibes

[![Flutter](https://img.shields.io/badge/Flutter-3.38.9+-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10.3+-0175C2?style=flat-square&logo=dart)](https://dart.dev)
[![Melos](https://img.shields.io/badge/Melos-7.3.0-42a5f5?style=flat-square)](https://melos.invertase.dev)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android%20%7C%20macOS%20%7C%20Web%20%7C%20Linux%20%7C%20Windows-lightgrey)](#)

> A powerful AI-powered Flutter application with multi-agent support, featuring intelligent conversations, workspace management, and seamless cross-platform experience.

[Demo Video](#) • [Architecture Guide](docs/monorepo-architecture-guide.md) • [Design System](packages/auravibes_ui/README.md)

## 📸 Screenshots

<div align="center">
  <img src="assets/screenshots/home.png" width="250" alt="Home Screen">
  <img src="assets/screenshots/chat.png" width="250" alt="Chat Screen">
  <img src="assets/screenshots/agents.png" width="250" alt="Agents Screen">
  <img src="assets/screenshots/settings.png" width="250" alt="Settings Screen">
</div>

*TODO: Add actual screenshots showing key app features*

## ✨ Features

- 🤖 **Multi-Agent System**: Intelligent AI agents powered by Anthropic, OpenAI, and more
- 💬 **Rich Conversations**: Threaded chat with history and context preservation
- 📁 **Workspace Management**: Organize chats and agents into workspaces
- 🛠️ **MCPs**: Extend capabilities with http/sse MCPs
- 🌍 **Cross-Platform**: Native apps for iOS, Android, macOS, Windows, Linux, and Web
- 🌐 **Multi-Language**: Support for English and Spanish with easy localization
- 🔒 **Secure Storage**: Secure local storage for API keys and sensitive data

*TODO: Verify feature list is current and accurate*

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

#### Required Software

- **Flutter SDK**: 3.38.9 or higher (managed via FVM)
  - Download from [flutter.dev](https://flutter.dev/docs/get-started/install)
  - Install [FVM](https://fvm.app) first: `dart pub global activate fvm`
  
- **Dart SDK**: 3.10.0 or higher (included with Flutter)
  
- **FVM (Flutter Version Management)**: 4.0.5 or higher
  ```bash
  dart pub global activate fvm
  ```

- **Melos**: 7.3.0 or higher (for monorepo management)
  ```bash
  dart pub global activate melos
  ```
<details>

<summary>Platform-Specific Requirements</summary>

**Android Development**
- Android Studio (latest version) with Flutter and Dart plugins
- Android SDK API level 21 or higher
- Android SDK Build-Tools

**iOS Development** (macOS only)
- Xcode 14.0 or higher
- CocoaPods: `sudo gem install cocoapods`
- iOS Simulator or physical iOS device

**macOS Development**
- Xcode 14.0 or higher
- CocoaPods

**Linux Development**
- GTK 3.0 development libraries
- See [Linux setup guide](https://flutter.dev/docs/desktop#additional-linux-requirements)

**Windows Development**
- Visual Studio 2022 with C++ desktop development
- See [Windows setup guide](https://flutter.dev/docs/desktop#additional-windows-requirements)

**Web Development**
- Chrome browser (latest version)
</details>


### Installation

Follow these steps to get a local copy up and running:

#### 1. Clone the Repository

```bash
git clone https://github.com/auravibes-apps/auravibes.git
cd auravibes
```

#### 2. Install Flutter Version via FVM

```bash
# Install and use this version for the project
fvm use

# Verify installation
fvm flutter --version
```

#### 3. Bootstrap the Workspace

This installs all dependencies across all packages in the monorepo:

```bash
# Install dependencies and link packages
melos bootstrap
```

#### 4. Run Code Generation

Generate required code for Riverpod, Freezed, and JSON serialization:

```bash
melos run generate
```

### Running the App

The app supports two flavors: **dev** (development) and **prod** (production).

#### Using VSCode Launch Configurations (Recommended)

The project includes pre-configured launch configurations in `.vscode/launch.json`:

- **prod Debug**: Production flavor, debug mode
- **prod Profile**: Production flavor, profile mode  
- **prod Release**: Production flavor, release mode
- **dev Debug**: Development flavor, debug mode
- **dev Profile**: Development flavor, profile mode
- **dev Release**: Development flavor, release mode

#### Using Command Line

Navigate to the app directory and run with your desired flavor:

```bash
cd apps/auravibes_app

# Run production flavor (recommended for testing)
fvm flutter run --flavor prod

# Run development flavor
fvm flutter run --flavor dev
```

#### Run on Specific Platform

```bash
# Web (Chrome)
fvm flutter run -d chrome --flavor prod

# macOS
fvm flutter run -d macos --flavor prod

# Android (requires emulator or connected device)
fvm flutter run -d android --flavor prod

# iOS (macOS only, requires simulator or connected device)
fvm flutter run -d ios --flavor prod

# Windows
fvm flutter run -d windows --flavor prod

# Linux
fvm flutter run -d linux --flavor prod
```

### Key Technologies

- **State Management**: [Riverpod](https://riverpod.dev) with code generation
- **Navigation**: [GoRouter](https://gorouter.dev) for declarative routing
- **Database**: [Drift](https://drift.simonbinder.eu) for local SQLite database
- **Networking**: [Dio](https://pub.dev/packages/dio) for HTTP requests
- **Localization**: [Easy Localization](https://pub.dev/packages/easy_localization)
- **Code Generation**: [Build Runner](https://pub.dev/packages/build_runner), [Freezed](https://pub.dev/packages/freezed)



---

Made with ❤️ using Flutter
