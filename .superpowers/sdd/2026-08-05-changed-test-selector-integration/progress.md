# SDD ledger — plan: docs/superpowers/plans/2026-08-05-changed-test-selector-integration.md

Base commit: aa1cb7d6fd009f61619a595377df6e80a1a2dffd

Task 1: done — tooling dependencies and selector contract (focused contract tests pass; graph/runner intentionally deferred)
Task 2: pending — Git diff classification and reverse import selection
Task 3: pending — repository adapter, JSON CLI, explicit test runner
Task 4: pending — GitHub Actions integration
Task 5: pending — repository validation and rollout evidence

Global decisions: analyzer-based reverse import graph; explicit current test files for ordinary Dart changes; full suite for global/ambiguous changes; affected PR runs skip LCOV/Sonar; pushes and full-suite runs retain coverage.
