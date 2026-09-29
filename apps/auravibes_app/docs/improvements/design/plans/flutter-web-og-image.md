# Fix: Add share-card metadata to Flutter web

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/flutter-web-og-image
- **Needs new dependency**: none

## Why

The web document has a placeholder description and no Open Graph or Twitter Card fields.

## Where

`apps/auravibes_app/web/index.html:19-33`

```html
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="A new Flutter project.">

  <!-- iOS meta tags & icons -->
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="auravibes">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">

  <!-- Favicon -->
  <link rel="icon" type="image/png" href="favicon.png"/>

  <title>auravibes</title>
  <link rel="manifest" href="manifest.json">
```

`apps/auravibes_app/web/` currently contains icons, favicon, manifest, and `index.html`; it has no 1200×630 social image.

## The fix

Add matching values for:

```html
<meta property="og:type" content="website">
<meta property="og:title" content="AuraVibes">
<meta property="og:description" content="AI conversations, agents, tools, and workspaces in one cross-platform app.">
<meta property="og:url" content="https://auravibes.me/">
<meta property="og:image" content="https://auravibes.me/og-image.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="AuraVibes">
<meta name="twitter:description" content="AI conversations, agents, tools, and workspaces in one cross-platform app.">
<meta name="twitter:image" content="https://auravibes.me/og-image.png">
```

Also replace the placeholder standard description. Use absolute HTTPS URLs; crawlers do not execute Flutter and cannot infer route-specific metadata.

## Steps

1. Confirm the production Flutter-web origin/path and approved short description.
2. Create/export a static `web/og-image.png` at exactly 1200×630 with readable safe-area content.
3. Add Open Graph and Twitter tags to `index.html`.
4. Build and serve the web output publicly or through a reachable preview.
5. Validate the raw HTML and image URL with at least one Open Graph validator and one Twitter/X-compatible validator.

## Check it

```sh
cd apps/auravibes_app && fvm flutter build web --release --no-pub
```

Then inspect `build/web/index.html` and request the absolute image URL directly. Both must return HTTP 200 without authentication.

## Don't touch

- Dynamic per-route SEO rendering.
- Flutter routing.
- Existing launcher icons.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- Production web origin/path or final card artwork is not approved. Do not invent a deploy URL or publish placeholder art.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report the confirmed absolute URL, image dimensions, build result, and validator results.

## Attempt log

### 2026-09-28 — blocked on production branding inputs

- Confirmed `web/index.html` still has the placeholder description and no Open Graph or Twitter Card metadata.
- Searched web assets for a social/share-card image and found none. The repository contains no approved production origin or final card artwork.
- Stopped before inventing an absolute URL, description, or placeholder image, as required by the plan.
- Status: requires the approved production origin/path, short description, and 1200×630 artwork.
