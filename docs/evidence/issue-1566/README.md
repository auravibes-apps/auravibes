# Conversation archive before and after

These genuine Flutter widget-test captures show the same persisted local workspace before and after archiving its conversation. The before image shows the conversation menu with **Archive**, **Export backup**, and **Delete** as separate actions. The after image shows the archived conversation in the archived list, with its title and timestamp intact.

The hosted capture used the production router, workspace session, repositories, and SQLite fixture. The test verified that archiving removes the conversation from the active list, navigates to the archived route, and displays the conversation there. Both images use the same 960 × 1400 viewport, English locale, light theme, renderer, text scale, and fonts. JSON sidecars preserve each capture's route and rendering metadata.

- [Before: active conversation and action menu](before/001-conversation-archive-before.png)
- [After: archived conversation list](after/002-conversation-archive-after.png)
- Hosted capture: [run 41522020768](https://github.com/auravibes-apps/auravibes/actions/runs/41522020768), source head `171ae3a7b5a891f6e1a85a5455cbdb70743253dc`.
- See [provenance.json](provenance.json) for artifact and file hashes.

These widget-test captures do not establish native system typography or assistive-technology behavior.
