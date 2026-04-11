# AuraVibes UI Package

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![Powered by Mason](https://img.shields.io/endpoint?url=https%3A%2F%2Ftinyurl.com%2Fmason-badge)](https://github.com/felangel/mason)
[![License: Apache 2.0][license_badge]][license_link]

A comprehensive UI package for the AuraVibes AI Assistant, built using atomic design principles and featuring a complete design system with tokens, components, and layouts.

## 🎨 Atomic Design Structure

This package follows the atomic design methodology, organizing components into five distinct levels:

### 🔬 Atoms (`lib/src/atoms/`)
The smallest building blocks of the design system:
- Buttons
- Icons  
- Text elements
- Input fields
- Loading indicators

### 🧪 Molecules (`lib/src/molecules/`)
Groups of atoms bonded together:
- Search forms (input + button)
- Cards with header and content
- Navigation items with icon and text
- Form fields with label and validation

### 🦠 Organisms (`lib/src/organisms/`)
Complex UI sections made of molecules:
- App headers with logo, navigation, and search
- Product listings with filters and cards
- Chat interfaces with messages and input
- Settings panels with multiple form sections

### 📄 Templates (`lib/src/templates/`)
Page-level layouts that organize organisms:
- Homepage layouts
- Article page layouts
- Dashboard layouts
- Profile page layouts

### 🎯 Design Tokens (`lib/src/tokens/`)
Design system constants ensuring consistency:
- Colors (primary, secondary, neutral, semantic)
- Typography (Inter font family, sizes, weights)
- Spacing (xs: 4px to xl3: 64px)
- Border radius, shadows, animations
- Component sizes and breakpoints

## 🚀 Features

- **Material Design 3** compliance with custom theming
- **Inter font family** integration via Google Fonts
- **SVG icon support** for scalable graphics
- **Responsive design** with defined breakpoints
- **Animation utilities** for smooth interactions
- **Accessibility** features built-in
- **Dark/Light theme** support
- **Glassmorphism effects** for modern UI

## Installation 💻

**❗ In order to start using Ui you must have the [Flutter SDK][flutter_install_link] installed on your machine.**

Install via `flutter pub add`:

```sh
dart pub add ui
```

---

## Continuous Integration 🤖

Ui comes with a built-in [GitHub Actions workflow][github_actions_link] powered by [Very Good Workflows][very_good_workflows_link] but you can also add your preferred CI/CD solution.

Out of the box, on each pull request and push, the CI `formats`, `lints`, and `tests` the code. This ensures the code remains consistent and behaves correctly as you add functionality or make changes. The project uses [Very Good Analysis][very_good_analysis_link] for a strict set of analysis options used by our team. Code coverage is enforced using the [Very Good Workflows][very_good_coverage_link].

---

## Running Tests 🧪

For first time users, install the [very_good_cli][very_good_cli_link]:

```sh
dart pub global activate very_good_cli
```

To run all unit tests:

```sh
very_good test --coverage
```

To view the generated coverage report you can use [lcov](https://github.com/linux-test-project/lcov).

```sh
# Generate Coverage Report
genhtml coverage/lcov.info -o coverage/

# Open Coverage Report
open coverage/index.html
```

[flutter_install_link]: https://docs.flutter.dev/get-started/install
[github_actions_link]: https://docs.github.com/en/actions/learn-github-actions
[license_badge]: https://img.shields.io/badge/license-Apache%202.0-blue.svg
[license_link]: ../../LICENSE
[logo_black]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_black.png#gh-light-mode-only
[logo_white]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_white.png#gh-dark-mode-only
[mason_link]: https://github.com/felangel/mason
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_cli_link]: https://pub.dev/packages/very_good_cli
[very_good_coverage_link]: https://github.com/marketplace/actions/very-good-coverage
[very_good_ventures_link]: https://verygood.ventures
[very_good_ventures_link_light]: https://verygood.ventures#gh-light-mode-only
[very_good_ventures_link_dark]: https://verygood.ventures#gh-dark-mode-only
[very_good_workflows_link]: https://github.com/VeryGoodOpenSource/very_good_workflows
