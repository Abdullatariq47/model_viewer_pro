/// The JavaScript manager injected into the model-viewer WebView.
///
/// Defines [ModelViewerProManager], a class that wraps a `<model-viewer>` element
/// and exposes APIs for mesh manipulation, environment/skybox changes, and
/// rendering updates. Also exposes [_modelViewerProForceRender], a shared helper
/// used by mesh and visibility operations.
///
/// The global `window.modelViewerPro` instance is created on injection and
/// connected to the model-viewer element via `window.modelViewerProInit()`.
const String jsMeshManager = """
(function() {

// ── Persistent RAF render watcher ──────────────────────────────────────────
// Runs every animation frame but only does work for 800 ms after a
// visibility change.  Each iteration nudges exposure ± 0.001 (imperceptible),
// which fires attributeChangedCallback → scheduleRenderFrame() → model-viewer
// renders that exact frame with the updated scale=0 nodes already applied.
window._mvpRenderDeadline = 0;
window._mvpRenderMV = null;
window._mvpRenderOrigExp = null;
(function _mvpRenderWatcher() {
  requestAnimationFrame(_mvpRenderWatcher);
  const now = Date.now();
  if (now > window._mvpRenderDeadline || !window._mvpRenderMV) return;
  const mv = window._mvpRenderMV;
  try {
    if (window._mvpRenderOrigExp === null)
      window._mvpRenderOrigExp = parseFloat(mv.getAttribute('exposure') || '1') || 1;
    const delta = (Math.floor(now / 100) % 2 === 0) ? 0 : 0.001;
    mv.setAttribute('exposure', String(window._mvpRenderOrigExp + delta));
    if (mv.requestUpdate) mv.requestUpdate();
  } catch(e) {}
})();

/**
 * Forces model-viewer to redraw after a programmatic scene change.
 *
 * Three layered strategies — the watcher above is the primary backstop:
 *   1. window resize event — model-viewer ALWAYS calls scheduleRenderFrame()
 *      on resize regardless of idle state, no isTrusted requirement.
 *   2. cameraOrbit property nudge (0.0001 rad, sub-pixel, invisible) — direct
 *      JS property setter triggers model-viewer's reactive update cycle.
 *   3. autoRotate = true toggle — Lit reactive path → scheduleRenderFrame().
 */
function _modelViewerProForceRender(mv, scene) {
  // Arm the persistent RAF watcher for 800 ms.
  window._mvpRenderDeadline = Date.now() + 800;
  window._mvpRenderMV = mv;
  window._mvpRenderOrigExp = null;  // reset so watcher re-captures fresh value

  // Strategy 1: window resize — unconditionally triggers scheduleRenderFrame().
  try { window.dispatchEvent(new Event('resize')); } catch(e) {}

  // Strategy 2: camera orbit nudge (property setter, not setAttribute).
  try {
    const orbit = mv.getCameraOrbit();
    if (orbit) {
      const tiny = 0.0001;
      mv.cameraOrbit = `\${orbit.theta + tiny}rad \${orbit.phi}rad \${orbit.radius}m`;
      requestAnimationFrame(() => {
        try {
          mv.cameraOrbit = `\${orbit.theta}rad \${orbit.phi}rad \${orbit.radius}m`;
          if (mv.jumpCameraToGoal) mv.jumpCameraToGoal();
        } catch(e) {}
      });
    }
  } catch(e) {}

  // Strategy 3: autoRotate property toggle.
  try {
    const was = mv.autoRotate;
    mv.autoRotate = true;
    setTimeout(() => { try { mv.autoRotate = was; } catch(e) {} }, 100);
  } catch(e) {}

  // Pointer events + requestUpdate as final backstop.
  try {
    mv.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true, clientX: 0, clientY: 0 }));
    mv.dispatchEvent(new PointerEvent('pointerup',   { bubbles: true, clientX: 0, clientY: 0 }));
    if (mv.requestUpdate) mv.requestUpdate();
  } catch(e) {}
}

// Expose globally so Dart-side JS calls in mesh_operations can call it.
window._modelViewerProForceRender = _modelViewerProForceRender;

// ── ModelViewerProManager ──────────────────────────────────────────────────────────

class ModelViewerProManager {
  constructor() {
    this.mv = null;
    this.scene = null;
    this._sceneReady = false;
    this._sceneReadyResolver = null;
    this._sceneReadyPromise = null;
  }

  // Connect the manager to a model-viewer element and start waiting for load.
  setModelViewer(modelViewer) {
    this.mv = modelViewer;
    this.scene = null;
    this._sceneReady = false;
    this._sceneReadyPromise = new Promise((resolve) => {
      this._sceneReadyResolver = resolve;
    });
    this._attachModelViewerEvents();
    if (this.mv && this.mv.loaded) {
      this._markSceneReady();
    }
    this._startPolling();
  }

  // Poll until the model is loaded so we can cache the scene reference.
  _startPolling() {
    let attempts = 0;
    const timer = setInterval(() => {
      attempts++;
      if (this._sceneReady) { clearInterval(timer); return; }
      if (this.mv && this.mv.loaded && this._init()) {
        this._markSceneReady();
        clearInterval(timer);
      }
      if (attempts >= 50) clearInterval(timer);
    }, 100);
  }

  _markSceneReady() {
    if (this._sceneReady || !this._init()) return;
    this._sceneReady = true;
    if (this._sceneReadyResolver) {
      this._sceneReadyResolver(true);
      this._sceneReadyResolver = null;
    }
  }

  _attachModelViewerEvents() {
    if (!this.mv) return;
    const onReady = () => this._markSceneReady();
    this.mv.addEventListener('scene-graph-ready', onReady, { once: true });
    this.mv.addEventListener('load', onReady, { once: true });
  }

  // Locate the Three.js scene inside model-viewer.
  _getModelScene() {
    if (!this.mv) return null;

    // Path 1 — model.scene (model-viewer v3+)
    if (this.mv.model && this.mv.model.scene) return this.mv.model.scene;

    // Path 2 — Symbol property whose description contains 'scene'
    const sym = Object.getOwnPropertySymbols(this.mv)
      .find(s => s.description && s.description.includes('scene'));
    if (sym) {
      const obj = this.mv[sym];
      if (obj && obj.traverse) return obj;
    }

    // Path 3 — model.scenes array
    if (this.mv.model && this.mv.model.scenes && this.mv.model.scenes.length > 0) {
      return this.mv.model.scenes[0];
    }

    // Path 4 — direct scene property
    if (this.mv.scene) return this.mv.scene;

    return null;
  }

  // Cache the scene reference; return false if not yet available.
  _init() {
    if (!this.mv) return false;
    if (this.scene) return true;
    const scene = this._getModelScene();
    if (scene) { this.scene = scene; return true; }
    return false;
  }

  // Return the root object used for scene traversal.
  _getTraversalRoot() {
    if (!this._init()) return null;
    if (this.scene && this.scene.traverse) return this.scene;
    if (this.scene && this.scene.children && this.scene.children[0] &&
        this.scene.children[0].traverse) {
      return this.scene.children[0];
    }
    return null;
  }

  // Find a scene node by exact name.
  _findNodeByName(nodeName) {
    const root = this._getTraversalRoot();
    if (!root) return null;

    const found = root.getObjectByName(nodeName);
    if (found) return found;

    // Manual traverse fallback for older Three.js builds without getObjectByName.
    let result = null;
    try {
      root.traverse((child) => {
        if (!result && child.name === nodeName) result = child;
      });
    } catch (e) {
      console.error('modelViewerPro: _findNodeByName traverse error', e.message);
    }
    return result;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Wait up to [timeoutMs] ms for the scene to become accessible.
  waitForSceneReady(timeoutMs) {
    if (this._sceneReady) return Promise.resolve(true);
    const timeout = Number.isFinite(timeoutMs) ? timeoutMs : 3000;
    return new Promise((resolve) => {
      const start = Date.now();
      const timer = setInterval(() => {
        if (this._sceneReady) { clearInterval(timer); resolve(true); return; }
        if (this._init()) {
          this._markSceneReady();
          clearInterval(timer);
          resolve(true);
          return;
        }
        if (Date.now() - start >= timeout) { clearInterval(timer); resolve(false); }
      }, 100);
    });
  }

  /// Return a JSON array of all named mesh/group names in the scene.
  getMeshNames() {
    const root = this._getTraversalRoot();
    const target = root || this._getModelScene();
    if (!target || !target.traverse) return JSON.stringify([]);

    const names = new Set();
    try {
      target.traverse((child) => {
        if (!child || !child.name) return;
        if (child.type === 'Camera' || child.type === 'Light' || child.isBone) return;
        const name = String(child.name).trim();
        if (!name || name === 'Scene' || name === 'Root' || name === 'root' || name === 'group') return;
        if (root && !(child.isMesh || child.type === 'Group' ||
            child.type === 'Object3D' || child.type === 'Mesh')) return;
        names.add(name);
      });
    } catch (e) {
      console.error('modelViewerPro: getMeshNames error', e);
    }
    return JSON.stringify(Array.from(names));
  }

  /// Show or hide a named node (and all its children).
  /// Show or hide a named node using scale-based hiding.
  /// scale.set(0,0,0) is the most reliable hide technique: no material
  /// clone/upload needed — Three.js simply skips scale=0 nodes during draw.
  setNodeVisibility(nodeName, isVisible) {
    if (!this.mv) { console.warn('modelViewerPro: mv not initialized'); return false; }
    const target = this._findNodeByName(nodeName);
    if (!target) {
      console.warn('modelViewerPro: setNodeVisibility — node not found:', nodeName);
      return false;
    }

    const applyScale = (node) => {
      if (!node || !node.scale) return;
      // Persist original scale on first hide so we can restore it exactly.
      if (node._origScale === undefined) {
        node._origScale = { x: node.scale.x, y: node.scale.y, z: node.scale.z };
      }
      if (isVisible) {
        node.scale.set(node._origScale.x, node._origScale.y, node._origScale.z);
      } else {
        node.scale.set(0, 0, 0);
      }
    };

    applyScale(target);
    target.traverse((child) => applyScale(child));

    // Force model-viewer to render the updated scene.
    if (typeof _modelViewerProForceRender === 'function') {
      _modelViewerProForceRender(this.mv, this.scene);
    }
    return true;
  }

  /// Set environment (reflection) image.
  setEnvironmentImage(url) {
    if (!this.mv || !url || typeof url !== 'string') return false;
    try {
      this.mv.setAttribute('environment-image', url);
      if (this.mv.requestUpdate) this.mv.requestUpdate();
      return true;
    } catch (e) {
      console.error('modelViewerPro: setEnvironmentImage error', e.message || e);
      return false;
    }
  }

  /// Set the skybox background image.
  setSkyboxImage(url) {
    const mv = this.mv || document.querySelector('model-viewer');
    if (!mv || !url || typeof url !== 'string') return false;
    try {
      mv.setAttribute('skybox-image', url);
      if (mv.requestUpdate) mv.requestUpdate();
      return true;
    } catch (e) {
      console.error('modelViewerPro: setSkyboxImage error', e.message || e);
      return false;
    }
  }

  /// Set the CSS background colour of the viewer.
  setBackgroundColor(color) {
    if (!this.mv) return false;
    try {
      this.mv.style.background = color;
      return true;
    } catch (e) {
      console.error('modelViewerPro: setBackgroundColor error', e.message || e);
      return false;
    }
  }

  /// Show or hide the ground shadow.
  setGroundVisibility(visible) {
    if (!this.mv) return false;
    try {
      this.mv.shadowIntensity = visible ? (this.mv.shadowIntensity || 1.0) : 0.0;
      if (this.mv.requestUpdate) this.mv.requestUpdate();
      return true;
    } catch (e) {
      console.error('modelViewerPro: setGroundVisibility error', e.message || e);
      return false;
    }
  }

  /// Set shadow intensity (0–1).
  setShadowIntensity(value) {
    if (!this.mv) return false;
    const v = Number(value);
    if (Number.isNaN(v)) return false;
    try {
      this.mv.setAttribute('shadow-intensity', String(v));
      if (this.mv.requestUpdate) this.mv.requestUpdate();
      return true;
    } catch (e) {
      console.error('modelViewerPro: setShadowIntensity error', e.message || e);
      return false;
    }
  }

  /// Set shadow softness (0–1).
  setShadowSoftness(value) {
    if (!this.mv) return false;
    const v = Number(value);
    if (Number.isNaN(v)) return false;
    try {
      this.mv.setAttribute('shadow-softness', String(v));
      if (this.mv.requestUpdate) this.mv.requestUpdate();
      return true;
    } catch (e) {
      console.error('modelViewerPro: setShadowSoftness error', e.message || e);
      return false;
    }
  }

  /// Set exposure / brightness multiplier.
  setExposure(value) {
    if (!this.mv) return false;
    const v = Number(value);
    if (Number.isNaN(v)) return false;
    try {
      this.mv.setAttribute('exposure', String(v));
      if (this.mv.requestUpdate) this.mv.requestUpdate();
      return true;
    } catch (e) {
      console.error('modelViewerPro: setExposure error', e.message || e);
      return false;
    }
  }

  /// Apply a solid colour to a named mesh (or all of its children).
  setNodeColor(nodeName, colorHex) {
    const target = this._findNodeByName(nodeName);
    if (!target) {
      console.warn('modelViewerPro: setNodeColor — node not found:', nodeName);
      return false;
    }

    const applyColor = (node) => {
      if (!node.material) return;
      if (Array.isArray(node.material)) {
        node.material = node.material.map(m => {
          const c = m.clone();
          c.color.set(colorHex);
          return c;
        });
      } else {
        node.material = node.material.clone();
        node.material.color.set(colorHex);
      }
    };

    applyColor(target);
    target.traverse((child) => { if (child !== target) applyColor(child); });
    target.traverse((node) => {
      if (node.material) node.material.needsUpdate = true;
    });
    _modelViewerProForceRender(this.mv, this.scene);
    return true;
  }
}

// ── Bootstrap ──────────────────────────────────────────────────────────────────

function _tryInitModelViewerPro() {
  const mv = document.querySelector('model-viewer');
  if (!mv) return false;
  if (!window.modelViewerPro) {
    try { window.modelViewerPro = new ModelViewerProManager(); }
    catch (e) { console.error('modelViewerPro: failed to create manager', e); return false; }
  }
  try {
    window.modelViewerPro.setModelViewer(mv);
    return true;
  } catch (e) {
    console.error('modelViewerPro: setModelViewer failed', e);
    return false;
  }
}

if (!window.modelViewerPro) {
  window.modelViewerPro = new ModelViewerProManager();
}

_tryInitModelViewerPro();

// Dart calls this after the model-viewer element appears in the DOM.
window.modelViewerProInit = function() {
  try { return _tryInitModelViewerPro(); }
  catch (e) { console.error('modelViewerPro: modelViewerProInit error', e); return false; }
};

})();
""";
