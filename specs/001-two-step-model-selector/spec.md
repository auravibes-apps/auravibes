# Feature Specification: Two-Step Model Selector

**Feature Branch**: `001-two-step-model-selector`  
**Created**: 2026-03-11  
**Status**: Draft  
**Input**: User description: "Replace single model dropdown with two-step provider-first model selection UX"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Select Provider Then Model (Priority: P1)

As a user starting a new chat, I want to select my AI provider first (e.g., OpenAI, Anthropic), then choose a specific model from that provider, so I can quickly find the model I need without scrolling through a mixed list.

**Why this priority**: This is the core functionality - the primary user flow that solves the UX problem. Without this, the feature has no value.

**Independent Test**: Can be fully tested by opening a new chat screen, selecting a provider from the first dropdown, then selecting a model from the filtered second dropdown, and starting a conversation with the selected model.

**Acceptance Scenarios**:

1. **Given** I am on the new chat screen, **When** I open the provider dropdown, **Then** I see a list of all providers with configured credentials
2. **Given** I have not selected a provider, **When** I view the model dropdown, **Then** it is disabled and shows "Select provider first"
3. **Given** I have selected "OpenAI" as provider, **When** I open the model dropdown, **Then** I see only OpenAI models (gpt-4o, gpt-4o-mini, etc.)
4. **Given** I have selected a provider and model, **When** I change the provider, **Then** the model selection resets to empty

---

### User Story 2 - Quick Model Switching (Priority: P2)

As a user who has already selected a provider, I want to quickly switch between models within the same provider without re-selecting the provider, so I can compare different models efficiently.

**Why this priority**: Enhances efficiency for users who switch models frequently, but the feature is still useful without it.

**Independent Test**: Can be tested by selecting a provider, then switching between multiple models in the second dropdown without touching the provider dropdown.

**Acceptance Scenarios**:

1. **Given** I have selected "Anthropic" and "claude-3-opus", **When** I open the model dropdown again, **Then** I can directly select "claude-3-sonnet" without changing provider
2. **Given** I have a model selected, **When** I start typing in the model dropdown, **Then** models are filtered by my search term

---

### User Story 3 - Single Provider Auto-Selection (Priority: P3)

As a user with only one provider configured, I want that provider to be pre-selected so I only need to choose a model, reducing the number of steps needed.

**Why this priority**: Nice-to-have optimization that reduces friction for simple configurations, but core functionality works without it.

**Independent Test**: Can be tested by configuring only one provider with credentials, then opening the new chat screen and verifying the provider is pre-selected.

**Acceptance Scenarios**:

1. **Given** I have only "OpenAI" configured, **When** I open the new chat screen, **Then** OpenAI is pre-selected in the provider dropdown
2. **Given** I have only one provider configured, **When** I view the provider dropdown, **Then** it still shows the provider name (not hidden)

---

### Edge Cases

- What happens when no providers are configured? → Show "No providers configured" message, both dropdowns disabled
- What happens when a provider has no models available? → Show "No models available" in model dropdown
- What happens when credentials fail to load? → Show error state with retry option
- What happens when user has many providers (10+)? → Dropdown remains scrollable, alphabetical sorting

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display a provider dropdown listing all providers with configured credentials
- **FR-002**: System MUST display a model dropdown that is disabled until a provider is selected
- **FR-003**: System MUST filter the model dropdown to show only models from the selected provider
- **FR-004**: System MUST reset the model selection when the provider selection changes
- **FR-005**: System MUST enable the chat input only when both provider and model are selected
- **FR-006**: System MUST display provider names in alphabetical order
- **FR-007**: System MUST display model IDs (not internal IDs) in the model dropdown
- **FR-008**: System MUST handle loading states while fetching providers and models
- **FR-009**: System MUST display error messages when provider/model data fails to load

### Key Entities

- **Provider**: Represents an AI service provider (e.g., OpenAI, Anthropic). Has a name and contains multiple models.
- **Model**: Represents a specific AI model within a provider (e.g., gpt-4o, claude-3-opus). Belongs to exactly one provider.
- **Credentials**: User's authentication configuration for a provider. A provider is only shown if credentials exist.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can select a model with 2 taps (provider + model) instead of searching through a mixed list
- **SC-002**: Model selection time reduced by 50% for users with 5+ configured providers
- **SC-003**: Zero user confusion about which provider a model belongs to
- **SC-004**: Feature scales to 50+ models across 10+ providers without performance degradation
- **SC-005**: 100% of users successfully complete model selection on first attempt

## Assumptions

- Users think "provider-first" when selecting models (validated through user research)
- Most users stick with one provider per session (validated through user research)
- The existing dropdown component supports the required two-dropdown layout
- Provider names are unique and can be used as identifiers in the grouped map
- Model IDs are unique within a provider but may overlap across providers

## Out of Scope

- Remembering/persisting the last selected provider across sessions
- Favorite/recent models section
- Model capability indicators (e.g., "supports vision", "fast")
- Provider-specific customization or branding
- Multi-select for comparing models side-by-side
