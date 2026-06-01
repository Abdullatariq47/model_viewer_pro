# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.1] — 2026-06-01

### 🛠 Fixes & Improvements
- Updated `LICENSE` file to use a standard MIT License, resolving pub.dev upload warnings.
- Fixed `LICENSE` link in `README.md` to use an absolute GitHub URL for universal compatibility across IDE markdown renderers.
- Updated `example` application test configurations to include `flutter_test` dependency.
- Fixed all `dart analyze` warnings (`activeColor` deprecation, `_visibilityMap` type hint) for a perfect 140/140 Pub points score.

## [1.0.0] — 2026-04-15

### 🚀 Breaking Changes
- **Package renamed** from `model_viewer_pro_controller` to `model_viewer_pro`.
  Update your import to `package:model_viewer_pro/model_viewer_pro.dart`.
  All class and method names are unchanged.

### ✨ New Features
- **Grounded mode** (`ModelViewerProViewer.grounded`) — projects the skybox onto a
  virtual ground plane for a realistic floor reflection, with smart automatic
  defaults for shadow intensity, camera orbit limits, and panning.
- **Local asset skybox** (`skyboxImagePath`) — load equirectangular images
  directly from the Flutter asset bundle (auto-encoded to base64 for WebView
  compatibility).
- **Lighting controls** — `shadowIntensity`, `shadowSoftness`, and `exposure`
  are now first-class constructor parameters on `ModelViewerProViewer`, watching for
  changes via `didUpdateWidget`.
- **Interaction toggles** — `disablePan`, `disableZoom`, `disableTap`,
  `touchAction`, `maxCameraOrbit`, and `minCameraOrbit` are all widget
  parameters with live `didUpdateWidget` support.
- **`AssetLoaderOperations`** mixin — `loadSkyboxFromAsset()` and
  `loadEnvironmentFromAsset()` encode any Flutter asset as a base64 data URI
  and inject it into the WebView for reliable cross-platform asset loading.
- **`setDisablePan` / `setDisableZoom` / `setDisableTap`** methods on
  `ModelViewerProController`.
- **`setSkyboxHeight` / `removeSkyboxHeight`** methods on
  `ModelViewerProController`.
- **`setTouchAction`** method on `ModelViewerProController`.
- **`executeCustomJS`** — run arbitrary JavaScript for one-off scene tweaks.
- **`takeScreenshot`** — capture the current frame as a PNG data URL.
- **Shared `_modelViewerProForceRender` JS helper** — all scene mutations now use a
  single, centralised render-trigger function (camera micro-move + autoRotate
  toggle + material `needsUpdate` flag) instead of duplicated inline code.

### 🛠 Improvements
- All Dart source files re-formatted to pass `dart format` with zero issues.
- Removed leftover `console.log` debug statements from injected JavaScript.
- Fixed `if`-without-braces lint warnings throughout `viewer.dart`.
- `_encodeBase64` in `AssetLoaderOperations` replaced with `dart:convert`'s
  `base64Encode` for correctness and performance.
- `debugPrint` prefix updated from `model_viewer_pro_controller:` to `model_viewer_pro:`.
- `controller.dart` internal helpers (`_setAttribute` / `_removeAttribute`)
  now return `Future<bool>` directly without unnecessary async wrapping.

### ⚠️ Deprecations
- `environmentImageAsset` widget param → use
  `controller.loadEnvironmentFromAsset()` inside `onLoad`.
- `skyboxImageAsset` widget param → use `controller.loadSkyboxFromAsset()`
  inside `onLoad`.
- `environmentImage` widget param → use `environmentImageUrl`.
- `skyboxImage` widget param → use `skyboxImagePath`.
- `setEnvironmentImage()` on controller → use `setEnvironmentImageFromUrl()`.
- `setSkyboxImage()` on controller → use `setSkyboxImageFromUrl()`.

### 📦 Dependencies
- `model_viewer_plus: ^1.10.0`
- `webview_flutter: ^4.13.1`

---

## [0.0.1] — 2026-02-21

### Initial Release

#### 🎭 Mesh Operations
- `getAvailableMeshes()` — query all named meshes from loaded models.
- `setVisibility()` — show/hide individual meshes and their children.
- `setTextureColor()` — change mesh material colours dynamically.

#### 📸 Camera Operations
- Camera orbit, target, FOV, min/max orbit constraints, disable-pan.

#### 🎬 Animation Operations
- Play, pause, seek, and query animation duration.

#### 💡 Lighting Operations
- Background colour, ground visibility, shadow intensity/softness, exposure.

#### 🌅 Environment Operations
- Environment images and skybox images from URL or Flutter assets.

#### 🎮 Viewer Widget
- `ModelViewerProViewer` with `controller`, `onLoad`, and model-viewer passthrough props.

#### 📦 Platform Support
- Android 6.0+, iOS 11.0+, Web (all modern browsers).

---

## [Unreleased]

### Planned
- Morph target / blend-shape control
- Named animation clip selection
- Material property editor (metalness, roughness, emissive)
- VR / immersive mode support
