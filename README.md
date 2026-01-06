# AuraVibes

[![Flutter](https://img.shields.io/badge/Flutter-3.38.3+-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10.0+-0175C2?style=flat-square&logo=dart)](https://dart.dev)
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
- 🛠️ **Custom Tools**: Extend capabilities with custom tools and integrations
- 🎨 **Beautiful Design**: Modern UI with Material Design 3 and custom theming
- 🌍 **Cross-Platform**: Native apps for iOS, Android, macOS, Windows, Linux, and Web
- 🌐 **Multi-Language**: Support for English and Spanish with easy localization
- 🔒 **Secure Storage**: Secure local storage for API keys and sensitive data

*TODO: Verify feature list is current and accurate*

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

#### Required Software

- **Flutter SDK**: 3.38.3 or higher (managed via FVM)
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

#### Platform-Specific Requirements

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

#### Development Tools (Recommended)

- **Visual Studio Code** with Flutter and Dart extensions
- **Android Studio** with Flutter and Dart plugins
- **Git** for version control

### Verification

Verify your Flutter installation:
```bash
flutter doctor
```

Expected output should show:
- ✅ Flutter version 3.38.3 or higher
- ✅ Android toolchain / Xcode / Visual Studio (depending on platform)
- ✅ Connected device or emulator

### Installation

Follow these steps to get a local copy up and running:

#### 1. Clone the Repository

```bash
git clone https://github.com/your-username/auravibes.git
cd auravibes
```

#### 2. Install Flutter Version via FVM

```bash
# Install the required Flutter version
fvm install 3.38.3

# Use this version for the project
fvm use 3.38.3

# Verify installation
fvm flutter --version
```

#### 3. Bootstrap the Workspace

This installs all dependencies across all packages in the monorepo:

```bash
# Install dependencies and link packages
melos bootstrap

# Verify all packages are discovered
melos list
```

Expected output should list packages like:
- `auravibes_app` (main app)
- `auravibes_core` (core utilities)
- `auravibes_ui` (design system)
- Other feature packages

#### 4. Set Up Environment Variables

Copy the example environment file and add your API keys:

```bash
cp .env.example .env
```

Edit `.env` with your actual API keys:

```bash
# Required
ANTHROPIC_API_KEY=sk-ant-api03-your-key-here

# Optional AI Providers
OPENAI_API_KEY=your-openai-key-here
PERPLEXITY_API_KEY=your-perplexity-key-here
GOOGLE_API_KEY=your-google-key-here
MISTRAL_API_KEY=your-mistral-key-here

# Optional Features
GITHUB_API_KEY=your-github-key-here
```

**Note**: Keep `.env` file private and never commit it to version control.

#### 5. Run Code Generation (Optional)

Generate required code for Riverpod, Freezed, and JSON serialization:

```bash
melos run generate
```

#### 6. Validate Setup

Run a quick validation to ensure everything is configured correctly:

```bash
# Quick validation (analyzes and formats)
melos run validate:quick

# Full validation (includes tests)
melos run validate
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

#### View Available Devices

```bash
fvm flutter devices
```

#### Hot Reload and Hot Restart

While running the app:
- Press `r` for **Hot Reload** (preserves app state)
- Press `R` for **Hot Restart** (resets app state)
- Press `q` to quit

### Troubleshooting

#### Issue: "fvm: command not found"
**Solution**: Add FVM to your PATH
```bash
# macOS/Linux
export PATH="$PATH:$HOME/.pub-cache/bin"

# Windows
# Add C:\Users\{username}\AppData\Local\Pub\Cache\bin to PATH
```

#### Issue: "flutter: command not found"
**Solution**: Verify FVM is properly configured
```bash
fvm flutter --version
# If this works, use 'fvm flutter' instead of 'flutter'
```

#### Issue: "Gradle build failed"
**Solution**: Clean and rebuild
```bash
cd apps/auravibes_app
cd android
./gradlew clean
cd ..
fvm flutter clean
fvm flutter pub get
```

#### Issue: "Unable to find bundled Java version"
**Solution**: Install JDK
```bash
# macOS
brew install openjdk

# Linux
sudo apt-get install default-jdk
```

#### Issue: "CocoaPods not installed" (iOS/macOS)
**Solution**: Install CocoaPods
```bash
sudo gem install cocoapods
cd apps/auravibes_app/ios
pod install
```

#### Issue: "melos: command not found"
**Solution**: Install Melos globally
```bash
dart pub global activate melos
export PATH="$PATH:$HOME/.pub-cache/bin"
```

## 📁 Project Structure

This is a Melos-managed monorepo with the following structure:

```
auravibes/
├── apps/
│   ├── auravibes_app/       # Main Flutter application
│   └── auravibes_shell/     # Legacy app (being migrated)
├── packages/
│   ├── core/
│   │   └── auravibes_core/  # Core utilities and helpers
│   ├── domain/              # Domain logic (pure Dart)
│   ├── application/         # Use cases and app services
│   ├── infrastructure/     # External integrations and adapters
│   ├── presentation/
│   │   └── auravibes_ui/    # Design system and UI components
│   └── features/            # Feature modules
├── docs/                    # Documentation
├── AGENTS.md                # Development guidelines
├── pubspec.yaml             # Workspace configuration
├── melos.yaml               # Melos configuration
└── .fvmrc                   # Flutter version specification
```

### Architecture

The app follows **Clean Architecture** principles with clear separation of concerns:

- **Domain Layer**: Business logic, entities, and use cases (pure Dart, no Flutter dependencies)
- **Application Layer**: Orchestration of use cases and application services
- **Infrastructure Layer**: External integrations (API clients, databases, storage)
- **Presentation Layer**: UI components and state management (Flutter widgets)

### Key Technologies

- **State Management**: [Riverpod](https://riverpod.dev) with code generation
- **Navigation**: [GoRouter](https://gorouter.dev) for declarative routing
- **Database**: [Drift](https://drift.simonbinder.eu) for local SQLite database
- **Networking**: [Dio](https://pub.dev/packages/dio) for HTTP requests
- **Localization**: [Easy Localization](https://pub.dev/packages/easy_localization)
- **Code Generation**: [Build Runner](https://pub.dev/packages/build_runner), [Freezed](https://pub.dev/packages/freezed)
- **AI Integration**: Anthropic SDK, LangChain, OpenAI Dart

## 🧪 Testing

### Running Tests

```bash
# Run all tests
melos run test

# Run tests in a specific package
melos exec --scope=auravibes_app -- flutter test

# Run tests with coverage
melos run test:coverage

# Run tests on specific file
fvm flutter test test/chat_test.dart
```

### Test Structure

```
test/
├── unit/           # Unit tests for business logic
├── widget/         # Widget tests for UI components
└── integration/    # Integration tests
```

### Coverage

The project requires **minimum 80% code coverage** for new code. View coverage report:

```bash
# Generate coverage report
melos run test:coverage

# View HTML report (after generation)
open coverage/lcov/index.html  # macOS
xdg-open coverage/lcov/index.html  # Linux
start coverage/lcov/index.html  # Windows
```

## 🏗️ Building for Production

### Android

```bash
cd apps/auravibes_app

# Build APK (for direct installation)
fvm flutter build apk --release --flavor prod

# Build App Bundle (for Google Play Store)
fvm flutter build appbundle --release --flavor prod

# Output location:
# APK: build/app/outputs/flutter-apk/app-release.apk
# App Bundle: build/app/outputs/bundle/release/app-release.aab
```

### iOS

```bash
cd apps/auravibes_app

# Build iOS app
fvm flutter build ios --release --flavor prod

# Then open in Xcode for final signing and archive
open ios/Runner.xcworkspace

# In Xcode: Product > Archive
```

**Note**: Requires Apple Developer account, proper code signing, and provisioning profiles.

### Web

```bash
cd apps/auravibes_app

# Build for production web deployment
fvm flutter build web --release --flavor prod

# Output location: build/web/
# Deploy to any static hosting service (Netlify, Vercel, GitHub Pages, etc.)
```

### macOS

```bash
cd apps/auravibes_app

# Build macOS app
fvm flutter build macos --release --flavor prod

# Output location: build/macos/Build/Products/Release/
```

### Windows

```bash
cd apps/auravibes_app

# Build Windows executable
fvm flutter build windows --release --flavor prod

# Output location: build/windows/runner/Release/
```

### Linux

```bash
cd apps/auravibes_app

# Build Linux executable
fvm flutter build linux --release --flavor prod

# Output location: build/linux/x64/release/bundle/
```

### Build Flavors

The app supports two build configurations:

| Flavor | App Name | Bundle ID | Use Case |
|--------|----------|-----------|----------|
| **prod** | AuraVibes | `me.auravibes.app` | Production builds |
| **dev** | AuraVibes Dev | `me.auravibes.app.dev` | Development builds |

## 🔧 Development Workflow

### Melos Commands

The project uses [Melos](https://melos.invertase.dev) for monorepo management. Key commands:

```bash
# Bootstrap - Install dependencies and link packages
melos bootstrap

# Clean - Remove build artifacts
melos clean

# Analyze - Run static analysis on all packages
melos run analyze

# Format - Check and fix code formatting
melos run format

# Test - Run all tests
melos run test

# Generate - Run code generation (Riverpod, Freezed, JSON)
melos run generate

# Validate:quick - Quick development check
melos run validate:quick

# Validate - Full CI validation
melos run validate

# Reset - Clean and regenerate everything
melos run reset

# List - Show all discovered packages
melos list

# Execute - Run command in specific package
melos exec --scope=auravibes_app -- flutter run
```

### Code Generation

When modifying code that uses Riverpod providers, Freezed models, or JSON serialization:

```bash
# Run code generation
melos run generate

# Or run build watcher for continuous generation
melos exec -- flutter pub run build_runner watch --delete-conflicting-outputs
```

### Linting and Formatting

```bash
# Run static analysis
melos run analyze

# Format code
melos run format

# Fix linting issues
melos exec -- dart fix --apply
```

### VSCode Extensions

Recommended extensions for development:
- Flutter
- Dart
- Melos (optional)

## 🔑 Environment Configuration

### Required API Keys

The app requires at least one AI provider API key to function:

```bash
# Minimum required
ANTHROPIC_API_KEY=sk-ant-api03-...
```

Get your Anthropic API key from [console.anthropic.com](https://console.anthropic.com/)

### Optional AI Providers

The app supports multiple AI providers:

| Provider | API Key Variable | Website |
|----------|------------------|---------|
| OpenAI | `OPENAI_API_KEY` | platform.openai.com |
| Perplexity | `PERPLEXITY_API_KEY` | perplexity.ai |
| Google | `GOOGLE_API_KEY` | console.cloud.google.com |
| Mistral | `MISTRAL_API_KEY` | console.mistral.ai |
| xAI | `XAI_API_KEY` | x.ai |
| Groq | `GROQ_API_KEY` | groq.com |
| OpenRouter | `OPENROUTER_API_KEY` | openrouter.ai |
| Azure OpenAI | `AZURE_OPENAI_API_KEY` | azure.microsoft.com |
| Ollama | `OLLAMA_API_KEY` | ollama.ai |

### Optional Features

```bash
# GitHub integration for import/export
GITHUB_API_KEY=your-github-personal-access-token
```

### Configuration Options

Runtime configuration in `lib/config/config.dart`:

```dart
const bool IS_DEV = true;              // Development mode
const bool STORE_LOCALE = true;        // Store locale preference
const double TINT_HUE = 259.47;        // Theme tint hue
const String APP_TITLE = 'Aura';       // App title
```

## 📋 TODO & Roadmap

### 🔴 High Priority

- [ ] **Add screenshots** to README showing key app features
- [ ] **Create demo video** or GIF for landing section
- [ ] **Add license file** (choose MIT, Apache 2.0, or other)
- [ ] **Create CONTRIBUTING.md** with contribution guidelines
- [ ] **Add end-to-end tests** for critical user flows

### 🟡 Medium Priority

- [ ] Implement offline support with local caching
- [ ] Add push notifications for agent responses
- [ ] Improve error handling and user feedback
- [ ] Add more language localizations beyond English/Spanish
- [ ] Optimize app performance and reduce bundle size

### 🟢 Low Priority

- [ ] Dark mode theme
- [ ] Custom animations and transitions
- [ ] Accessibility improvements
- [ ] Widgetbook for design system documentation
- [ ] CI/CD pipeline improvements

### Known Issues

- **Navigation animation flickering on iOS**: Under investigation
- **Memory leak in chat widget**: Workaround implemented, tracking in issue tracker
- **Hot reload occasionally fails**: Sometimes requires hot restart

### Upcoming Features

- [ ] Voice input/output support
- [ ] File attachments in conversations
- [ ] Agent marketplace/community sharing
- [ ] Advanced analytics dashboard
- [ ] Custom agent builder UI

*TODO: Create GitHub Issues for these items and link them here*

## 📚 Documentation

- [Architecture Guide](docs/monorepo-architecture-guide.md) - Detailed monorepo architecture
- [AGENTS.md](AGENTS.md) - Development workflow and commands
- [Design System](packages/auravibes_ui/README.md) - UI component library
- [Flutter Documentation](https://docs.flutter.dev) - Official Flutter docs
- [Riverpod Documentation](https://riverpod.dev) - State management docs

## 🤝 Contributing

We love contributions! Here's how you can help:

### Getting Started

1. **Fork the repository**
   ```bash
   # Click "Fork" on GitHub, then clone your fork
   git clone https://github.com/your-username/auravibes.git
   cd auravibes
   ```

2. **Set up your development environment**
   ```bash
   # Follow the "Installation" section above
   fvm install 3.38.3
   melos bootstrap
   ```

3. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Make your changes**
   - Write tests for new functionality
   - Ensure all tests pass: `melos run test`
   - Run linter: `melos run analyze`
   - Format code: `melos run format`

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

6. **Push and create a Pull Request**
   ```bash
   git push origin feature/your-feature-name
   # Create PR on GitHub
   ```

### Commit Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting)
- `refactor:` Code refactoring
- `test:` Adding or updating tests
- `chore:` Build process or auxiliary tool changes

Example: `feat(auth): add login form with validation`

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `const` constructors where possible
- Write meaningful comments for complex logic
- Maintain minimum 80% test coverage

### Pull Request Guidelines

- Link to related GitHub Issues
- Describe what you changed and why
- Include screenshots if applicable (for UI changes)
- Ensure all CI checks pass
- Request review from at least one maintainer

*TODO: Create detailed CONTRIBUTING.md with full guidelines*

## 👥 Authors

- **[Your Name](https://github.com/your-username)** - *Initial work*

See the list of [contributors](https://github.com/your-username/auravibes/contributors) who participated in this project.

*TODO: Add contributor information and team details*

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

*TODO: Choose and create LICENSE file (MIT, Apache 2.0, GPL, etc.)*

## 🙏 Acknowledgments

- [Flutter Team](https://flutter.dev) for the amazing framework
- [Riverpod](https://riverpod.dev) for excellent state management
- [Anthropic](https://anthropic.com) for AI capabilities
- All contributors and community members

## 📞 Support & Resources

### Documentation

- [Official Flutter Documentation](https://docs.flutter.dev)
- [Dart Language Guide](https://dart.dev/guides)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Riverpod Documentation](https://riverpod.dev)

### Community

- [Flutter Community Discord](https://discord.gg/flutter)
- [Stack Overflow - Flutter](https://stackoverflow.com/questions/tagged/flutter)
- [r/FlutterDev on Reddit](https://reddit.com/r/FlutterDev)

### Issue Tracker

Report bugs and request features:
- [GitHub Issues](https://github.com/your-username/auravibes/issues)

---

**Note**: This is the main application. For the legacy app (being migrated), see `apps/auravibes_app/`.

Made with ❤️ using Flutter
