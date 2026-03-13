# Feature Specification: UI Library Widget Expansion

**Feature Branch**: `001-ui-library-widgets`  
**Created**: 2026-03-11  
**Status**: Draft  
**Input**: User description: "Expand auravibes_ui library with missing Material widgets (AlertDialog, TextButton, SnackBar, Radio, Tooltip, SelectableText)"

## Clarifications

### Session 2026-03-11

- Q: When a dialog is shown while another dialog is already visible, how should the system behave? → A: Stack - Show second dialog on top of first
- Q: What should happen when `showAuraSnackBar()` is called without a Scaffold ancestor? → A: Works (uses OverlayEntry, doesn't require Scaffold)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Confirmation Dialogs (Priority: P1)

As a developer using the AuraVibes UI library, I need a consistent, styled confirmation dialog component so that I can present destructive or important actions (delete, disconnect, clear) with a unified look and feel across the app.

**Why this priority**: Dialogs are used 15+ times throughout the app for critical user decisions (deleting MCP servers, confirming tool removal, theme selection). This is the most impactful widget to add.

**Independent Test**: Can be fully tested by creating an `AuraConfirmDialog` and verifying it displays title, message, cancel/confirm actions with proper styling and returns user selection.

**Acceptance Scenarios**:

1. **Given** a developer needs a confirmation dialog, **When** they use `showAuraConfirmDialog()`, **Then** a styled dialog appears with title, message, and customizable action buttons
2. **Given** a destructive action is being confirmed, **When** the confirm button uses `destructive` variant, **Then** it displays with error styling (red foreground)
3. **Given** a dialog is displayed, **When** the user taps outside on mobile, **Then** the dialog dismisses without confirming
4. **Given** a dialog needs custom content, **When** developer provides custom widget, **Then** it renders in the dialog body

---

### User Story 2 - Text Button Component (Priority: P1)

As a developer, I need a text-only button component (no background/border) so that I can create inline actions and dialog action buttons that match the Aura design system.

**Why this priority**: TextButton is used 12+ times in the app, primarily for dialog actions and inline text links. This is essential for completing the button system.

**Independent Test**: Can be fully tested by adding a `text` variant to `AuraButton` and verifying it renders text with no background, responds to taps, and supports color variants.

**Acceptance Scenarios**:

1. **Given** a developer needs a minimal button, **When** they use `AuraButton(variant: AuraButtonVariant.text)`, **Then** it displays text with transparent background
2. **Given** a text button in a dialog, **When** it's an error action, **Then** it uses `AuraColorVariant.error` for the text color
3. **Given** a text button is disabled, **When** `disabled: true`, **Then** text appears at reduced opacity and doesn't respond to taps
4. **Given** a text button with an icon, **When** `icon` parameter is provided, **Then** icon appears before the text with proper spacing

---

### User Story 3 - SnackBar Notifications (Priority: P2)

As a user, I need brief, non-intrusive feedback notifications so that I know when background operations succeed or fail without blocking my workflow.

**Why this priority**: SnackBar provides essential user feedback for async operations (MCP connections, model updates). Used 2 times but critical for UX.

**Independent Test**: Can be fully tested by calling `showAuraSnackBar()` and verifying a styled notification appears at the bottom of the screen, auto-dismisses, and can be swiped away.

**Acceptance Scenarios**:

1. **Given** an operation completes, **When** `showAuraSnackBar()` is called with a message, **Then** a styled notification appears at the bottom
2. **Given** an error occurs, **When** `variant: AuraSnackBarVariant.error` is used, **Then** the snackbar displays with error styling
3. **Given** a snackbar is shown, **When** 4 seconds pass, **Then** it auto-dismisses
4. **Given** a snackbar with an action, **When** `actionLabel` and `onAction` are provided, **Then** an action button appears that executes the callback

---

### User Story 4 - Radio Selection Components (Priority: P2)

As a user, I need to select one option from a list so that I can configure settings like app theme (system/light/dark) with clear visual feedback.

**Why this priority**: Radio selection is used for theme selection and could be used for future settings. Provides clear single-choice UX.

**Independent Test**: Can be fully tested by creating `AuraRadioGroup` with options and verifying only one can be selected at a time.

**Acceptance Scenarios**:

1. **Given** a list of mutually exclusive options, **When** `AuraRadioGroup` is displayed, **Then** all options are shown with radio indicators
2. **Given** no option is selected, **When** user taps an option, **Then** only that option's radio fills
3. **Given** an option is selected, **When** user taps a different option, **Then** the previous selection clears and the new one selects
4. **Given** a group has a label, **When** rendered, **Then** the label appears above the options with proper styling

---

### User Story 5 - Tooltip Component (Priority: P3)

As a user, I need contextual hints on hover/focus so that I can understand the purpose of icon-only buttons and other compact UI elements.

**Why this priority**: Used 2 times in tool group headers. Nice-to-have for improved accessibility and UX.

**Independent Test**: Can be fully tested by wrapping a widget with `AuraTooltip` and verifying the tooltip appears on hover/long-press with the provided message.

**Acceptance Scenarios**:

1. **Given** a widget with a tooltip, **When** user hovers (desktop) or long-presses (mobile), **Then** a styled tooltip appears
2. **Given** a tooltip is visible, **When** user moves away, **Then** the tooltip dismisses
3. **Given** a tooltip with a custom position, **When** `preferBelow: false`, **Then** tooltip appears above the widget
4. **Given** a tooltip with a custom color variant, **When** `colorVariant: AuraColorVariant.error` is set, **Then** tooltip uses the variant's colors

---

### User Story 6 - Selectable Text (Priority: P3)

As a user, I need to select and copy text content so that I can share error messages or other text from the application.

**Why this priority**: Used 2 times for displaying error messages that users may need to copy/share.

**Independent Test**: Can be fully tested by using `AuraSelectableText` and verifying text can be selected and copied via the platform's native selection mechanism.

**Acceptance Scenarios**:

1. **Given** selectable text is displayed, **When** user long-presses and drags, **Then** text is highlighted for selection
2. **Given** text is selected, **When** user uses copy action, **Then** the selected text is copied to clipboard
3. **Given** selectable text with custom style, **When** rendered, **Then** it matches the provided text style

---

### Edge Cases

- **Dialog stacking**: When a dialog is shown while another is visible, the second dialog stacks on top (standard Flutter/Material behavior)
- **SnackBar without Scaffold**: Flutter's native `ScaffoldMessenger.of(context)` error will propagate - no additional handling needed
- **Long messages in dialogs/snackbars**: Content wraps with scrollable area when exceeding available space
- **Empty or single-option radio group**: Empty group renders nothing; single option renders normally and is always selected
- **Tooltip near screen edges**: Flutter's Tooltip widget automatically repositions to stay within viewport

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The UI library MUST provide `AuraConfirmDialog` with customizable title, message, and actions
- **FR-002**: The UI library MUST provide `AuraAlertDialog` for simple alert dialogs with a single dismiss action
- **FR-003**: The UI library MUST provide `showAuraConfirmDialog()` and `showAuraAlertDialog()` helper functions for displaying dialogs
- **FR-004**: `AuraButton` MUST support a `text` variant with transparent background
- **FR-005**: The UI library MUST provide `showAuraSnackBar()` function for displaying snackbars
- **FR-006**: Snackbars MUST support semantic variants (default, success, error, warning, info)
- **FR-007**: The UI library MUST provide `AuraRadio` and `AuraRadioGroup` components
- **FR-008**: `AuraRadioGroup` MUST support both vertical and horizontal layouts
- **FR-009**: The UI library MUST provide `AuraRadioListTile` for list-style radio selections
- **FR-010**: The UI library MUST provide `AuraTooltip` widget for contextual hints
- **FR-011**: The UI library MUST provide `AuraSelectableText` for copyable text content
- **FR-012**: All new components MUST follow the const-first design pattern using `AuraColorVariant`
- **FR-013**: All new components MUST integrate with the Aura theme system (`context.auraColors`, `context.auraTheme`)
- **FR-014**: All new components MUST be exported from `package:auravibes_ui/ui.dart`

### Design System Compliance

- **DC-001**: All color parameters MUST use `AuraColorVariant` enum, not `Color` objects
- **DC-002**: All components MUST be const-constructible where possible
- **DC-003**: All components MUST use design tokens for spacing, typography, and colors
- **DC-004**: All components MUST follow atomic design organization (atoms/molecules/organisms)

### Key Entities

- **AuraConfirmDialog**: A dialog requiring user confirmation before proceeding. Contains title, message, and customizable actions.
- **AuraAlertDialog**: A simple dialog for displaying alerts. Contains title, message, and a single dismiss action.
- **AuraSnackBar**: A brief notification that appears at the bottom of the screen. Auto-dismisses after a timeout.
- **AuraRadioGroup**: A container managing mutually exclusive radio selections. Tracks the currently selected value.
- **AuraRadio**: An individual radio button that communicates with its parent group.
- **AuraRadioListTile**: A list tile with an integrated radio button for settings-style selections.
- **AuraTooltip**: A contextual hint that appears on hover/long-press to explain a widget's purpose.
- **AuraSelectableText**: Text content that users can select and copy using native platform selection.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All 15+ existing dialog usages in the app can be replaced with Aura dialog components
- **SC-002**: All 12+ existing TextButton usages can be replaced with `AuraButton(variant: text)`
- **SC-003**: All snackbar usages can be replaced with `showAuraSnackBar()`
- **SC-004**: Theme selection dialog uses `AuraRadioListTile` instead of Material `RadioListTile`
- **SC-005**: All new components have widget tests with 80%+ code coverage
- **SC-006**: All new components are documented with dartdoc comments
- **SC-007**: No Material widgets are imported directly in production code (only via UI library)

## Assumptions

- Desktop platforms (macOS, Windows, Linux) support hover for tooltips; mobile platforms use long-press
- Snackbars appear at the bottom of the screen (standard Material behavior)
- Dialogs are centered on screen (standard behavior)
- Radio groups can have 0 or 1 selected item (not required to have a selection)
- TextButton variant will be added to existing `AuraButton` component rather than creating a separate widget
- Dialogs will use `showDialog` internally but provide Aura-styled wrappers
- Snackbars will use `ScaffoldMessenger` internally but provide Aura-styled helpers

## Dependencies

- Existing `AuraColorVariant` enum and `AuraColorScheme` for color resolution
- Existing `AuraTypographyTheme` for text styling
- Existing `AuraSpacingTheme` for consistent spacing
- Flutter's Material library for underlying dialog/snackbar implementations

## Out of Scope

- Bottom sheets (not currently used in app)
- Date/time pickers (not currently used in app)
- Tab bars (not currently used in app)
- Navigation components (already covered by existing library)
- Checkbox component (not currently used in app)
- Slider component (not currently used in app)
