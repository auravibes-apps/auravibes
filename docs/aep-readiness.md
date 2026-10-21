# AuraVibes Android and desktop readiness

**Reviewed:** 2026-10-10 (America/Bogota)

**Scope:** Android Experience Program (AEP), Googlebook, and higher-tier desktop readiness. Google makes the final enrollment and desktop-label decisions. AEP Guidelines Planner results are preliminary.

Status labels: **met**, **code gap**, **Console task**, **justified exemption**, **deferred**.

## Readiness matrix

| Requirement | Status | Evidence and next action |
| --- | --- | --- |
| Tier 2 form factors | Console task | AEP enrollment requires Tier 2 for phones, tablets, foldables, and XR. Googlebook support is due by 2027-03-01. Confirm the title’s scope and enrollment in Play Console. [AEP form factors](https://developer.android.com/distribute/aep/aep-req-form-factor-support) |
| Tier 1 / desktop label | deferred | Tier 1 and Google’s desktop experience checklist are the documented route toward a higher desktop label; Google assigns the label. Device and full-flow evidence below is incomplete. [Adaptive quality](https://developer.android.com/docs/quality-guidelines/adaptive-app-quality), [desktop experiences](https://developer.android.com/docs/quality-guidelines/adaptive-app-quality/experiences/desktop) |
| Responsive shell | met | The shell switches to desktop at 960 dp. Existing responsive tests cover 599, 600, 768, 959, 960, and 1280 dp. This is breakpoint coverage, not the full AEP device matrix. |
| Workspace, chat, attachment, agent, and service-connection journeys | deferred | Route and feature tests exist, including desktop chat menu layout, keyboard activation, workspace management, and service-connection screens. They do not run every journey at every official size or on a resizable Android desktop device. No concrete layout defect was reproduced in this audit. |
| Scrollbars, pointer hover, and in-app menus | met | `main.dart` wraps routed content in a `Scrollbar`; drawer and menu components have pointer/keyboard tests. Verify behavior on physical desktop hardware. |
| Full desktop keyboard parity, context menus, drag-and-drop, and multi-window | deferred | Existing tests cover selected keyboard actions. No app-level drag target or secondary-click context-menu path was found in the reviewed attachment flow. No Android desktop multi-window session was available. Prioritize gaps during device validation. |
| Media3 audio playback | deferred | AEP requires Media3 for supported audio/video playback. Voice-note preview now uses `just_audio` 0.10.6, whose Android implementation uses Media3; Linux and Windows use `just_audio_media_kit`. However, GenUI 0.10.4 still brings `audioplayers` transitively, whose Android implementation uses `MediaPlayer`. AuraVibes removes GenUI's `AudioPlayer` item from active catalogs in `aura_chat_catalog_adapter.dart`. Confirm AEP accepts this inactive component and dependency; otherwise replace or patch GenUI before enrollment. No `MediaSession` or `MediaLibraryService` is needed for the current attachment-preview flow. [Media3 requirement](https://developer.android.com/distribute/aep/aep-req-media-3), [GenUI 0.10.4](https://pub.dev/packages/genui/versions/0.10.4), [audioplayers_android 5.3.0](https://pub.dev/packages/audioplayers_android/versions/5.3.0), [just_audio](https://pub.dev/packages/just_audio), [just_audio_media_kit](https://pub.dev/packages/just_audio_media_kit) |
| Android Photo Picker | met | Android picker configuration opts into `ImagePickerAndroid.useAndroidPhotoPicker` before app launch. A focused test checks the configuration. Confirm the actual picker intent and cancellation flow on Android devices. [Photo Picker requirement](https://developer.android.com/distribute/aep/aep-req-photo-picker) |
| In-app camera, CameraX, and Night Mode | justified exemption | Chat capture delegates to the platform camera through `image_picker`; no in-app camera preview or Camera1/Camera2 API use was found. The system camera owns capture UI and Night Mode. Android's camera guidance says invoking the existing camera app does not need the app's `CAMERA` permission. Confirm this exemption in Play Console. [Camera API guidance](https://developer.android.com/media/camera/camera-deprecated/camera-api), [CameraX](https://developer.android.com/distribute/aep/aep-req-camera-x), [Night Mode](https://developer.android.com/distribute/aep/aep-req-night-mode) |
| Optional camera and microphone hardware | met | The production `me.auravibes.app` release bundle has no `CAMERA` permission or camera feature; it retains `RECORD_AUDIO` with `android.hardware.microphone` marked `required=false`. AAPT2 reports only `android.hardware.faketouch` as implied. Unit tests cover denied microphone permission and camera cancellation/failure; physical hardware absence remains in the device matrix. [Feature filtering](https://developer.android.com/guide/topics/manifest/uses-feature-element), [AAPT2 badging](https://developer.android.com/develop/adaptive-apps/guides/increase-app-availability) |
| Predictive Back | met | Launcher `MainActivity` sets `android:enableOnBackInvokedCallback="true"`. [Predictive Back](https://developer.android.com/distribute/aep/aep-req-predictive-background) |
| Edge-to-edge | met | App enables edge-to-edge and transparent system bars in `main.dart`. Verify system-bar insets on target Android devices. [Edge-to-edge](https://developer.android.com/distribute/aep/aep-req-edge-to-edge) |
| Compose requirement | met | App remains Flutter; Google’s AEP guidance accepts Flutter as an alternative. No Compose migration is planned. [Compose guidance](https://developer.android.com/distribute/aep/aep-req-jetpack-compose) |
| Phishing-resistant sign-in and Restore Credentials | code gap | Current cloud account sign-in uses email and password. No passkey/accepted SSO flow or Credential Manager Restore Credentials integration was found. Address with auth/backend design; this audit makes no public API or schema change. [Phishing-resistant authentication](https://developer.android.com/distribute/aep/aep-req-phishing-resistant-auth), [Restore Credentials](https://developer.android.com/distribute/aep/aep-req-restore-credentials) |
| Comparable platform release availability | Console task | Check release and feature availability across comparable platforms before enrollment. [Title availability](https://developer.android.com/distribute/aep/aep-req-new-title-availability) |
| AEP stability | Console task | Review trailing 28-day Play Console metrics and minimum sample size. Published limits: reference devices below 1% crash, 2% ANR, and 2% excessive slow frames; devices with at least 4 GB RAM below 2% crash and 3% ANR; at least 1,500 sessions required. [Stability requirements](https://developer.android.com/distribute/aep/aep-req-stability) |
| AI productivity, Play Content Integration, and Android MCP | deferred | Planner results are preliminary. The AI-productivity selection indicates Android MCP applicability; the Notes/Productivity Play Content Integration exemption depends on the final category and Console review. Android MCP enforcement is deferred until the later of 2027-03-01 or three months after self-service registration launches. Recheck timing and applicability before enrollment. [AEP Guidelines Planner](https://developer.android.com/distribute/aep/aep-integration-planner), [Android MCP](https://developer.android.com/distribute/aep/aep-req-android-mcp) |
| Console access and enrollment | Console task | The available account reached developer-account signup, not an existing app’s Play Console. Device catalog, title availability, stability, and enrollment remain unverified. Do not treat local readiness as AEP approval. [AEP enrollment](https://developer.android.com/distribute/aep) |

## Device validation still required

An Android 14 Large Desktop emulator was used to check caption-bar contrast and the wide-window layout after the AEP review; the full AEP reference-size matrix and hardware-absence flows remain untested. Desktop Preview requires Android Studio Canary or a physical Chromebook. Run the following matrix with resizable and multi-window sessions, keyboard navigation and shortcuts, mouse/trackpad, attachment selection/playback, and camera/microphone absent or denied:

| Target | Reference size |
| --- | --- |
| Googlebook | 160 ppi |
| Foldable | 841 × 701 dp |
| 8-inch tablet | 1024 × 640 dp |
| 10.5-inch tablet | 1280 × 800 dp |
| 13-inch Chromebook | 1600 × 900 dp |

Existing tests exercise selected routes at desktop sizes, but not this complete matrix. The baseline responsive-shell golden run had 30 passes and one mismatch: `mobile_599_closed_light.png` (0.36%, 1,960 pixels). The generated diff images were removed after review; treat the mismatch as a known baseline, not an AEP pass.

## Local verification

- Focused picker and attachment-preview tests: passed, 18 tests (`main_test.dart` and `chat_attachment_draft_preview_test.dart`).
- `fvm dart run melos run validate:quick`: passed; analyzer and format check succeeded.
- Production `me.auravibes.app` release bundle: rebuilt after the caption-bar change at `apps/auravibes_app/build/app/outputs/bundle/prodRelease/app-prod-release.aab` (111.1 MB); `bundletool validate` passed. Current universal APK badging reports version `0.0.4` (version code `1`), target SDK `36`, min SDK `24`, ABIs `arm64-v8a`, `armeabi-v7a`, and `x86_64`; no camera permission or required camera/microphone hardware. The merged launcher activity enables Predictive Back.
- Physical Android/Googlebook matrix, camera/microphone-absent behavior, Play Console metrics, catalog, title availability, and enrollment: unavailable in this environment.
