# Markdown Editor Interactions Design

**Date:** 2026-09-29

**Live issue state checked:** 2026-09-29T11:58:27-05:00

## Intent

Improve the existing full-screen Markdown editor so users can manage nested lists, edit existing links, toggle inline formatting, and preview unsaved Markdown without losing their source draft or selection. Scope comes from open issues #1162–1165. All four follow merged #1146; no dependencies exist among this group.

## Existing flow

`features/markdown` owns the editor screen, text formatter, preview renderer, link dialog, and toolbar. Agent and Skill forms open the editor through `MarkdownEditorLauncher`; saving returns the Markdown draft, while cancellation discards it. `MarkdownPreviewField` already renders Markdown with `GptMarkdown`. The editor controller and toolbar already preserve selections and provide toolbar undo/redo.

## Design

Keep behavior in the existing feature. Add no dependency, shared-package API, or caller changes.

- **List indentation (#1162):** Tab and Shift+Tab act on list items. Indent one level with two spaces; collapsed selection applies to the current item and its deeper list descendants, while a range applies to its selected list lines and their descendants. Preserve markers and selection. Renumber touched ordered-list groups independently by indentation. Shift+Tab removes one level from an empty nested item; an empty root item stays unchanged. Existing Enter behavior continues to exit an empty root item.
- **Link editing (#1163):** Find a single Markdown link that contains the caret or intersects the selection. Prefill its label and destination. Confirm replaces only that link; cancel preserves editor text and selection. If a selection ambiguously spans multiple links, retain current insertion behavior.
- **Inline format toggles (#1165):** Bold, italic, and inline-code actions remove matching markers only when they surround the complete selected text (or the selection contains the complete marked span). Partial selections inside marked text remain unchanged; unformatted selections keep the current wrapping behavior. Multiline code keeps current fenced-code behavior.
- **Preview (#1164):** Add a localized source/preview toggle to the full-screen editor. Preview renders the latest controller text with `GptMarkdown`. Switching views does not save, discard, or edit the draft. Returning to source restores its controller selection and focus. Expose the toggle as an accessible button with its current state.

## View flow

- **Source:** User starts from an Agent or Skill Markdown field. The view shows editable source, existing formatting toolbar, list keyboard behavior, and Save/Cancel actions. The visible result is the controller draft.
- **Preview:** User switches from source to see the current unsaved draft rendered. Save and Cancel retain their existing behavior. The source selection remains in the controller.
- **Return:** Switching back restores the source text and caret/selection, so editing can continue.

Empty draft renders as an empty preview. Rendering has no new asynchronous or error state. Existing unsaved-change confirmation remains the recovery path for system back.

## Verification

Add focused formatter, toolbar, and screen tests for each issue's acceptance criteria, including selection and undo/redo. Add source/preview strings in English and Spanish and generate `LocaleKeys`. Run focused Markdown tests, the app fatal analyzer, then the repository validation and PR dependency/import gates.

## Assumptions

- Two spaces define one newly inserted indentation level; an existing tab prefix counts as one level when outdenting.
- An ambiguous selection containing multiple Markdown links is not edited as a specific link.
- A partial selection inside a matching inline-format span is a no-op; users can select the full span to remove its markers.
