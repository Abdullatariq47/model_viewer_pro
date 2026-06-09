import 'dart:async' show unawaited;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'controller.dart';
import 'scripts.dart';

/// A widget that renders an interactive 3D model (GLB or GLTF format).
///
/// Wraps `model_viewer_plus` and injects a JavaScript manager that exposes
/// extended functionality (mesh visibility, color changes, grounded
/// environments, etc.) via [ModelViewerProController].
///
/// ## Required parameters
/// - [src] — Path or URL to a `.glb` or `.gltf` model file.
///
/// ## Key optional parameters
/// - [controller] — A [ModelViewerProController] for runtime scene control.
/// - [onLoad] — Callback invoked with discovered mesh names after load.
/// - [grounded] — Projects the skybox onto a ground plane (requires a
///   skybox or environment image).
/// - [skyboxImagePath] — URL or asset path for the 360° background.
/// - [environmentImageUrl] — URL to an HDR image for reflections.
///
/// ## Grounded mode defaults
/// When [grounded] is `true` the following are applied automatically
/// unless you explicitly override them:
/// | Attribute           | Auto value          | Override with        |
/// |---------------------|---------------------|----------------------|
/// | `skybox-projection` | `equirectangular`   | *(always applied)*   |
/// | `skybox-height`     | `"1.5m"`            | [skyboxHeight]       |
/// | `shadow-intensity`  | `1.0`               | [shadowIntensity]    |
/// | `max-camera-orbit`  | `"auto 90deg auto"` | [maxCameraOrbit]     |
/// | `disable-pan`       | `true`              | [disablePan]         |
///
/// ## Example
/// ```dart
/// ModelViewerProViewer(
///   src: 'assets/my_model.glb',
///   controller: _controller,
///   grounded: true,
///   skyboxImagePath: 'assets/park.jpg',
///   shadowIntensity: 1.0,
///   onLoad: (meshes) => print('Loaded: $meshes'),
/// )
/// ```
class ModelViewerProViewer extends StatefulWidget {
  // ── Required ──────────────────────────────────────────────────────────────

  /// Path or URL to the 3D model file (`.glb` or `.gltf`).
  final String src;

  // ── Controller & Callbacks ────────────────────────────────────────────────

  /// Controller for runtime operations (mesh, camera, lighting, etc.).
  final ModelViewerProController? controller;

  /// Called once the model has loaded with a list of available mesh names.
  final void Function(List<String> availableMeshes)? onLoad;

  /// Optional list of mesh names to show initially. All others will be hidden.
  final List<String>? initialLoadingMeshes;

  // ── Appearance ────────────────────────────────────────────────────────────

  /// Background color of the viewer. Defaults to [Colors.transparent].
  final Color backgroundColor;

  /// Shadow intensity beneath the model. `0.0` = no shadow.
  /// Defaults to `1.0` when [grounded] is `true`.
  final double? shadowIntensity;

  /// Shadow blur/softness. `0.0` = sharp, `1.0` = very soft.
  final double? shadowSoftness;

  /// Scene brightness multiplier. `1.0` = default.
  final double? exposure;

  // ── Environment & Skybox ──────────────────────────────────────────────────

  /// URL of an HDR or equirectangular image used for reflections.
  final String? environmentImageUrl;

  /// URL or asset path of an equirectangular image used as the 360° background.
  final String? skyboxImagePath;

  /// When `true`, projects the skybox onto a ground plane for a realistic
  /// floor effect. Requires [skyboxImagePath] or [environmentImageUrl].
  final bool? grounded;

  /// Height at which the skybox terminates when [grounded] is `true`.
  /// Accepts CSS length values: `"auto"`, `"1.5m"`, `"10ft"`, etc.
  /// Defaults to `"1.5m"` when [grounded] is `true`.
  final String? skyboxHeight;

  // ── Camera ────────────────────────────────────────────────────────────────

  /// Initial camera orbit position, e.g. `"45deg 55deg 2m"`.
  final String? cameraOrbit;

  /// The point in 3D space the camera looks at, e.g. `"0m 1m 0m"`.
  final String? cameraTarget;

  /// Field of view in degrees, e.g. `"30deg"`.
  final String? fieldOfView;

  /// Minimum field of view clamp, e.g. `"10deg"`.
  final String? minFieldOfView;

