# AuraVibes

[![Flutter](https://img.shields.io/badge/Flutter-3.47.5-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%5E3.13.0-0175C2?style=flat-square&logo=dart)](https://dart.dev)
[![Melos](https://img.shields.io/badge/Melos-%5E8.7.0-42a5f5?style=flat-square)](https://melos.invertase.dev)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android%20%7C%20macOS%20%7C%20Web%20%7C%20Linux%20%7C%20Windows-lightgrey)

> An AI-powered Flutter app for conversations, agents, and workspace management across mobile, desktop, and Web targets.

[Architecture docs](doc/architecture/README.md) • [Design System](packages/auravibes_ui/README.md)

## ✨ Features

- 🤖 **AI agents and model providers**: Configure model providers and run agents
- 💬 **Conversations**: Keep chat history and conversation context
- 📁 **Workspaces**: Organize chats and agents into workspaces
- 🛠️ **MCP connections**: Connect workspace tools over Streamable HTTP or SSE
- 🌍 **Platform targets**: Android, iOS, macOS, Web, Windows, and Linux
- 🌐 **English and Spanish**: Switch between the supported interface locales

Chat attachments are unavailable on Web. Support is tracked in
[issue #1063](https://github.com/auravibes-apps/auravibes/issues/1063).

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

#### Required Software

- **Flutter SDK**: 3.47.5, pinned in `.fvmrc`
  - Download from [Flutter](https://docs.flutter.dev/install)
  - Install [FVM](https://fvm.app) first: `dart pub global activate fvm`

- **Dart SDK**: `^3.13.0` (included with the pinned Flutter SDK)
- **FVM (Flutter Version Management)**: 4.0.5 or higher
- **Melos**: `^8.7.0`, provided by the root `pubspec.yaml`; run it through FVM
  <details>

<summary>Platform-Specific Requirements</summary>

**Android Development**

- Android Studio (latest version) with Flutter and Dart plugins
- Android SDK API level 21 or higher
- Android SDK Build-Tools

**iOS Development** (macOS only)

- Xcode 14.0 or higher
- iOS Simulator or physical iOS device

**macOS Development**

- Xcode 14.0 or higher

**Linux Development**

- GTK 3.0 development libraries
- See the [Linux setup guide](https://docs.flutter.dev/platform-integration/linux/setup)

**Windows Development**

- Visual Studio 2022 with C++ desktop development
- See the [Windows setup guide](https://docs.flutter.dev/platform-integration/windows/setup)

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
# Select the Flutter SDK pinned in .fvmrc
fvm use

# Verify installation
fvm flutter --version
```

FVM selects the SDK pinned in `.fvmrc`, updates the local SDK link and VS Code
setting, and runs `flutter pub get` by default when the SDK changes. This
repository enables Pub resolution on SDK changes; pass `--skip-pub-get` to
skip it.

#### 3. Bootstrap the Workspace

Run the repository's Melos workspace bootstrap with the pinned SDK:

```bash
fvm dart run melos bootstrap
```

The root Pub workspace declares its member packages. Melos bootstrap resolves
the workspace and generates ignored IntelliJ module files for its six
packages. CI's setup action runs Melos bootstrap before its integrity check
looks for dependency artifact drift. Keep the step in the fresh-checkout
sequence even though Pub handles workspace package resolution; a clean setup
should leave no tracked or untracked dependency changes.

#### 4. Run Code Generation

Generate required code for Riverpod, Freezed, and JSON serialization:

```bash
fvm dart run melos run generate
```

### Running the App

The app supports two flavors: **dev** (development) and **prod** (production).

#### Using VSCode Launch Configurations (Recommended)

The project includes pre-configured launch configurations in `.vscode/launch.json`:

- **dev Debug**: Development flavor, debug mode
- **dev Debug (DB hash source)**: Development flavor, debug mode with a
  full workspace path hash for isolated worktree databases
- **Widgetbook**: UI component catalog, debug mode

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
- **Navigation**: [go_router](https://pub.dev/packages/go_router) for declarative routing
- **Database**: [Drift](https://drift.simonbinder.eu) for local SQLite database
- **Networking**: [Dio](https://pub.dev/packages/dio) for HTTP requests
- **Localization**: [Easy Localization](https://pub.dev/packages/easy_localization)
- **Code Generation**: [Build Runner](https://pub.dev/packages/build_runner), [Freezed](https://pub.dev/packages/freezed)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, development, testing, and
pull request guidelines.

---

Made with ❤️ using Flutter
