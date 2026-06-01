import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Mixin that adds mesh querying and manipulation to [ModelViewerProController].
///
/// Provides methods to list mesh names, toggle visibility, and change
/// the colour of individual meshes in a loaded GLB / GLTF model.
mixin MeshOperations {
  /// The [WebViewController] supplied by the owning controller.
  WebViewController? get webViewController;

  // ── Mesh discovery ────────────────────────────────────────────────────────

  /// Returns all named mesh nodes found in the currently loaded model.
  ///
  /// Traverses the Three.js scene graph and collects every `Mesh` node whose
  /// name is not a generic root label (`"Scene"`, `"Root"`, etc.).
  ///
  /// Returns an empty list if the model is not yet loaded or contains no named
  /// meshes.
  Future<List<String>> getAvailableMeshes() async {
    if (webViewController == null) return [];

    try {
      final result = await webViewController!.runJavaScriptReturningResult('''
        (function() {
          try {
            const mv = document.querySelector('model-viewer');
            if (!mv || !mv.loaded) return "[]";

            const sym = Object.getOwnPropertySymbols(mv)
              .find(s => s.description === 'scene');
            if (!sym || !mv[sym]) return "[]";

            const scene = mv[sym];
            const names = [];

            scene.traverse(function(node) {
              if (!node || !node.name || !node.isMesh) return;
              if (node.type === 'Camera' || node.type === 'Light' || node.isBone) return;
              const name = String(node.name).trim();
              if (!name || name === 'Scene' || name === 'Root' || name === 'root') return;
              if (names.indexOf(name) === -1) names.push(name);
            });

            return JSON.stringify(names);
          } catch (e) {
            return "[]";
          }
        })();
      ''');

      final raw = result.toString();
      if (raw.isEmpty || raw == 'null') return [];

      try {
        final decoded = jsonDecode(raw);
        // Some WebView implementations double-encode the return value.
        if (decoded is String) {
          final inner = jsonDecode(decoded);
          return inner is List ? List<String>.from(inner) : <String>[];
        }
        if (decoded is List) return List<String>.from(decoded);
        return <String>[];
      } catch (e) {
        debugPrint('model_viewer_pro: getAvailableMeshes decode error — $e');
        return <String>[];
      }
    } catch (e) {
      debugPrint('model_viewer_pro: getAvailableMeshes error — $e');
      return <String>[];
    }
  }

  // ── Visibility ────────────────────────────────────────────────────────────

  /// Shows or hides the node named [meshName] and all its children.
  ///
  /// [meshName] must exactly match a value returned by [getAvailableMeshes].
  Future<void> setVisibility(String meshName, bool isVisible) async {
    if (webViewController == null) return;

    try {
      final name = meshName.replaceAll('"', '\\"');
      await webViewController!.runJavaScript('''
        (function() {
          const mv = document.querySelector('model-viewer');
          if (!mv || !mv.loaded) return;

          const sym = Object.getOwnPropertySymbols(mv)
            .find(s => s.description === 'scene');
          if (!sym || !mv[sym]) return;

          const scene = mv[sym];
          let found = false;

          const setNodeScale = (node, visible) => {
            if (!node) return;
            if (node.scale) {
              if (node._origScale === undefined) {
                node._origScale = { x: node.scale.x, y: node.scale.y, z: node.scale.z };
              }
              if (visible) {
                node.scale.set(node._origScale.x, node._origScale.y, node._origScale.z);
              } else {
                node.scale.set(0, 0, 0);
              }
            }
          };

          scene.traverse(function(node) {
            if (node.name === "$name") {
              setNodeScale(node, $isVisible);
              node.traverse(function(child) {
                setNodeScale(child, $isVisible);
              });
              found = true;
            }
          });

          if (!found) {
            console.warn('modelViewerPro: setVisibility — node not found: $name');
            return;
          }

          if (scene.updateMatrixWorld) scene.updateMatrixWorld(true);
          if (typeof _modelViewerProForceRender === 'function') {
            _modelViewerProForceRender(mv, scene);
          } else {
            // Inline fallback for camera tweak
            try {
              const orbit = mv.getCameraOrbit();
              if (orbit) {
                const t = orbit.theta * 180 / Math.PI;
                const p = orbit.phi * 180 / Math.PI;
                const r = orbit.radius;
                window._mvTweakToggle = !window._mvTweakToggle;
                const offset = window._mvTweakToggle ? 0.01 : -0.01;
                mv.setAttribute('camera-orbit', `\${t + offset}deg \${p}deg \${r}m`);
              }
            } catch(e) {}
          }

        })();
      ''');

      await Future<void>.delayed(const Duration(milliseconds: 250));
    } catch (e) {
      debugPrint('model_viewer_pro: setVisibility error — $e');
    }
  }

  // ── Colour ────────────────────────────────────────────────────────────────

  /// Changes the base colour of the mesh named [meshName].
  ///
  /// [colorHex] accepts any value that `THREE.Color.set()` understands,
  /// e.g. `"#FF0000"` or `"red"`.
  ///
  /// The material is cloned before modification so other objects sharing the
  /// same material are not affected.
  Future<void> setTextureColor(String meshName, String colorHex) async {
    if (webViewController == null) return;

    try {
      final name = meshName.replaceAll('"', '\\"');
      final color = colorHex.replaceAll('"', '\\"');

      await webViewController!.runJavaScript('''
        (function() {
          const mv = document.querySelector('model-viewer');
          if (!mv || !mv.loaded) return;

          const THREE = window.THREE;
          if (!THREE) {
            console.warn('modelViewerPro: setTextureColor — THREE not available');
            return;
          }

          const sym = Object.getOwnPropertySymbols(mv)
            .find(s => s.description === 'scene');
          if (!sym || !mv[sym]) return;

          const scene = mv[sym];
          const newColor = new THREE.Color("$color");

          scene.traverse(function(node) {
            if (node.name === "$name" && node.isMesh && node.material) {
              if (Array.isArray(node.material)) {
                node.material = node.material.map(m => {
                  const c = m.clone();
                  c.color = newColor;
                  return c;
                });
              } else {
                node.material = node.material.clone();
                node.material.color = newColor;
              }
              node.material.needsUpdate = true;
            }
          });

          if (typeof _modelViewerProForceRender === 'function') {
            _modelViewerProForceRender(mv, scene);
          }
        })();
      ''');

      await Future<void>.delayed(const Duration(milliseconds: 250));
    } catch (e) {
      debugPrint('model_viewer_pro: setTextureColor error — $e');
    }
  }
}