  /// Maximum field of view clamp, e.g. `"90deg"`.
  final String? maxFieldOfView;

  /// Maximum camera orbit angles, e.g. `"auto 90deg auto"`.
  /// Defaults to `"auto 90deg auto"` when [grounded] is `true`.
  final String? maxCameraOrbit;

  /// Minimum camera orbit angles, e.g. `"auto 0deg auto"`.
  final String? minCameraOrbit;

  // ── Interaction ───────────────────────────────────────────────────────────

  /// Enable camera orbit controls (rotate via drag). Defaults to `true`.
  final bool cameraControls;

  /// Enable continuous auto-rotation. Defaults to `false`.
  final bool autoRotate;

  /// Disable panning (two-finger drag / middle-mouse).
  /// Defaults to `true` when [grounded] is `true`.
  final bool? disablePan;

  /// Disable zooming (pinch / scroll wheel).
  final bool? disableZoom;

  /// Disable tapping on the model.
  final bool? disableTap;

  /// CSS `touch-action` attribute, e.g. `"pan-y"`.
  final String? touchAction;

  // ── Model loading ─────────────────────────────────────────────────────────

  /// Whether to show the AR button. Defaults to `false`.
  final bool ar;

  /// Auto-play embedded animations. Defaults to `false`.
  final bool autoPlay;

  /// Accessibility alt text.
  final String? alt;

  /// URL of a poster image shown while loading.
  final String? poster;

  /// Loading behavior: `auto`, `lazy`, or `eager`.
  final Loading? loading;

  /// Reveal behavior: `auto`, `interaction`, or `manual`.
  final Reveal? reveal;

  // ── Deprecated ────────────────────────────────────────────────────────────

  /// Deprecated — use `controller.loadEnvironmentFromAsset()` inside [onLoad].
  @Deprecated('Use controller.loadEnvironmentFromAsset() inside onLoad.')
  final String? environmentImageAsset;

  /// Deprecated — use `controller.loadSkyboxFromAsset()` inside [onLoad].
  @Deprecated('Use controller.loadSkyboxFromAsset() inside onLoad.')
  final String? skyboxImageAsset;

  /// Deprecated — use [environmentImageUrl] instead.
  @Deprecated('Use environmentImageUrl instead.')
  final String? environmentImage;

  /// Deprecated — use [skyboxImagePath] instead.
  @Deprecated('Use skyboxImagePath instead.')
  final String? skyboxImage;

  /// Creates a [ModelViewerProViewer] widget.
  const ModelViewerProViewer({
    super.key,
    required this.src,
    this.controller,
    this.onLoad,
    this.initialLoadingMeshes,
    this.backgroundColor = Colors.transparent,
    this.autoRotate = false,
    this.cameraControls = true,
    this.ar = false,
    this.autoPlay = false,
    this.cameraOrbit,
    this.cameraTarget,
    this.fieldOfView,
    this.minFieldOfView,
    this.maxFieldOfView,
    this.shadowIntensity,
    this.shadowSoftness,
    this.exposure,
    this.alt,
    this.poster,
    this.loading,
    this.reveal,
    this.environmentImageUrl,
    @Deprecated('Use controller.loadEnvironmentFromAsset() inside onLoad.')
    this.environmentImageAsset,
    this.skyboxImagePath,
    @Deprecated('Use controller.loadSkyboxFromAsset() inside onLoad.')
    this.skyboxImageAsset,
    @Deprecated('Use environmentImageUrl instead.') this.environmentImage,
    @Deprecated('Use skyboxImagePath instead.') this.skyboxImage,
    this.disablePan,
    this.touchAction,
    this.maxCameraOrbit,
    this.minCameraOrbit,
    this.grounded,
    this.skyboxHeight,
    this.disableZoom,
    this.disableTap,
  });

  @override
  State<ModelViewerProViewer> createState() => _ModelViewerProViewerState();
}

class _ModelViewerProViewerState extends State<ModelViewerProViewer> {
  late WebViewController _webViewController;
  bool _modelLoaded = false;
  int _meshLoadAttempts = 0;
  bool _curtainVisible = true;

  @override
  void initState() {
    super.initState();
  }

