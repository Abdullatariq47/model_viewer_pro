import 'dart:async' show unawaited;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Mixin that adds camera control to [ModelViewerProController].
///
/// All methods work by setting properties on the `<model-viewer>` element via
/// JavaScript. Orbit angles are accepted as degrees and distances are in
/// metres (model-viewer conventions).
mixin CameraOperations {
  /// The [WebViewController] supplied by the owning controller.
  WebViewController? get webViewController;

  // ── Orbit and target ──────────────────────────────────────────────────────

  /// Moves the camera to the specified orbit position.
  ///
  /// [theta] — horizontal angle in degrees.
  /// [phi]   — vertical angle in degrees.
  /// [radius]— distance from the model's centre in metres.
  ///
  /// ```dart
  /// controller.setCameraOrbit(45, 80, 5);
  /// ```
  Future<void> setCameraOrbit(double theta, double phi, double radius) async {
    unawaited(webViewController?.runJavaScript(
        "document.querySelector('model-viewer').cameraOrbit = "
        "'${theta}deg ${phi}deg ${radius}m';"));
  }

  /// Sets the point in the scene that the camera looks at.
  ///
  /// [x], [y], [z] are world-space coordinates in metres.
  Future<void> setCameraTarget(double x, double y, double z) async {
    unawaited(webViewController?.runJavaScript(
        "document.querySelector('model-viewer').cameraTarget = "
        "'${x}m ${y}m ${z}m';"));
  }

  // ── Field of view ─────────────────────────────────────────────────────────

  /// Sets the camera field of view in degrees.
  ///
  /// Lower values zoom in; higher values zoom out.
  Future<void> setFieldOfView(double fov) async {
    unawaited(webViewController?.runJavaScript(
        "document.querySelector('model-viewer').fieldOfView = '${fov}deg';"));
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  /// Resets the camera to its default position and clears any turntable offset.
  Future<void> resetCamera() async {
    unawaited(webViewController?.runJavaScript('''
      const viewer = document.querySelector('model-viewer');
      if (viewer) {
        viewer.resetTurntableRotation();
        viewer.jumpCameraToGoal();
      }
    '''));
  }

  // ── Zoom ──────────────────────────────────────────────────────────────────

  /// Zooms in by reducing the orbit radius by 20%.
  Future<void> zoomIn() async {
    unawaited(webViewController?.runJavaScript('''
      const viewer = document.querySelector('model-viewer');
      if (viewer) {
        const orbit = viewer.getCameraOrbit();
        viewer.cameraOrbit =
          orbit.theta + 'rad ' + orbit.phi + 'rad ' + (orbit.radius * 0.8) + 'm';
        viewer.jumpCameraToGoal();
      }
    '''));
  }

  /// Zooms out by increasing the orbit radius by 20%.
  Future<void> zoomOut() async {
    unawaited(webViewController?.runJavaScript('''
      const viewer = document.querySelector('model-viewer');
      if (viewer) {
        const orbit = viewer.getCameraOrbit();
        viewer.cameraOrbit =
          orbit.theta + 'rad ' + orbit.phi + 'rad ' + (orbit.radius * 1.2) + 'm';
        viewer.jumpCameraToGoal();
      }
    '''));
  }

  // ── Query ─────────────────────────────────────────────────────────────────

  /// Returns the current camera orbit as a map with keys `theta`, `phi`, and
  /// `radius` (all in SI units from model-viewer: radians / metres).
  ///
  /// Returns `null` if the value could not be retrieved.
  Future<Map<String, dynamic>?> getCameraOrbit() async {
    if (webViewController == null) return null;
    try {
      final result = await webViewController!.runJavaScriptReturningResult(
          "JSON.stringify(document.querySelector('model-viewer').getCameraOrbit())");
      final decoded = jsonDecode(result.toString());
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      debugPrint('model_viewer_pro: getCameraOrbit error — $e');
      return null;
    }
  }

  // ── Auto-rotation ─────────────────────────────────────────────────────────

  /// Enables or disables continuous auto-rotation of the model.
  Future<void> setAutoRotate(bool enabled) async {
    unawaited(webViewController?.runJavaScript('''
      const viewer = document.querySelector('model-viewer');
      if (viewer) viewer.autoRotate = $enabled;
    '''));
  }
}
