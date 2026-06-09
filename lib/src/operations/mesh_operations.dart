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
            if (window.modelViewerPro) {
              return window.modelViewerPro.getMeshNames();
            }
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

  /// Returns all named mesh nodes with their current visibility state.
  ///
  /// Each entry has `name` (String) and `visible` (bool).
  /// A mesh is considered hidden if its material opacity is 0.
  Future<List<Map<String, dynamic>>> getAvailableMeshesWithState() async {
    if (webViewController == null) return [];

    try {
      final result = await webViewController!.runJavaScriptReturningResult('''
        (function() {
          try {
            var mv = document.querySelector('model-viewer');
            if (!mv || !mv.loaded) return "[]";

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
            if (!scene && mv.scene) scene = mv.scene;
            if (!scene) return "[]";

            var meshes = {};
            scene.traverse(function(node) {
              if (!node || !node.name) return;
              if (node.type === 'Camera' || node.type === 'Light' || node.isBone) return;
              var name = String(node.name).trim();
              if (!name || name === 'Scene' || name === 'Root' || name === 'root' || name === 'group') return;
              if (!(node.isMesh || node.type === 'Group' || node.type === 'Object3D' || node.type === 'Mesh')) return;
              if (meshes[name] !== undefined) return;
              // Determine visibility: check material opacity
              var visible = true;
              const checkOpacity = (m) => {
                if (Array.isArray(m)) {
                  for (var i=0; i<m.length; i++) {
                    if (m[i].opacity === 0) return false;
                  }
                  return true;
                }
                return m.opacity > 0;
              };

              if (node.isMesh && node.material) {
                visible = checkOpacity(node.material);
              } else if (!node.isMesh && node.children) {
                for (var c = 0; c < node.children.length; c++) {
                  if (node.children[c].isMesh && node.children[c].material) {
                    visible = checkOpacity(node.children[c].material);
                    break;
                  }
                }
              }
              meshes[name] = visible;
            });

            var result = [];
            var keys = Object.keys(meshes);
            for (var i = 0; i < keys.length; i++) {
              result.push({ name: keys[i], visible: meshes[keys[i]] });
            }
            return JSON.stringify(result);
          } catch (e) {
            return "[]";
          }
        })();
      ''');

      final raw = result.toString();
      if (raw.isEmpty || raw == 'null') return [];

      try {
        dynamic decoded = jsonDecode(raw);
        if (decoded is String) decoded = jsonDecode(decoded);
        if (decoded is List) {
          final List<Map<String, dynamic>> meshStates = [];
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              meshStates.add({
                'name': item['name']?.toString() ?? '',
                'visible': item['visible'] == true,
              });
            }
          }
          return meshStates;
        }
        return [];
      } catch (e) {
        debugPrint('model_viewer_pro: getAvailableMeshesWithState decode error — $e');
        return [];
      }
    } catch (e) {
      debugPrint('model_viewer_pro: getAvailableMeshesWithState error — $e');
      return [];
    }
  }

  // ── Visibility ────────────────────────────────────────────────────────────

  /// Shows or hides the node named [meshName] and all its children.
  ///
  /// Uses material opacity to hide (opacity=0) and restore to show.
  /// Model-viewer does NOT override material properties, so this persists.
  ///
  /// [meshName] must exactly match a value returned by [getAvailableMeshes].
  Future<void> setVisibility(String meshName, bool isVisible) async {
    if (webViewController == null) return;

    try {
      // Prefer the manager if available
      final name = meshName.replaceAll('"', '\\"');
      await webViewController!.runJavaScript('''
        (function() {
          // Try the manager first
          if (window.modelViewerPro) {
            window.modelViewerPro.setNodeVisibility("$name", $isVisible);
            return;
          }

          // Fallback: direct scene access with material opacity
          const mv = document.querySelector('model-viewer');
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

          var found = false;
          
          const applyOpacity = (node) => {
            if (!node || !node.material) return;
            
            if (!node.material._isCloned) {
              if (Array.isArray(node.material)) {
                node.material = node.material.map(m => { let c = m.clone(); c._isCloned = true; return c; });
              } else {
                node.material = node.material.clone();
                node.material._isCloned = true;
              }
            }

            if (Array.isArray(node.material)) {
              node.material.forEach(m => {
                if ($isVisible) {
                  m.opacity = m._origOpacity !== undefined ? m._origOpacity : 1;
                  m.transparent = m._origTransparent !== undefined ? m._origTransparent : false;
                  m.depthWrite = m._origDepthWrite !== undefined ? m._origDepthWrite : true;
                } else {
                  if (m._origOpacity === undefined) {
                    m._origOpacity = m.opacity;
                    m._origTransparent = m.transparent;
                    m._origDepthWrite = m.depthWrite;
                  }
                  m.opacity = 0;
                  m.transparent = true;
                  m.depthWrite = false;
                }
                m.needsUpdate = true;
              });
            } else {
              if ($isVisible) {
                node.material.opacity = node.material._origOpacity !== undefined ? node.material._origOpacity : 1;
                node.material.transparent = node.material._origTransparent !== undefined ? node.material._origTransparent : false;
                node.material.depthWrite = node.material._origDepthWrite !== undefined ? node.material._origDepthWrite : true;
              } else {
                if (node.material._origOpacity === undefined) {
                  node.material._origOpacity = node.material.opacity;
                  node.material._origTransparent = node.material.transparent;
                  node.material._origDepthWrite = node.material.depthWrite;
                }
                node.material.opacity = 0;
                node.material.transparent = true;
                node.material.depthWrite = false;
              }
              node.material.needsUpdate = true;
            }
          };

          scene.traverse(function(node) {
            if (node.name === "$name") {
              found = true;
              if (node.isMesh) applyOpacity(node);
              if (node.traverse) {
                node.traverse(function(child) {
                  if (child.isMesh) applyOpacity(child);
                });
              }
            }
          });

          if (!found) {
            console.warn('modelViewerPro: setVisibility — node not found: $name');
          }

          // Force re-render immediately — requestUpdate first, then the full
          // multi-strategy forceRender (direct renderer.render + pointer events).
          try { if (mv.requestUpdate) mv.requestUpdate(); } catch(e) {}
          if (typeof window._modelViewerProForceRender === 'function') {
            window._modelViewerProForceRender(mv, scene);
          }
        })();
      ''');

      // Only a tiny yield needed — the JS-side render fires synchronously
      // inside the same WebView frame via direct renderer.render().
      await Future<void>.delayed(const Duration(milliseconds: 50));
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