  // ── Effective values ──────────────────────────────────────────────────────
  // When grounded is true these resolve to a sensible default unless the
  // caller has supplied an explicit override.

  String? get _effectiveMaxCameraOrbit =>
      widget.maxCameraOrbit ??
      (widget.grounded == true ? 'auto 90deg auto' : null);

  String? get _effectiveSkyboxHeight =>
      widget.skyboxHeight ?? (widget.grounded == true ? '1.5m' : null);

  double? get _effectiveShadowIntensity =>
      widget.shadowIntensity ?? (widget.grounded == true ? 1.0 : null);

  bool get _effectiveDisablePan =>
      widget.disablePan ?? (widget.grounded == true);

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void didUpdateWidget(ModelViewerProViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_modelLoaded) return;

    // Batch all attribute changes into a single JS call to avoid multiple
    // WebView round-trips.
    final changes = <String>[];

    if (oldWidget.grounded != widget.grounded) {
      if (widget.grounded == true) {
        // Ensure a skybox is present for the floor projection.
        changes.add('''
          if (!mv.getAttribute('skybox-image')) {
            var env = mv.getAttribute('environment-image');
            if (env) mv.setAttribute('skybox-image', env);
          }
        ''');
        changes.add("mv.setAttribute('skybox-projection', 'equirectangular');");
        changes.add(
            "mv.setAttribute('skybox-height', '$_effectiveSkyboxHeight');");
        changes.add(
            "mv.setAttribute('shadow-intensity', '$_effectiveShadowIntensity');");
        changes.add(
            "mv.setAttribute('max-camera-orbit', '$_effectiveMaxCameraOrbit');");
        if (_effectiveDisablePan) {
          changes.add("mv.setAttribute('disable-pan', '');");
        }
      } else {
        changes.add("mv.removeAttribute('skybox-projection');");
        if (widget.skyboxHeight == null) {
          changes.add("mv.removeAttribute('skybox-height');");
        }
        if (widget.shadowIntensity == null) {
          changes.add("mv.setAttribute('shadow-intensity', '0');");
        }
        if (widget.maxCameraOrbit == null) {
          changes.add("mv.removeAttribute('max-camera-orbit');");
        }
        if (widget.disablePan == null || widget.disablePan == false) {
          changes.add("mv.removeAttribute('disable-pan');");
        }
        // ignore: deprecated_member_use_from_same_package
        if ((widget.skyboxImagePath ?? widget.skyboxImage) == null) {
          changes.add("mv.removeAttribute('skybox-image');");
        }
      }
    }

    // Only apply individual prop changes when grounded itself did not toggle
    // (to avoid overwriting what the grounded block just set).
    if (oldWidget.grounded == widget.grounded) {
      if (oldWidget.disablePan != widget.disablePan) {
        changes.add(_effectiveDisablePan
            ? "mv.setAttribute('disable-pan', '');"
            : "mv.removeAttribute('disable-pan');");
      }
      if (oldWidget.maxCameraOrbit != widget.maxCameraOrbit) {
        changes.add(_effectiveMaxCameraOrbit == null
            ? "mv.removeAttribute('max-camera-orbit');"
            : "mv.setAttribute('max-camera-orbit', '$_effectiveMaxCameraOrbit');");
      }
      if (oldWidget.skyboxHeight != widget.skyboxHeight) {
        changes.add(_effectiveSkyboxHeight == null
            ? "mv.removeAttribute('skybox-height');"
            : "mv.setAttribute('skybox-height', '$_effectiveSkyboxHeight');");
      }
    }

    if (oldWidget.disableZoom != widget.disableZoom) {
      changes.add(widget.disableZoom == true
          ? "mv.setAttribute('disable-zoom', '');"
          : "mv.removeAttribute('disable-zoom');");
    }
    if (oldWidget.disableTap != widget.disableTap) {
      changes.add(widget.disableTap == true
          ? "mv.setAttribute('disable-tap', '');"
          : "mv.removeAttribute('disable-tap');");
    }
    if (oldWidget.touchAction != widget.touchAction) {
      changes.add(widget.touchAction == null
          ? "mv.removeAttribute('touch-action');"
          : "mv.setAttribute('touch-action', '${widget.touchAction}');");
    }
    if (oldWidget.minCameraOrbit != widget.minCameraOrbit) {
      changes.add(widget.minCameraOrbit == null
          ? "mv.removeAttribute('min-camera-orbit');"
          : "mv.setAttribute('min-camera-orbit', '${widget.minCameraOrbit}');");
    }

