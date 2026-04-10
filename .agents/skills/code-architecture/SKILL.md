---
name: code-architecture
description: Use when code needs to be writen or read in apps codebases. Where is the code location, how and when to use it, and best practices for each layer of the code architecture.
---

# Code Architecture

The code is organized in feature base structure. then there are data, services outside of features.

## Usecases
holde the business logic
check `./doc/architecture/usecases-pattern.md` for detail description
usecases locations `apps/<app_name>/lib/features/<feature_name>/usecases/<usecase_name>_usecase.dart`

# Notifiers
dont have business logic, ony app runtime states that usecases can manage
location: `apps/<app_name>/lib/features/<feature_name>/notifiers/<notifier_name>_notifier.dart`
check `../../../doc/architecture/notifier-pattern.md` for detail description

# Providers
dependencies results for UI to consume.
like fetching repository data.
not meant to be consumed by usecases or notifiers, but by the UI layer.

# Repositories
persist data in local DB
