# Scoped verification settings visual evidence

These are hosted Flutter widget-test captures of the production workspace settings route before and after adding scoped verification settings. The baseline is current main (`6137bbf`); the feature capture is PR #1784 at `797a3ca2`. Both show the same persisted in-memory fixture, route, viewport, locale, theme, text scale, renderer, and registered fonts. JSON sidecars describe each capture.

- **Before:** agent lifecycle hooks are available; scoped verification settings are absent.
- **After:** a scoped verification section appears between conversation compaction and agent lifecycle hooks. It is off by default and its configuration remains collapsed.

See [capture-manifest.json](capture-manifest.json) and the sidecars for source fingerprints, fixture description, dimensions, and font hashes. `before-fixtures.sha256` and `after-fixtures.sha256` confirm that the same capture harness and fixture were used on both revisions. These Flutter widget-test images do not establish native typography, keyboard, or assistive-technology behavior.