    if (oldWidget.exposure != widget.exposure) {
      changes.add(widget.exposure == null
          ? "mv.removeAttribute('exposure');"
          : "mv.setAttribute('exposure', '${widget.exposure}');");
    }
    if (oldWidget.shadowIntensity != widget.shadowIntensity) {
      changes.add(_effectiveShadowIntensity == null
          ? "mv.removeAttribute('shadow-intensity');"
          : "mv.setAttribute('shadow-intensity', '$_effectiveShadowIntensity');");
    }
    if (oldWidget.shadowSoftness != widget.shadowSoftness) {
      changes.add(widget.shadowSoftness == null
          ? "mv.removeAttribute('shadow-softness');"
          : "mv.setAttribute('shadow-softness', '${widget.shadowSoftness}');");
    }
    if (oldWidget.autoRotate != widget.autoRotate) {
      changes.add(widget.autoRotate
          ? "mv.setAttribute('auto-rotate', '');"
          : "mv.removeAttribute('auto-rotate');");
    }
    if (oldWidget.cameraControls != widget.cameraControls) {
      changes.add(widget.cameraControls
          ? "mv.setAttribute('camera-controls', '');"
          : "mv.removeAttribute('camera-controls');");
    }
    if (oldWidget.cameraOrbit != widget.cameraOrbit) {
      changes.add(widget.cameraOrbit == null
          ? "mv.removeAttribute('camera-orbit');"
          : "mv.setAttribute('camera-orbit', '${widget.cameraOrbit}');");
    }
    if (oldWidget.cameraTarget != widget.cameraTarget) {
      changes.add(widget.cameraTarget == null
          ? "mv.removeAttribute('camera-target');"
          : "mv.setAttribute('camera-target', '${widget.cameraTarget}');");
    }
    if (oldWidget.fieldOfView != widget.fieldOfView) {
      changes.add(widget.fieldOfView == null
          ? "mv.removeAttribute('field-of-view');"
          : "mv.setAttribute('field-of-view', '${widget.fieldOfView}');");
    }

