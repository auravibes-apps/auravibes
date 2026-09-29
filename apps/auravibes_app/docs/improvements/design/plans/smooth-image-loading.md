# Fix: Fade remote SVG logos in with quiet loading and error states

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/smooth-image-loading
- **Needs new dependency**: none — the article's `image_fade` package accepts raster `ImageProvider`s and cannot decode this app's SVG URLs

## Why

The only direct remote image surface is a provider-logo SVG. It shows a spinner while loading, then pops to the logo; failures render a localized text message, which is visually heavy inside compact rows.

## Where

`apps/auravibes_app/lib/features/models/widgets/model_logo.dart:30-43`

```dart
  Widget build(BuildContext context) {
    final url = 'https://models.dev/logos/$modelId.svg';
    final svgBuilder = this.svgBuilder;
    if (svgBuilder != null) {
      return svgBuilder(context, url);
    }

    return _ModelLogoNetwork(
      url: url,
      color: context.auraColors.onBackground,
      height: height,
      width: width,
      httpClient: httpClient,
    );
```

`apps/auravibes_app/lib/features/models/widgets/model_logo.dart:54-66`

```dart
  }) : picture = SvgPicture.network(
         url,
         width: width,
         height: height,
         placeholderBuilder: (_) => const AuraSpinner(),
         colorFilter: .mode(color, .srcIn),
         errorBuilder: (_, _, _) => const AuraText(
           child: TextLocale(
             LocaleKeys.models_screens_add_provider_search_no_icon,
           ),
         ),
         httpClient: httpClient,
       );
```

## The fix

Keep `SvgPicture.network`, the injected `httpClient`, fixed dimensions, and color filter. `flutter_svg` 2.3.0 already exposes `imageBuilder`, which runs only after that same network SVG has decoded; use it instead of preloading or fetching twice. Replace the visual callbacks with:

```dart
placeholderBuilder: (context) => SizedBox(
  width: width,
  height: height,
  child: ColoredBox(color: context.auraColors.surfaceVariant),
),
imageBuilder: (context, child) => TweenAnimationBuilder<double>(
  tween: Tween(begin: 0.0, end: 1.0),
  duration: TickerMode.valuesOf(context).enabled
      ? context.auraTheme.animation.fast
      : Duration.zero,
  builder: (context, opacity, child) => Opacity(
    opacity: opacity,
    child: child,
  ),
  child: child,
),
errorBuilder: (context, _, _) => SizedBox(
  width: width,
  height: height,
  child: ColoredBox(
    color: context.auraColors.surfaceVariant,
    child: Center(
      child: Semantics(
        label: LocaleKeys.models_screens_add_provider_search_no_icon.tr(
          context: context,
        ),
        child: Icon(
          Icons.broken_image_outlined,
          size: 16,
          color: context.auraColors.onSurfaceVariant,
        ),
      ),
    ),
  ),
),
```

Add the `easy_localization` import for `.tr` and remove the now-unused `TextLocale` import. Preserve test injection through `svgBuilder` and `httpClient`. The article's `image_fade` package remains inappropriate here because it accepts raster `ImageProvider`s, not SVG bytes.

## Steps

1. Add the SVG-safe `placeholderBuilder`, `imageBuilder`, and `errorBuilder` directly to the existing `SvgPicture.network`; do not add state or `image_fade`.
2. Reserve the current logo bounds for all states.
3. Replace spinner/text error UI with quiet placeholder/icon.
4. Add widget tests for loading, success fade, failure icon/semantics, fixed size, and injected builder/client.
5. Test under reduced motion; use `Duration.zero` when animations are disabled by `TickerMode`.

## Check it

```sh
fvm flutter test test/features/models/widgets/model_logo_test.dart --no-pub
fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine
```

## Don't touch

- Model catalog networking.
- URL construction.
- SVG-to-raster conversion.
- Safe image loader policy.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The chosen `flutter_svg` API would require a second network request or bypass the injected `httpClient`. Keep current loading behavior rather than weakening transport controls.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report state tests and confirm one request per logo.

## Attempt log

- 2026-09-28: The SVG-safe placeholder, fade, semantic error icon, injected client, and fixed logo bounds were already present in `model_logo.dart`. The quoted network-constructor excerpt in "Where" no longer matches (`width: width ?? height` and its callbacks differ), so the plan's stale-excerpt STOP condition applies; no source changes made. `fvm flutter test test/features/models/widgets/model_logo_test.dart --no-pub` passed all 7 tests, including exactly one request. App fatal analysis not run for this plan after STOP; latest recorded app analysis is blocked by info-level diagnostics in the separate friendly-error widget and test.
