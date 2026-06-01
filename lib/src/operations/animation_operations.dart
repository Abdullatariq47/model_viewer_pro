import 'dart:async' show unawaited;
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Mixin that adds animation control to [ModelViewerProController].
///
/// Works with GLB / GLTF files that contain embedded animations.
/// All timing values are in seconds.
mixin AnimationOperations {
  /// The [WebViewController] supplied by the owning controller.
  WebViewController? get webViewController;

  // ── Playback ──────────────────────────────────────────────────────────────

  /// Starts playing the model's animation(s).
  ///
  /// If the model contains multiple animations they play in sequence.
  /// Has no effect if the model has no animations.
  Future<void> playAnimation() async {
    unawaited(webViewController?.runJavaScript('''
      const viewer = document.querySelector('model-viewer');
      if (viewer && viewer.availableAnimations && viewer.availableAnimations.length > 0) {
        viewer.play();
      }
    '''));
  }

  /// Pauses the currently playing animation at its current position.
  ///
  /// Call [playAnimation] to resume.
  Future<void> pauseAnimation() async {
    unawaited(webViewController?.runJavaScript('''
      const viewer = document.querySelector('model-viewer');
      if (viewer) viewer.pause();
    '''));
  }

  // ── Time seeking ──────────────────────────────────────────────────────────

  /// Seeks to [timeInSeconds] in the animation timeline.
  ///
  /// [timeInSeconds] should be between `0` and the value returned by
  /// [getAnimationDuration].
  Future<void> setAnimationTime(double timeInSeconds) async {
    unawaited(webViewController?.runJavaScript('''
      const viewer = document.querySelector('model-viewer');
      if (viewer) viewer.currentTime = $timeInSeconds;
    '''));
  }

  /// Returns the total duration of the currently active animation in seconds.
  ///
  /// Returns `null` if the model has no animations or is not yet loaded.
  Future<double?> getAnimationDuration() async {
    if (webViewController == null) return null;
    try {
      final result = await webViewController!.runJavaScriptReturningResult('''
        (function() {
          const viewer = document.querySelector('model-viewer');
          return viewer ? viewer.duration : 0;
        })()
      ''');
      return double.tryParse(result.toString());
    } catch (e) {
      debugPrint('model_viewer_pro: getAnimationDuration error — $e');
      return null;
    }
  }
}