    if (changes.isNotEmpty) {
      unawaited(_webViewController.runJavaScript('''
        (function() {
          var mv = document.querySelector('model-viewer');
          if (!mv) return;
          ${changes.join('\n')}
          if (mv.requestUpdate) mv.requestUpdate();
          if (mv.jumpCameraToGoal) mv.jumpCameraToGoal();
        })();
      '''));
    }
  }

  // ── Asset loading ─────────────────────────────────────────────────────────

  /// Converts a Flutter asset path to a base-64 data URI.
  /// Returns the original value unchanged if it is already a URL or data URI.
  Future<String?> _loadAssetToBase64(String? path) async {
    if (path == null) return null;
    if (path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('data:')) {
      return path;
    }
    try {
      final data = await rootBundle.load(path);
      final bytes = data.buffer.asUint8List();
      final base64String = base64Encode(bytes);
      final ext = path.split('.').last.toLowerCase();
      final String mime;
      switch (ext) {
        case 'png':
          mime = 'image/png';
          break;
        case 'webp':
          mime = 'image/webp';
          break;
        case 'hdr':
          mime = 'image/vnd.radiance';
          break;
        default:
          mime = 'image/jpeg';
      }
      return 'data:$mime;base64,$base64String';
    } catch (e) {
      debugPrint('model_viewer_pro: Failed to load asset $path — $e');
      return null;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Resolve skybox: explicit value > environment fallback when grounded.
    // ignore: deprecated_member_use_from_same_package
    final resolvedSkybox = (widget.skyboxImagePath ?? widget.skyboxImage) ??
        (widget.grounded == true
            // ignore: deprecated_member_use_from_same_package
            ? (widget.environmentImageUrl ?? widget.environmentImage)
            : null);

    // ignore: deprecated_member_use_from_same_package
    final resolvedEnv = widget.environmentImageUrl ?? widget.environmentImage;

    final isSkyboxAsset = resolvedSkybox != null &&
        !resolvedSkybox.startsWith('http') &&
        !resolvedSkybox.startsWith('data:');
    final isEnvAsset = resolvedEnv != null &&
        !resolvedEnv.startsWith('http') &&
        !resolvedEnv.startsWith('data:');

    return Stack(
      fit: StackFit.expand,
      children: [
        ModelViewer(
          src: widget.src,
          backgroundColor: widget.backgroundColor,
          autoRotate: widget.autoRotate,
          cameraControls: widget.cameraControls,
          ar: widget.ar,
          autoPlay: widget.autoPlay,
          cameraOrbit: widget.cameraOrbit,
          cameraTarget: widget.cameraTarget,
          fieldOfView: widget.fieldOfView,
          minFieldOfView: widget.minFieldOfView,
          maxFieldOfView: widget.maxFieldOfView,
          shadowIntensity: _effectiveShadowIntensity,
          shadowSoftness: widget.shadowSoftness,
          exposure: widget.exposure,
          alt: widget.alt,
          poster: widget.poster,
          loading: widget.loading,
          reveal: widget.reveal,
          // Pass null for local assets — injected as base64 after init.
          environmentImage: isEnvAsset ? null : resolvedEnv,
          skyboxImage: isSkyboxAsset ? null : resolvedSkybox,
          debugLogging: false,
          onWebViewCreated: (webController) async {
            _webViewController = webController;
            widget.controller?.setWebViewController(webController);

            // Inject the JS manager (defines ModelViewerProManager + force-render helper).
            await webController.runJavaScript(jsMeshManager);
            await Future<void>.delayed(const Duration(milliseconds: 150));

            // Inject HTML div overlay inside the WebView — covers model-viewer
            // completely so we don't need to mess with its CSS or opacity,
            // avoiding GL_INVALID_FRAMEBUFFER_OPERATION errors.
            if (widget.initialLoadingMeshes != null) {
              final bgHex = '#${widget.backgroundColor.toARGB32().toRadixString(16).substring(2, 8)}';
              await webController.runJavaScript('''
                (function() {
                  var div = document.createElement('div');
                  div.id = 'mvp-html-curtain';
                  div.style.position = 'fixed';
                  div.style.top = '0';
                  div.style.left = '0';
                  div.style.width = '100vw';
                  div.style.height = '100vh';
                  div.style.backgroundColor = '$bgHex';
                  div.style.zIndex = '999999';
                  div.style.transition = 'opacity 0.3s ease';
                  document.body.appendChild(div);
                })();
              ''');
            }

            final initAttrs = <String>[];

            // Encode local assets as base-64 data URIs.
            if (isEnvAsset) {
              final uri = await _loadAssetToBase64(resolvedEnv);
              if (uri != null) {
                initAttrs.add("mv.setAttribute('environment-image', '$uri');");
              }
            }
            if (isSkyboxAsset) {
              final uri = await _loadAssetToBase64(resolvedSkybox);
              if (uri != null) {
                initAttrs.add("mv.setAttribute('skybox-image', '$uri');");
              }
            }

            // Interaction attributes.
            if (_effectiveDisablePan) {
              initAttrs.add("mv.setAttribute('disable-pan', '');");
            }
            if (widget.disableZoom == true) {
              initAttrs.add("mv.setAttribute('disable-zoom', '');");
            }
            if (widget.disableTap == true) {
              initAttrs.add("mv.setAttribute('disable-tap', '');");
            }
            if (widget.touchAction != null) {
              initAttrs
                  .add("mv.setAttribute('touch-action', '${widget.touchAction}');");
            }

            // Camera constraints.
            if (_effectiveMaxCameraOrbit != null) {
              initAttrs.add(
                  "mv.setAttribute('max-camera-orbit', '$_effectiveMaxCameraOrbit');");
            }
            if (widget.minCameraOrbit != null) {
              initAttrs.add(
                  "mv.setAttribute('min-camera-orbit', '${widget.minCameraOrbit}');");
            }

            // Grounded floor projection.
            if (widget.grounded == true) {
              initAttrs.add('''
                if (!mv.getAttribute('skybox-image')) {
                  var env = mv.getAttribute('environment-image');
                  if (env) mv.setAttribute('skybox-image', env);
                }
                if (mv.getAttribute('skybox-image')) {
                  mv.setAttribute('skybox-projection', 'equirectangular');
                  mv.setAttribute('skybox-height', '$_effectiveSkyboxHeight');
                }
              ''');
            } else if (widget.skyboxHeight != null) {
              initAttrs.add(
                  "mv.setAttribute('skybox-height', '${widget.skyboxHeight}');");
            }

            await webController.runJavaScript('''
              (function pollForModelViewer() {
                var mv = document.querySelector('model-viewer');
                if (!mv) { setTimeout(pollForModelViewer, 100); return; }
                ${initAttrs.join('\n')}
                if (mv.requestUpdate) mv.requestUpdate();

                const applyGrounded = () => {
                  ${widget.grounded == true ? '''
                    if (!mv.getAttribute('skybox-image')) {
                      var env = mv.getAttribute('environment-image');
                      if (env) mv.setAttribute('skybox-image', env);
                    }
                    if (mv.getAttribute('skybox-image')) {
                      mv.setAttribute('skybox-projection', 'equirectangular');
                      mv.setAttribute('skybox-height', '$_effectiveSkyboxHeight');
                    }
                    if (mv.requestUpdate) mv.requestUpdate();
                    if (mv.jumpCameraToGoal) mv.jumpCameraToGoal();
                  ''' : ''}
                };

                mv.addEventListener('load', applyGrounded, { once: true });
                if (mv.loaded) applyGrounded();

                if (window.modelViewerProInit) window.modelViewerProInit();
              })();
            ''');

            if (widget.onLoad != null) {
              unawaited(_checkModelLoadedAndGetMeshes());
            }
          },
        ),
        if (_curtainVisible)
          Container(color: widget.backgroundColor),
      ],
    );
  }

  // ── Mesh loader ───────────────────────────────────────────────────────────

  Future<void> _checkModelLoadedAndGetMeshes() async {
    const checkScript = '''
      (function() {
        var mv = document.querySelector('model-viewer');
        return mv ? mv.loaded : false;
      })();
    ''';

    try {
      final result =
          await _webViewController.runJavaScriptReturningResult(checkScript);
      final isLoaded = result.toString().replaceAll('"', '') == 'true';

      if (isLoaded && !_modelLoaded && mounted) {
        _modelLoaded = true;

        unawaited(_webViewController.runJavaScript('''
          if (window.modelViewerProInit) modelViewerProInit();
        '''));

        // Wait for the Three.js scene to become accessible.
        final sceneReady =
            await widget.controller?.waitForSceneReady(timeoutMs: 15000) ??
                false;

        if (!sceneReady && mounted && _meshLoadAttempts < 8) {
          _meshLoadAttempts++;
          _modelLoaded = false;
          await Future<void>.delayed(const Duration(milliseconds: 1500));
          unawaited(_checkModelLoadedAndGetMeshes());
          return;
        }

        // Brief buffer so the scene graph fully settles before traversal.
        await Future<void>.delayed(const Duration(milliseconds: 800));

        // Apply initial mesh visibility filter while the CSS curtain hides model-viewer.
        if (widget.initialLoadingMeshes != null && mounted) {
          final whitelist = jsonEncode(widget.initialLoadingMeshes);
          await _webViewController.runJavaScript('''
            (function() {
              var mv = document.querySelector('model-viewer');
              if (!mv || !mv.loaded) return;

              var scene = null;
              if (mv.model && mv.model.scene) scene = mv.model.scene;
              if (!scene) {
                var syms = Object.getOwnPropertySymbols(mv);
                for (var i = 0; i < syms.length; i++) {
                  if (syms[i].description && syms[i].description.includes('scene')) {
                    var obj = mv[syms[i]];
                    if (obj && obj.traverse) { scene = obj; break; }
                  }
                }
              }
              if (!scene) return;

              // Track which nodes we hid so runtime show works
              if (!window._mvpHiddenNodes) window._mvpHiddenNodes = new Set();

              var whitelist = $whitelist;

              // Pass 1: hide ALL Mesh objects
              scene.traverse(function(child) {
                if (!child || !child.name) return;
                var name = child.name.trim();
                if (!name || name === 'Scene' || name === 'Root' || name === 'root') return;
                if (child.isMesh || child.type === 'Mesh' || child.type === 'SkinnedMesh') {
                  if (child.material) {
                    if (!child.material._isCloned) {
                      if (Array.isArray(child.material)) {
                        child.material = child.material.map(m => { let c = m.clone(); c._isCloned = true; return c; });
                      } else {
                        child.material = child.material.clone();
                        child.material._isCloned = true;
                      }
                    }
                    if (Array.isArray(child.material)) {
                      child.material.forEach(m => {
                        if (m._origOpacity === undefined) {
                          m._origOpacity = m.opacity;
                          m._origTransparent = m.transparent;
                          m._origDepthWrite = m.depthWrite;
                        }
                        m.opacity = 0;
                        m.transparent = true;
                        m.depthWrite = false;
                        m.needsUpdate = true;
                      });
                    } else {
                      if (child.material._origOpacity === undefined) {
                        child.material._origOpacity = child.material.opacity;
                        child.material._origTransparent = child.material.transparent;
                        child.material._origDepthWrite = child.material.depthWrite;
                      }
                      child.material.opacity = 0;
                      child.material.transparent = true;
                      child.material.depthWrite = false;
                      child.material.needsUpdate = true;
                    }
                  }
                  window._mvpHiddenNodes.add(name);
                }
              });

              // Pass 2: show ONLY whitelisted nodes
              scene.traverse(function(child) {
                if (!child || !child.name) return;
                var name = child.name.trim();
                if (whitelist.indexOf(name) !== -1) {
                  const restoreOpacity = (node) => {
                    if ((node.isMesh || node.type === 'Mesh' || node.type === 'SkinnedMesh') && node.material) {
                      if (Array.isArray(node.material)) {
                        node.material.forEach(m => {
                          if (m._origOpacity !== undefined) {
                            m.opacity = m._origOpacity;
                            m.transparent = m._origTransparent;
                            m.depthWrite = m._origDepthWrite !== undefined ? m._origDepthWrite : true;
                            m.needsUpdate = true;
                          }
                        });
                      } else {
                        if (node.material._origOpacity !== undefined) {
                          node.material.opacity = node.material._origOpacity;
                          node.material.transparent = node.material._origTransparent;
                          node.material.depthWrite = node.material._origDepthWrite !== undefined ? node.material._origDepthWrite : true;
                          node.material.needsUpdate = true;
                        }
                      }
                    }
                  };
                  
                  restoreOpacity(child);
                  if (child.traverse) {
                    child.traverse(function(c) { restoreOpacity(c); });
                  }
                  
                  window._mvpHiddenNodes.delete(name);
                }
              });

              // Force a quick re-render
              try { if (mv.requestUpdate) mv.requestUpdate(); } catch(e) {}
              if (typeof window._modelViewerProForceRender === 'function') {
                window._modelViewerProForceRender(mv, scene);
              }

              // Wait for the render pump to paint several frames, then remove curtain
              setTimeout(function() {
                var curtain = document.getElementById('mvp-html-curtain');
                if (curtain) {
                  curtain.style.opacity = '0';
                  setTimeout(function() { curtain.remove(); }, 350);
                }
              }, 600);
            })();
          ''');

          // Wait for the render pump + curtain fade
          await Future<void>.delayed(const Duration(milliseconds: 1000));
        }

        // Drop the curtain — model is ready and filtered.
        if (mounted) setState(() => _curtainVisible = false);

        if (widget.controller != null && mounted) {
          try {
            final meshes = await widget.controller!.getAvailableMeshes();
            if (mounted && widget.onLoad != null) widget.onLoad!(meshes);
          } catch (e) {
            debugPrint('model_viewer_pro: error retrieving meshes — $e');
            if (mounted && widget.onLoad != null) widget.onLoad!(<String>[]);
          }
        }
      } else if (!isLoaded && !_modelLoaded && mounted) {
        _meshLoadAttempts++;
        if (_meshLoadAttempts > 60) {
          debugPrint('model_viewer_pro: model did not load within timeout.');
          if (mounted) widget.onLoad!(<String>[]);
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (mounted) unawaited(_checkModelLoadedAndGetMeshes());
      }
    } catch (e) {
      debugPrint('model_viewer_pro: error checking model load status — $e');
      if (mounted) widget.onLoad!(<String>[]);
    }
  }
}
