import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Mixin that adds environment and skybox image control to [ModelViewerProController].
///
/// **Prefer URL-based methods** ([setEnvironmentImageFromUrl],
/// [setSkyboxImageFromUrl]) for remote images. For local assets, call the
/// asset loader methods ([AssetLoaderOperations.loadEnvironmentFromAsset],
/// [AssetLoaderOperations.loadSkyboxFromAsset]) inside the
/// [ModelViewerProViewer.onLoad] callback — asset paths are only resolvable after
/// the WebView has loaded the model.
mixin EnvironmentOperations {
  /// The [WebViewController] supplied by the owning controller.
  WebViewController? get webViewController;

  // ── Environment image (reflections) ──────────────────────────────────────

  /// Sets the environment image used for reflections from a remote [url].
  ///
  /// Accepts `.hdr`, `.jpg`, or `.png` equirectangular images.
  Future<bool> setEnvironmentImageFromUrl(String url) {
    return _setAttribute('environment-image', url);
  }

  /// Sets the environment image used for reflections from a Flutter asset path.
  ///
  /// [assetPath] must match exactly what is declared in `pubspec.yaml`, e.g.
  /// `"assets/env.hdr"`. Call inside [ModelViewerProViewer.onLoad].
  Future<bool> setEnvironmentImageFromAsset(String assetPath) {
    return _setAttribute('environment-image', assetPath);
  }

  // ── Skybox image (360° background) ────────────────────────────────────────

  /// Sets the 360° skybox background image from a remote [url].
  Future<bool> setSkyboxImageFromUrl(String url) {
    return _setAttribute('skybox-image', url);
  }

  /// Sets the 360° skybox background image from a Flutter asset path.
  ///
  /// Call inside [ModelViewerProViewer.onLoad].
  Future<bool> setSkyboxImageFromAsset(String assetPath) {
    return _setAttribute('skybox-image', assetPath);
  }

  // ── Deprecated aliases ────────────────────────────────────────────────────

  /// Deprecated — use [setEnvironmentImageFromUrl] or
  /// [setEnvironmentImageFromAsset] instead.
  @Deprecated('Use setEnvironmentImageFromUrl or setEnvironmentImageFromAsset.')
  Future<bool> setEnvironmentImage(String url) =>
      setEnvironmentImageFromUrl(url);

  /// Deprecated — use [setSkyboxImageFromUrl] or [setSkyboxImageFromAsset]
  /// instead.
  @Deprecated('Use setSkyboxImageFromUrl or setSkyboxImageFromAsset.')
  Future<bool> setSkyboxImage(String url) => setSkyboxImageFromUrl(url);

  // ── Internal helper ───────────────────────────────────────────────────────

  Future<bool> _setAttribute(String attribute, String value) async {
    if (webViewController == null) return false;
    try {
      final result = await webViewController!.runJavaScriptReturningResult('''
        (function() {
          const mv = document.querySelector('model-viewer');
          if (!mv) return false;
          mv.setAttribute(${jsonEncode(attribute)}, ${jsonEncode(value)});
          if (mv.requestUpdate) mv.requestUpdate();
          return true;
        })();
      ''');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return result == 'true' || result == true || result == 1;
    } catch (e) {
      debugPrint('model_viewer_pro: $attribute set error — $e');
      return false;
    }
  }
}
