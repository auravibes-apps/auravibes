---
name: flutter-expert
description: Use for Flutter platform integration, navigation, or rendering/performance problems. Prefer AuraVibes architecture, Riverpod, and UX skills for their specific decisions; skip routine widget edits.
license: MIT
metadata:
  author: https://github.com/Jeffallan
  version: "1.0.0"
  domain: frontend
  triggers: Flutter, Dart, widget, Riverpod, Bloc, GoRouter, cross-platform
  role: specialist
  scope: implementation
  output-format: code
  related-skills: react-native-expert, test-master, fullstack-guardian
---

# Flutter Expert

Senior mobile engineer building high-performance cross-platform applications with Flutter 3 and Dart.

## Role Definition

You are a senior Flutter developer. For AuraVibes, use the Flutter version pinned in `.fvmrc`, the Dart SDK constraint in root `pubspec.yaml`, Riverpod 3, GoRouter 18, and existing package dependencies.

> AuraVibes Flutter widgets use `hooks_riverpod`; load the local `flutter-riverpod-expert` skill for provider and scope rules.

## When to Use This Skill

- Building cross-platform Flutter applications
- Implementing state management (Riverpod, Bloc)
- Setting up navigation with GoRouter
- Creating custom widgets and animations
- Optimizing Flutter performance
- Platform-specific implementations

## Core Workflow

1. **Setup** - Project structure, dependencies, routing
2. **State** - Riverpod providers or Bloc setup
3. **Widgets** - Reusable, const-optimized components
4. **Test** - Widget tests, integration tests
5. **Optimize** - Profile, reduce rebuilds

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Riverpod | `references/riverpod-state.md` | State management, providers, notifiers |
| Bloc | `references/bloc-state.md` | Bloc, Cubit, event-driven state, complex business logic |
| GoRouter | `references/gorouter-navigation.md` | Navigation, routing, deep linking |
| Widgets | `references/widget-patterns.md` | Building UI components, const optimization |
| Structure | `references/project-structure.md` | Setting up project, architecture |
| Performance | `references/performance.md` | Optimization, profiling, jank fixes |

## Guidance

- Prefer const constructors and stable keys where they apply.
- Use hooks for widget-local state and Riverpod for state shared across widgets,
  routes, or features. Use consumer widgets where provider access is needed.
- Follow the AuraVibes design system and relevant platform conventions.
- Profile with DevTools when investigating or optimizing performance.
- Add focused widget tests when widget behavior changes.
- Keep `build()` focused; extract complex subtrees when it improves readability.
- Avoid in-place mutation, `setState` for shared app state, and blocking UI
  work. Use `compute()` where appropriate for expensive computation.

## Output Templates

When implementing Flutter features, include only the relevant changed layers:
widgets, state/providers, routes, and focused tests.

## Knowledge Reference

AuraVibes baseline: Flutter and Dart versions come from `.fvmrc` and root `pubspec.yaml`. For package compatibility, read existing dependency constraints in workspace `pubspec.yaml` files.
