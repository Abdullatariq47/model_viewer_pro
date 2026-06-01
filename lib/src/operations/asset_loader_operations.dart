import 'dart:async' show unawaited;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Mixin that helps load Flutter assets into the model-viewer WebView.
///
/// The WebView cannot reach the Flutter asset bundle directly, so these
/// helpers convert asset bytes to base-64 data URIs that model-viewer can
/// use as `environment-image` or `skybox-image` values.
///
/// **Call these methods inside the [ModelViewerProViewer.onLoad] callback**, after
/// the page is fully ready:
///
/// ```dart
/// ModelViewerProViewer(
///   src: 'assets/model.glb',
///   controller: _controller,
///   onLoad: (meshes) async {
///     await _controller.loadSkyboxFromAsset('assets/skybox.hdr');
///   },
/// )
/// ```
mixin AssetLoaderOperations {
  /// The [WebViewController] supplied by the owning controller.
  WebViewController? get webViewController;

  // ── Skybox ──────────────────────────────────────────────────────────────────

  /// Loads a skybox image from [assetPath] and applies it to model-viewer.
  ///
  /// Reads the file from the Flutter asset bundle, encodes it as a base-64
  /// data URI, and injects it into the page via JavaScript.
  ///
  /// Returns `true` on success, `false` if the asset could not be loaded.
  Future<bool> loadSkyboxFromAsset(String assetPath) {
    return _loadAssetAsAttribute(assetPath, 'skybox-image');
  }

  // ── Environment image ────────────────────────────────────────────────────────

  /// Loads an environment / reflection image from [assetPath].
  ///
  /// Same mechanism as [loadSkyboxFromAsset] but targets the
  /// `environment-image` attribute.
  ///
  /// Returns `true` on success, `false` if the asset could not be loaded.
  Future<bool> loadEnvironmentFromAsset(String assetPath) {
    return _loadAssetAsAttribute(assetPath, 'environment-image');
  }

  // ── Internal ─────────────────────────────────────────────────────────────────

  Future<bool> _loadAssetAsAttribute(String assetPath, String attribute) async {
    if (webViewController == null) return false;
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      final base64Str = base64Encode(bytes);
      final mime = _mimeTypeFor(assetPath);
      final dataUri = 'data:$mime;base64,$base64Str';

      final result = await webViewController!.runJavaScriptReturningResult('''
        (function() {
          const mv = document.querySelector('model-viewer');
          if (!mv) return false;
          mv.setAttribute(${jsonEncode(attribute)}, ${jsonEncode(dataUri)});
          if (mv.requestUpdate) mv.requestUpdate();
          return true;
        })();
      ''');

      await Future<void>.delayed(const Duration(milliseconds: 100));
      return result == 'true' || result == true || result == 1;
    } catch (e) {
      debugPrint('model_viewer_pro: loadAsset($assetPath) error — $e');
      return false;
    }
  }

  static String _mimeTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.hdr')) return 'image/vnd.radiance';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'application/octet-stream';
  }

  // Unused in this mixin but kept so subclasses can call unawaited without
  // importing dart:async themselves.
  // ignore: unused_element
  static void _noop() => unawaited(Future<void>.value());
}
