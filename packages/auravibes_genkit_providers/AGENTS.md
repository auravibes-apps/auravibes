# AuraVibes Genkit Providers Agent Instructions

## Scope

- Applies to `packages/auravibes_genkit_providers`.
- This package provides AuraVibes-specific Genkit model provider plugins.
- Keep it Flutter-free. Do not import app, UI, Riverpod, or Flutter packages.

## Provider Boundaries

- Preserve the public provider surface exposed from `auravibes_genkit_providers.dart`.
- Provider plugins should wrap external model APIs and protocol translation only.
- Do not add AuraVibes app business logic, persistence, localization, or UI concepts here.
- Keep API credentials injectable through callbacks or constructor parameters; never read environment variables or app storage directly.
- Preserve streaming and non-streaming behavior when changing request or response parsing.
- Keep provider-specific options in provider-specific option classes.

## HTTP And Protocol Handling

- Inject `http.Client` for tests and close only clients created by the provider.
- Preserve raw backend error details in `GenkitException.details`.
- Keep request body and header mapping explicit and covered by tests.
- Treat SSE parsing, tool-call mapping, token usage, and nested content parsing as compatibility-sensitive.

## Tests

- Use package tests with fake HTTP clients for request, response, error, and streaming behavior.
- Run focused tests from this package with `fvm dart test test/<file>`.
- Add or update tests whenever provider payload shape, headers, streaming events, model refs, or error mapping changes.
