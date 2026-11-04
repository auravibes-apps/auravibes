# Workspace setup preflight visual evidence

These hosted Flutter widget-test captures compare the production workspace
settings route on the PR base with the workspace setup preflight route on the
feature head. Both use the same persisted in-memory fixture, viewport, locale,
theme, text scale, renderer, and registered fonts. JSON sidecars record each
route and source revision.

- **Before:** [Workspace settings](before/WorkspaceSettingsRoute-466x678-en-1.0.png)
- **After:** [Workspace setup preflight](after/WorkspaceSetupPreflightRoute-466x678-en-1.0.png)

The captures are from hosted workflow run
[41749343077](https://github.com/auravibes-apps/auravibes/actions/runs/41749343077),
artifact `13284569165`. See [capture-manifest.json](capture-manifest.json) for
the source SHAs and checksums. These widget-test images do not establish native
typography, keyboard, or assistive-technology behavior.
