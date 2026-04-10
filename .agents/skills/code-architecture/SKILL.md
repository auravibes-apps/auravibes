---
name: code-architecture
description: Use when code needs to be writen or read in apps codebases. Where is the code location, how and when to use it, and best practices for each layer of the code architecture.
---

# Code Architecture

The code is organized in feature base structure. then there are data, services outside of features.

## Usecases
holde the business logic
check `../../../doc/architecture/usecases-pattern.md` for detailed description
usecases locations `apps/<app_name>/lib/features/<feature_name>/usecases/<usecase_name>_usecase.dart`

# Notifiers
Must not contain business logic. They only hold app runtime state that use cases can manage.
location: `apps/<app_name>/lib/features/<feature_name>/notifiers/<notifier_name>_notifier.dart`
See `../../../doc/architecture/notifier-pattern.md` for a detailed description

# Providers
dependencies results for UI to consume.
like fetching repository data.
not meant to be consumed by usecases or notifiers, but by the UI layer.

# Repositories
persist data in local DB
