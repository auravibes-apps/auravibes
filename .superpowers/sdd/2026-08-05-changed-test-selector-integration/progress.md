# SDD ledger — plan: docs/superpowers/plans/2026-08-05-changed-test-selector-integration.md

Base commit: aa1cb7d6fd009f61619a595377df6e80a1a2dffd

Task 1: fix round 1/5 (2 addressed, 0 open; commits 096b1179..25e22142)
Task 1: complete (commits 096b1179..25e22142, review clean)
Task 2: fix round 1/5 (3 addressed, 0 open; commits ced64f47..e2cf6ccd)
Task 2: complete (commits ced64f47..e2cf6ccd, review clean)
Task 3: fix round 1/5 (1 addressed, 0 open; commits 83625d31..27c53a27)
Task 3: complete (commits 83625d31..27c53a27, review clean)
Task 4: complete (commit 6cfea6b6, review clean)
Task 5: validation blocked — 96 fatal analyzer infos in selector tests; quick validation failed
Task 6: complete — production and test selector analyzer clean; focused tests pass; commit pending
Global decisions: analyzer-based reverse import graph; explicit current test files for ordinary Dart changes; full suite for global/ambiguous changes; affected PR runs skip LCOV/Sonar; pushes and full-suite runs retain coverage.
