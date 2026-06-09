# model_viewer_pro

[![pub.dev](https://img.shields.io/pub/v/model_viewer_pro.svg)](https://pub.dev/packages/model_viewer_pro)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Display and control interactive **3D models (GLB / GLTF)** in Flutter with
fine-grained mesh manipulation, camera control, animations, grounded
environments, and custom lighting.

Built on top of [`model_viewer_plus`](https://pub.dev/packages/model_viewer_plus),
this package adds a full Dart API for **runtime scene control** that the base
package does not provide.

---

## The Customization Workflow (How it Works)

This package provides the simplest and most efficient way to create customizable 3D models (like character avatars with interchangeable outfits) directly in Flutter.

To achieve seamless, instant customization, follow this workflow:

1. **Use a Single GLB File with Overlapping Meshes:** Instead of loading multiple separate files, ask your 3D artist to export a single `.glb` file that contains *all* possible variations (e.g., all shirts, pants, and hats) layered on top of each other.
2. **Initialize the Default State:** When the model first loads (using the `onLoad` callback), immediately hide the overlapping meshes and show *only* the necessary default meshes.
3. **Toggle Meshes at Runtime:** As the user interacts with your app's UI, use `controller.setVisibility('MeshName', true/false)` to instantly swap parts. Because all meshes are already loaded into memory, the transition is completely seamless with zero loading delay!

---

## Features

| | |
|---|---|
| 🎨 **Mesh control** | Discover, show/hide, and recolour meshes by name |
| 📷 **Camera** | Orbit, target, FOV, zoom in/out, auto-rotate, reset |
| 🌄 **Environment & Skybox** | Set HDR/equirectangular images from URL or Flutter assets |
| 🌍 **Grounded mode** | Project the skybox onto a ground plane for realistic scenes |
| 💡 **Lighting** | Shadow intensity/softness, exposure, background colour |
| 🎬 **Animations** | Play, pause, seek, get duration |
| 📸 **Screenshot** | Capture the current frame as a PNG data URI |
| ⚡ **Performance** | Batched JS calls, single render-trigger, minimal WebView round-trips |

---

## Installation

```yaml
# pubspec.yaml
dependencies:
  model_viewer_pro: ^2.0.0
```

Then run:
```bash
flutter pub get
```

---

## Quick Start

```dart
import 'package:model_viewer_pro/model_viewer_pro.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _controller = ModelViewerProController();

  @override
  Widget build(BuildContext context) {
    return ModelViewerProViewer(
      src: 'assets/model.glb',
      controller: _controller,
      cameraControls: true,
      autoRotate: true,
      onLoad: (meshes) {
        print('Loaded meshes: $meshes');
      },
    );
  }
}
```

Don't forget to declare your model asset in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/model.glb
```

---

## ModelViewerProViewer — Widget Reference

### Required

| Parameter | Type | Description |
|-----------|------|-------------|
| `src` | `String` | Path or URL to the model file (`.glb` or `.gltf`). |

### Controller & Callbacks

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `controller` | `ModelViewerProController?` | `null` | Controller for runtime mesh, camera, and lighting operations. |
| `onLoad` | `Function(List<String>)?` | `null` | Called once the model loads with discovered mesh names. |
| `initialLoadingMeshes` | `List<String>?` | `null` | Whitelist of meshes to show instantly upon load, hiding all others to prevent visual pop-in. |

### Appearance

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `backgroundColor` | `Color` | `Colors.transparent` | Background colour of the viewer. |
| `shadowIntensity` | `double?` | `null` (`1.0` when grounded) | Shadow darkness. `0.0` = none. |
| `shadowSoftness` | `double?` | `null` | Shadow blur. `0.0` = sharp, `1.0` = soft. |
| `exposure` | `double?` | `null` | Scene brightness. `1.0` = default. |

### Environment & Skybox

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `environmentImageUrl` | `String?` | `null` | URL to HDR/equirectangular image for reflections. |
| `skyboxImagePath` | `String?` | `null` | URL **or asset path** to equirectangular image for 360° background. |
| `grounded` | `bool?` | `null` | Projects skybox onto a ground plane. See [Grounded Mode](#grounded-mode). |
| `skyboxHeight` | `String?` | `null` (`"1.5m"` when grounded) | Height at which the skybox terminates, e.g. `"1.5m"`. |

### Camera

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `cameraOrbit` | `String?` | `null` | Initial camera position, e.g. `"45deg 55deg 2m"`. |
| `cameraTarget` | `String?` | `null` | Look-at point, e.g. `"0m 1m 0m"`. |
| `fieldOfView` | `String?` | `null` | FOV, e.g. `"30deg"`. |
| `minFieldOfView` | `String?` | `null` | Min FOV clamp. |
| `maxFieldOfView` | `String?` | `null` | Max FOV clamp. |
| `maxCameraOrbit` | `String?` | `null` (`"auto 90deg auto"` when grounded) | Max orbit constraint. |
| `minCameraOrbit` | `String?` | `null` | Min orbit constraint. |

### Interaction

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `cameraControls` | `bool` | `true` | Enable camera orbit via drag. |
| `autoRotate` | `bool` | `false` | Continuous auto-rotation. |
| `disablePan` | `bool?` | `null` (`true` when grounded) | Disable two-finger pan / middle-mouse. |
| `disableZoom` | `bool?` | `null` | Disable pinch-zoom / scroll wheel. |
| `disableTap` | `bool?` | `null` | Disable tapping the model. |
| `touchAction` | `String?` | `null` | CSS `touch-action`, e.g. `"pan-y"`. |

### Model Loading

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `ar` | `bool` | `false` | Show the AR button. |
| `autoPlay` | `bool` | `false` | Auto-play embedded animations. |
| `alt` | `String?` | `null` | Accessibility alt text. |
| `poster` | `String?` | `null` | Poster image URL shown while loading. |
| `loading` | `Loading?` | `null` | Loading behavior: `auto`, `lazy`, `eager`. |
| `reveal` | `Reveal?` | `null` | Reveal behavior: `auto`, `interaction`, `manual`. |

---

## Grounded Mode

When `grounded: true` is set, the skybox is projected onto a virtual ground
plane, creating a realistic floor reflection. **A skybox or environment image
is required.**

### Automatic Defaults

When grounded is enabled, these sensible defaults are applied **unless you
explicitly override them**:

| Attribute | Auto value | Override with |
|-----------|-----------|---------------|
| `skybox-projection` | `equirectangular` | *(always applied)* |
| `skybox-height` | `"1.5m"` | `skyboxHeight` param |
| `shadow-intensity` | `1.0` | `shadowIntensity` param |
| `max-camera-orbit` | `"auto 90deg auto"` | `maxCameraOrbit` param |
| `disable-pan` | `true` | `disablePan` param |

If no `skyboxImagePath` is provided but `environmentImageUrl` is set, the
environment image is automatically used as the skybox.

### Example

```dart
ModelViewerProViewer(
  src: 'assets/model.glb',
  controller: controller,
  grounded: true,
  skyboxImagePath: 'assets/park.jpg',
  // All defaults applied automatically — override any you need:
  // skyboxHeight: '2m',
  // maxCameraOrbit: 'auto 120deg auto',
  // disablePan: false,
)
```

---

## ModelViewerProController — Runtime API

Create one instance, pass it to `ModelViewerProViewer`. All methods become active
after the `onLoad` callback fires.

### Scene

| Method | Returns | Description |
|--------|---------|-------------|
| `waitForSceneReady({int timeoutMs})` | `Future<bool>` | Wait for the 3D scene graph to be accessible. |

### Mesh

| Method | Returns | Description |
|--------|---------|-------------|
| `getAvailableMeshes()` | `Future<List<String>>` | All mesh names in the loaded model. |
| `setVisibility(name, visible)` | `Future<void>` | Show/hide a mesh and all its children. |
| `setExclusiveMesh(group, selectedMesh)` | `Future<void>` | Show `selectedMesh` and hide all other meshes in the `group` list. |
| `setTextureColor(name, colorHex)` | `Future<void>` | Change a mesh's base colour (e.g. `"#FF0000"`). |

### Camera

| Method | Returns | Description |
|--------|---------|-------------|
| `setCameraOrbit(theta, phi, radius)` | `Future<void>` | Move camera (degrees/metres). |
| `setCameraTarget(x, y, z)` | `Future<void>` | Set look-at point (metres). |
| `setFieldOfView(fov)` | `Future<void>` | Set FOV (degrees). |
| `getCameraOrbit()` | `Future<Map?>` | Get current orbit values. |
| `resetCamera()` | `Future<void>` | Reset to default position. |
| `zoomIn()` / `zoomOut()` | `Future<void>` | Zoom by ±20%. |
| `setAutoRotate(enabled)` | `Future<void>` | Toggle auto-rotation. |

### Environment & Skybox

| Method | Returns | Description |
|--------|---------|-------------|
| `setEnvironmentImageFromUrl(url)` | `Future<bool>` | Set reflection image from URL. |
| `setEnvironmentImageFromAsset(path)` | `Future<bool>` | Set reflection image from Flutter asset. |
| `setSkyboxImageFromUrl(url)` | `Future<bool>` | Set 360° background from URL. |
| `setSkyboxImageFromAsset(path)` | `Future<bool>` | Set 360° background from Flutter asset. |
| `setSkyboxHeight(height)` | `Future<bool>` | Set skybox termination height. |
| `removeSkyboxHeight()` | `Future<bool>` | Remove skybox height constraint. |

### Lighting

| Method | Returns | Description |
|--------|---------|-------------|
| `setBackgroundColor(color)` | `Future<bool>` | Set CSS background (e.g. `"#000"`). |
| `setGroundVisibility(visible)` | `Future<bool>` | Show/hide ground shadow. |
| `setShadowIntensity(value)` | `Future<bool>` | Shadow darkness (0–1). |
| `setShadowSoftness(value)` | `Future<bool>` | Shadow blur (0–1). |
| `setExposure(value)` | `Future<bool>` | Scene brightness multiplier. |

### Interaction Controls

| Method | Returns | Description |
|--------|---------|-------------|
| `setDisablePan(disabled)` | `Future<bool>` | Enable/disable panning. |
| `setDisableZoom(disabled)` | `Future<bool>` | Enable/disable zooming. |
| `setDisableTap(disabled)` | `Future<bool>` | Enable/disable tap. |
| `setMaxCameraOrbit(orbit)` | `Future<bool>` | Set max orbit constraint. |
| `setMinCameraOrbit(orbit)` | `Future<bool>` | Set min orbit constraint. |
| `setTouchAction(action)` | `Future<bool>` | Set CSS touch-action. |

### Animation

| Method | Returns | Description |
|--------|---------|-------------|
| `playAnimation()` | `Future<void>` | Start playback. |
| `pauseAnimation()` | `Future<void>` | Pause at current position. |
| `setAnimationTime(seconds)` | `Future<void>` | Seek to a specific time. |
| `getAnimationDuration()` | `Future<double?>` | Total animation duration. |

### Asset Loading

| Method | Returns | Description |
|--------|---------|-------------|
| `loadSkyboxFromAsset(path)` | `Future<bool>` | Load skybox from Flutter asset (base64). |
| `loadEnvironmentFromAsset(path)` | `Future<bool>` | Load environment from Flutter asset. |

### Utilities

| Method | Returns | Description |
|--------|---------|-------------|
| `takeScreenshot()` | `Future<String?>` | Capture frame as PNG data URL. |
| `executeCustomJS(script)` | `Future<void>` | Run arbitrary JavaScript. |

---

## Performance Tips

1. **Use URL images when possible** — `skyboxImagePath` and `environmentImageUrl`
   pointing to remote URLs are loaded natively by the WebView and are more
   efficient than base64-encoded assets.
2. **Avoid unnecessary `setState`** — The viewer batches all `didUpdateWidget`
   changes into a single JS call to keep round-trips minimal.
3. **Wait for `onLoad`** — Perform all controller operations inside or after
   the `onLoad` callback to ensure the scene is ready.
4. **Keep models small** — Compress `.glb` files and use Draco compression.
5. **Use `loading: Loading.lazy`** — Defer loading until the viewer is on screen.

---

## Supported Platforms

| Platform | Status |
|----------|--------|
| Android  | ✅ Supported (6.0+) |
| iOS      | ✅ Supported (11.0+) |
| Web      | ✅ Supported (via `<model-viewer>`) |

---

## Architecture & Limitations (Problem Solving)

This package is optimized for **zero-latency outfit swapping** using a single-file architecture (sub-mesh toggling). This is highly desirable for avatars, mini-games, and simple 3D models where you want instant changes without network requests.

However, be aware of the following limitations:
1. **Memory Usage**: The entire wardrobe (all meshes and textures, even hidden ones) is loaded into memory at once. If you have dozens of high-resolution clothing items, you may encounter Out-Of-Memory (OOM) crashes on low-end mobile devices.
2. **Texture Atlasing**: To mitigate memory issues, instruct your 3D artists to use **Texture Atlasing** (combining multiple clothing textures into a single shared image map).
3. **Skeleton Sharing**: All clothing items must share the exact same skeletal rig. Clothing that requires entirely different bone structures (e.g., a flowing cape vs. a tight shirt) might cause animation conflicts or inflate the rig complexity.

If your application requires hundreds of distinct, high-resolution clothing pieces, consider a modular loading approach (loading separate GLB files dynamically) instead of packing everything into one file.

---

## Troubleshooting

- **Black screen or infinite loading**: Ensure your `assets/model.glb` is declared in `pubspec.yaml` and spelled exactly the same (case-sensitive).
- **`WebViewPlatform.instance != null` errors in tests**: Because `model_viewer_pro` relies on native WebViews, headless widget tests (`flutter test`) will fail. You must use the `integration_test` package and run tests on a real device or emulator.
- **Symlink errors on Windows**: If you encounter plugin symlink errors when running the example app, enable **Developer Mode** in your Windows system settings.

---

## Launching & Publishing your App

When preparing your Flutter app for release with this package:
1. **Model Optimization**: Compress your `.glb` files before launch. Use tools like `gltf-pipeline` to apply **Draco compression**. The `model-viewer` web component natively supports Draco decompression.
2. **Web Deployment**: If deploying to Flutter Web, no additional configuration is needed. The package uses an iframe `<model-viewer>` component which handles WebGL natively. Ensure your web server serves `.glb` files with the correct CORS headers if loading from external URLs.
3. **Android Permissions**: Native WebView components require internet access if you are loading remote URLs (for the model or skyboxes). Ensure `<uses-permission android:name="android.permission.INTERNET" />` is in your `AndroidManifest.xml`.
4. **App Size**: Be mindful that large 3D assets bundled locally will drastically increase your `.apk`/`.ipa` size. For production apps, host your `glb` and `hdr` files on a CDN and load them via URL.

---

## Migrating from `model_viewer_pro_controller`

Replace the import:

```dart
// Before
import 'package:model_viewer_pro_controller/model_viewer_pro_controller.dart';

// After
import 'package:model_viewer_pro/model_viewer_pro.dart';
```

Update your `pubspec.yaml`:

```yaml
dependencies:
  # Remove:  model_viewer_pro_controller: ...
  model_viewer_pro: ^1.0.0
```

All class names (`ModelViewerProViewer`, `ModelViewerProController`) and method
signatures remain **identical** — no other code changes required.

---

## License

See [LICENSE](https://github.com/Abdullatariq47/model_viewer_pro/blob/main/LICENSE) for details.