import 'dart:async' show unawaited;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'operations/mesh_operations.dart';
import 'operations/environment_operations.dart';
import 'operations/lighting_operations.dart';
import 'operations/camera_operations.dart';
import 'operations/animation_operations.dart';
import 'operations/asset_loader_operations.dart';

/// Controller for a [ModelViewerProViewer] widget.
///
/// Create a single instance and pass it to the `controller` parameter of
/// [ModelViewerProViewer]. Once the viewer calls [setWebViewController] (done
/// automatically by the widget), all methods become active.
///
/// All feature methods are provided by mixed-in operation classes:
/// - [MeshOperations]         — mesh visibility, colour, and name queries
/// - [EnvironmentOperations]  — environment / skybox images
/// - [LightingOperations]     — shadows, exposure, background colour
/// - [CameraOperations]       — orbit, target, FOV, zoom
/// - [AnimationOperations]    — play, pause, time-seek
/// - [AssetLoaderOperations]  — load Flutter assets into the WebView
///
/// ## Example
/// ```dart
/// final controller = ModelViewerProController();
///
/// ModelViewerProViewer(
///   src: 'assets/model.glb',
///   controller: controller,
///   onLoad: (meshes) async {
///     await controller.setShadowIntensity(0.8);
///   },
/// )
/// ```
class ModelViewerProController
    with
        MeshOperations,
        EnvironmentOperations,
        LightingOperations,
        CameraOperations,
        AnimationOperations,
        AssetLoaderOperations {
  WebViewController? _webViewController;

  /// Required by each mixin so it can access the underlying [WebViewController].
  @override
  WebViewController? get webViewController => _webViewController;

  /// Called automatically by [ModelViewerProViewer] when the WebView is ready.
  ///
  /// You do not need to call this yourself.
  void setWebViewController(WebViewController controller) {
    _webViewController = controller;
  }

  // ── Scene readiness ────────────────────────────────────────────────────────

  /// Waits until the model-viewer scene graph is accessible.
  ///
  /// Polls up to [timeoutMs] milliseconds (default 3 000 ms).
  /// Returns `true` if the scene became ready in time, `false` otherwise.
  Future<bool> waitForSceneReady({int timeoutMs = 3000}) async {
    if (_webViewController == null) return false;
    try {
      final result = await _webViewController!.runJavaScriptReturningResult('''
        (async function() {
          const mv = document.querySelector('model-viewer');
          if (!mv) return false;
          if (mv.loaded && mv.model) return true;
          const start = Date.now();
          return new Promise((resolve) => {
            const poll = setInterval(() => {
              if (mv.loaded && mv.model) {
                clearInterval(poll);
                resolve(true);
              } else if (Date.now() - start > $timeoutMs) {
                clearInterval(poll);
                resolve(false);
              }
            }, 100);
          });
        })()
      ''');
      final clean = result.toString().replaceAll('"', '');
      return clean == 'true' || clean == '1' || result == true || result == 1;
    } catch (e) {
      debugPrint('model_viewer_pro: waitForSceneReady error — $e');
      return false;
    }
  }

  // ── Skybox helpers ─────────────────────────────────────────────────────────

  /// Sets the `skybox-height` attribute on model-viewer.
  ///
  /// Accepts any CSS length value: `"auto"`, `"1.5m"`, `"10ft"`, etc.
  Future<bool> setSkyboxHeight(String height) {
    return _setAttribute('skybox-height', height, requestUpdate: true);
  }

  /// Removes `skybox-height` so the skybox displays as a full 360° sphere.
  Future<bool> removeSkyboxHeight() {
    return _removeAttribute('skybox-height', requestUpdate: true);
  }

  // ── Camera constraints ─────────────────────────────────────────────────────

  /// Sets the `max-camera-orbit` attribute to restrict how far the user can
  /// orbit the camera.
  ///
  /// Example: `"auto 90deg auto"` limits vertical rotation to 90°.
  Future<bool> setMaxCameraOrbit(String orbit) {
    return _setAttribute('max-camera-orbit', orbit);
  }

  /// Sets the `min-camera-orbit` attribute.
  Future<bool> setMinCameraOrbit(String orbit) {
    return _setAttribute('min-camera-orbit', orbit);
  }

  // ── Interaction ────────────────────────────────────────────────────────────

  /// Enables or disables panning (two-finger drag on touch / middle-mouse).
  Future<bool> setDisablePan(bool disabled) {
    return disabled
        ? _setAttribute('disable-pan', '')
        : _removeAttribute('disable-pan');
  }

  /// Enables or disables zooming (pinch on touch / scroll wheel).
  Future<bool> setDisableZoom(bool disabled) {
    return disabled
        ? _setAttribute('disable-zoom', '')
        : _removeAttribute('disable-zoom');
  }

  /// Enables or disables tapping on the model.
  Future<bool> setDisableTap(bool disabled) {
    return disabled
        ? _setAttribute('disable-tap', '')
        : _removeAttribute('disable-tap');
  }

  /// Sets the CSS `touch-action` on the model-viewer element.
  ///
  /// Use `"pan-y"` to allow vertical page scrolling while the viewer handles
  /// horizontal swipes.
  Future<bool> setTouchAction(String action) {
    return _setAttribute('touch-action', action);
  }

  // ── Utilities ──────────────────────────────────────────────────────────────

  /// Captures the current rendered frame as a PNG data URL.
  ///
  /// Returns `null` if the screenshot could not be taken.
  Future<String?> takeScreenshot() async {
    if (_webViewController == null) return null;
    try {
      final result = await _webViewController!.runJavaScriptReturningResult(
          "document.querySelector('model-viewer').toDataURL()");
      return result.toString();
    } catch (e) {
      debugPrint('model_viewer_pro: takeScreenshot error — $e');
      return null;
    }
  }

  /// Runs arbitrary JavaScript against the page hosting the model-viewer.
  ///
  /// Use this for one-off tweaks not covered by the existing API.
  Future<void> executeCustomJS(String script) async {
    unawaited(_webViewController?.runJavaScript(script));
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  Future<bool> _setAttribute(String attr, String value,
      {bool requestUpdate = false}) async {
    if (_webViewController == null) return false;
    try {
      final result = await _webViewController!.runJavaScriptReturningResult('''
        (function() {
          const mv = document.querySelector('model-viewer');
          if (!mv) return false;
          mv.setAttribute(${jsonEncode(attr)}, ${jsonEncode(value)});
          ${requestUpdate ? "if (mv.requestUpdate) mv.requestUpdate();" : ""}
          return true;
        })();
      ''');
      return result == 'true' || result == true || result == 1;
    } catch (e) {
      debugPrint('model_viewer_pro: setAttribute($attr) error — $e');
      return false;
    }
  }

  Future<bool> _removeAttribute(String attr,
      {bool requestUpdate = false}) async {
    if (_webViewController == null) return false;
    try {
      final result = await _webViewController!.runJavaScriptReturningResult('''
        (function() {
          const mv = document.querySelector('model-viewer');
          if (!mv) return false;
          mv.removeAttribute(${jsonEncode(attr)});
          ${requestUpdate ? "if (mv.requestUpdate) mv.requestUpdate();" : ""}
          return true;
        })();
      ''');
      return result == 'true' || result == true || result == 1;
    } catch (e) {
      debugPrint('model_viewer_pro: removeAttribute($attr) error — $e');
      return false;
    }
  }
}
