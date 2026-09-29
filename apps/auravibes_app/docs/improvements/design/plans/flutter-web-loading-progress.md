# Fix: Show progress while Flutter web boots

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/flutter-web-loading-progress
- **Needs new dependency**: none

## Why

The current page contains only Flutter's async bootstrap script, so slow downloads render a blank body.

## Where

`apps/auravibes_app/web/index.html:19-36`

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
</head>
<body>
  <script src="flutter_bootstrap.js" async></script>
```

`apps/auravibes_app/web/flutter_bootstrap.js` does not currently exist, so Flutter generates the default bootstrap file.

## The fix

Link the stylesheet in `<head>`:

```html
<link rel="stylesheet" href="style.css">
```

Replace the body with the article's loader, adding progress semantics:

```html
<body>
  <div
    class="progress-container"
    data-flutter-loader
    data-flutter-progress
    role="progressbar"
    aria-label="AuraVibes"
    aria-valuemin="0"
    aria-valuemax="100"
    aria-valuenow="0"
  >
    <div class="progress-bar" data-flutter-progress-bar></div>
  </div>
  <script src="flutter_bootstrap.js" async></script>
</body>
```

Add `web/style.css` with literal dimensions and the existing web brand color:

```css
html,
body {
  width: 100%;
  height: 100%;
}

body {
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0;
  background: #ffffff;
}

.progress-container {
  width: 120px;
  height: 8px;
  overflow: hidden;
  border-radius: 10px;
  background: #f4f4f5;
}

.progress-bar {
  width: 0;
  height: 100%;
  background: #ad83ff;
  transition: width 400ms ease;
}

@media (prefers-color-scheme: dark) {
  body {
    background: #18181b;
  }

  .progress-container {
    background: #3f3f46;
  }
}

@media (prefers-reduced-motion: reduce) {
  .progress-bar {
    transition: none;
  }
}
```

Add custom `web/flutter_bootstrap.js` with the required Flutter tokens and article milestones:

```javascript
{{flutter_js}}
{{flutter_build_config}}

const progress = document.querySelector('[data-flutter-progress]');
const progressBar = document.querySelector('[data-flutter-progress-bar]');
const setProgress = (value) => {
  progress?.setAttribute('aria-valuenow', String(value));
  if (progressBar) progressBar.style.width = `${value}%`;
};
setProgress(20);
_flutter.loader.load({
  onEntrypointLoaded: async (engineInitializer) => {
    setProgress(50);
    const appRunner = await engineInitializer.initializeEngine();
    setProgress(80);
    await appRunner.runApp();
    document.querySelector('[data-flutter-loader]')?.remove();
  },
});
```

Remove the loader only after `runApp()` resolves.

## Steps

1. Add the HTML loader and stylesheet link.
2. Add the custom bootstrap script verbatim around Flutter's template tokens.
3. Build web and inspect generated bootstrap output.

## Check it

```sh
cd apps/auravibes_app && fvm flutter build web --release --no-pub
```

Serve the build with network throttling. Confirm visible 20/50/80 stages, loader removal after first Flutter frame, keyboard focus on retry, dark mode, and reduced motion.

## Don't touch

- Dart startup sequencing.
- Native splash screens.
- Service worker strategy.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## Attempt log

- 2026-09-28: Loader markup, CSS, and custom bootstrap already exist. The
  Flutter 3.47.5 release build passed after allowing the pinned SDK to update
  its cache; generated bootstrap expanded both Flutter template tokens and
  retained the 20/50/80 milestones. A local browser load reached progress 50
  and removed the loader, but the app then failed before rendering with
  `appFlavor is not initialized` because the plan's build command supplies no
  flavor define. Network throttling, 20/80 visibility, dark mode, and reduced
  motion remain unverified. No Dart startup changes made, per `Don't touch`.

## STOP if

- The selected Flutter version rejects either bootstrap template token; use the generated 3.47.2 bootstrap contract, not documentation for another version.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report build result and throttled-load behavior.
