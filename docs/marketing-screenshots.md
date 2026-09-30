# Marketing screenshots

Generate the bilingual store and website screenshot matrix from the repository
root:

```sh
fvm dart run melos bootstrap
fvm dart run tool/generate_marketing_screenshots.dart
```

The generator renders production Flutter routes with fictional fixture data from
`apps/auravibes_app/test/marketing_screenshots/`. It makes no Notion requests or
writes. The output is recreated at `build/marketing_screenshots/` on every run.

The matrix contains 52 raw app captures, 52 captures with `device_preview`
frames, 16 detail crops for approval and model scenes, and 40 store JPEGs. Store
scenes cover the finished result, approval, workspaces, agent, and model picker
in English and Spanish on iPhone, iPad, Android phone, and Android tablet
canvases. Website-only scenes use the iPhone preset.

To copy the localized, framed iPhone images to a checked-out website, pass its
root path:

```sh
fvm dart run tool/generate_marketing_screenshots.dart \
  --web-root /path/to/auravibes_web
```

The website mapping is kept in `tool/generate_marketing_screenshots.dart` and
must match the shot IDs in the website's `src/lib/shots.ts`. This copies PNGs to
`public/shots/{en,es}`; website build and publishing remain separate steps.

The Codemagic `marketing-screenshots` workflow runs the same generator without
`--web-root` and publishes `build/marketing_screenshots/**` as downloadable
artifacts.
