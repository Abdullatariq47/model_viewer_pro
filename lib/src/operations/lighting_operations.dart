import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Mixin that adds lighting, shadow, and background control to
/// [ModelViewerProController].
mixin LightingOperations {
  /// The [WebViewController] supplied by the owning controller.
  WebViewController? get webViewController;

  // ── Background ─────────────────────────────────────────────────────────────

  /// Sets the CSS background colour of the viewer element.
  ///
  /// [color] accepts any CSS colour string, e.g. `"#ffffff"` or
  /// `"transparent"`.
  Future<bool> setBackgroundColor(String color) {
    return _setMVStyle('backgroundColor', color);
  }

  // ── Shadow ─────────────────────────────────────────────────────────────────

  /// Shows or hides the ground shadow beneath the model.
  ///
  /// Internally toggles the `disable-shadow` attribute rather than setting
  /// `shadow-intensity` to zero, so the previous intensity is preserved when
  /// re-enabled.
  Future<bool> setGroundVisibility(bool visible) {
    return _runBoolScript('''
      (function() {
        const mv = document.querySelector('model-viewer');
        if (!mv) return false;
        if (${visible ? 'true' : 'false'}) {
          mv.removeAttribute('disable-shadow');
        } else {
          mv.setAttribute('disable-shadow', '');
        }
        return true;
      })();
    ''', 'setGroundVisibility');
  }

  /// Sets the shadow intensity (darkness).
  ///
  /// [value] must be in the range `0.0` (no shadow) – `1.0` (full shadow).
  Future<bool> setShadowIntensity(double value) {
    return _setMVAttribute(
        'shadow-intensity', value.toString(), 'setShadowIntensity');
  }

  /// Sets the shadow blur / softness.
  ///
  /// [value] must be in the range `0.0` (sharp) – `1.0` (very soft).
  Future<bool> setShadowSoftness(double value) {
    return _setMVAttribute(
        'shadow-softness', value.toString(), 'setShadowSoftness');
  }

  // ── Exposure ───────────────────────────────────────────────────────────────

  /// Sets the scene exposure / brightness multiplier.
  ///
  /// Values above `1.0` brighten the scene; values below darken it.
  Future<bool> setExposure(double value) {
    return _setMVAttribute('exposure', value.toString(), 'setExposure');
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  Future<bool> _setMVAttribute(
      String attr, String value, String debugLabel) async {
    if (webViewController == null) return false;
    try {
      final result = await webViewController!.runJavaScriptReturningResult('''
        (function() {
          const mv = document.querySelector('model-viewer');
          if (!mv) return false;
          mv.setAttribute(${jsonEncode(attr)}, ${jsonEncode(value)});
          return true;
        })();
      ''');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return result == 'true' || result == true || result == 1;
    } catch (e) {
      debugPrint('model_viewer_pro: $debugLabel error — $e');
      return false;
    }
  }

  Future<bool> _setMVStyle(String property, String value) async {
    if (webViewController == null) return false;
    try {
      final result = await webViewController!.runJavaScriptReturningResult('''
        (function() {
          const mv = document.querySelector('model-viewer');
          if (!mv) return false;
          mv.style[${jsonEncode(property)}] = ${jsonEncode(value)};
          return true;
        })();
      ''');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return result == 'true' || result == true || result == 1;
    } catch (e) {
      debugPrint('model_viewer_pro: setBackgroundColor error — $e');
      return false;
    }
  }

  Future<bool> _runBoolScript(String script, String debugLabel) async {
    if (webViewController == null) return false;
    try {
      final result =
          await webViewController!.runJavaScriptReturningResult(script);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return result == 'true' || result == true || result == 1;
    } catch (e) {
      debugPrint('model_viewer_pro: $debugLabel error — $e');
      return false;
    }
  }
}
