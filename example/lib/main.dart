import 'package:flutter/material.dart';
import 'package:model_viewer_pro/model_viewer_pro.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Flutter 3D — Demo',
    home: DemoScreen(),
  ));
}

/// Interactive demo for the [model_viewer_pro] package.
///
/// Demonstrates:
/// - Loading a GLB model from a Flutter asset
/// - Grounded mode with a local skybox image
/// - Runtime lighting controls (exposure, shadow intensity, shadow softness)
/// - Mesh discovery, visibility toggling, and colour changes
class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  final ModelViewerProController _controller = ModelViewerProController();

  List<String> _availableMeshes = [];
  final Map<String, bool> _visibilityMap = {};
  bool _isLoading = true;
  bool _isGrounded = true;
  double _exposure = 0.5;
  double _shadowIntensity = 1.0;
  double _shadowSoftness = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Flutter 3D — Demo'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── 3D Viewer ──────────────────────────────────────────────────────
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.44,
            child: Stack(
              children: [
                Container(
                  color: Colors.grey[200],
                  child: ModelViewerProViewer(
                    src: 'assets/man.glb',
                    controller: _controller,
                    // Local asset skybox loaded via base-64 injection.
                    // skyboxImagePath: 'assets/park.jpg',
                    // Grounded mode — projects skybox onto a ground plane.
                    grounded: _isGrounded,
                    exposure: _exposure,
                    shadowIntensity: _shadowIntensity,
                    shadowSoftness: _shadowSoftness,
                    autoRotate: false,
                    cameraControls: true,
                    backgroundColor: const Color.fromARGB(255, 0, 0, 0)!,
                    onLoad: (List<String> meshes) {
                      setState(() {
                        // Prepend a virtual 'WholeModel' target for bulk ops.
                        _availableMeshes = ['WholeModel', ...meshes];
                        _isLoading = false;
                        for (final name in _availableMeshes) {
                          _visibilityMap[name] = true;
                        }
                      });
                    },
                  ),
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black38,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Loading 3D model…',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Controls ────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _buildLightingCard(),
                  const SizedBox(height: 8),
                  _buildGroundedCard(),
                  const SizedBox(height: 8),
                  if (_availableMeshes.isNotEmpty)
                    _buildMeshCard()
                  else if (!_isLoading)
                    _buildRetryCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Lighting card ──────────────────────────────────────────────────────────

  Widget _buildLightingCard() {
    return _Card(
      title: 'Lighting',
      color: Colors.deepPurple.shade50,
      borderColor: Colors.deepPurple.shade200,
      child: Column(
        children: [
          _Slider(
            label: 'Exposure',
            value: _exposure,
            min: 0.1,
            max: 3.0,
            onChanged: (v) => setState(() => _exposure = v),
          ),
          _Slider(
            label: 'Shadow intensity',
            value: _shadowIntensity,
            min: 0.0,
            max: 1.0,
            onChanged: (v) => setState(() => _shadowIntensity = v),
          ),
          _Slider(
            label: 'Shadow softness',
            value: _shadowSoftness,
            min: 0.0,
            max: 1.0,
            onChanged: (v) => setState(() => _shadowSoftness = v),
          ),
        ],
      ),
    );
  }

  // ── Grounded toggle card ───────────────────────────────────────────────────

  Widget _buildGroundedCard() {
    return _Card(
      title: 'Grounded mode',
      color: Colors.amber.shade50,
      borderColor: Colors.amber.shade200,
      child: SwitchListTile(
        title: Text(
          _isGrounded ? 'Enabled' : 'Disabled',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _isGrounded
              ? 'Skybox projected on ground, pan locked, orbit ≤90°'
              : 'Free orbit, full skybox sphere',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        value: _isGrounded,
        activeThumbColor: Colors.amber[700],
        onChanged: (v) => setState(() => _isGrounded = v),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  // ── Mesh list card ────────────────────────────────────────────────────────

  Widget _buildMeshCard() {
    return _Card(
      title: 'Meshes (${_availableMeshes.length})',
      color: Colors.cyan.shade50,
      borderColor: Colors.cyan.shade200,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _availableMeshes.length,
          itemBuilder: (context, index) {
            final name = _availableMeshes[index];
            final visible = _visibilityMap[name] ?? true;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(name, style: const TextStyle(fontSize: 12)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Visibility toggle
                  IconButton(
                    icon: Icon(
                      visible ? Icons.visibility : Icons.visibility_off,
                      color: visible ? Colors.deepPurple : Colors.grey,
                      size: 18,
                    ),
                    onPressed: () => _toggleVisibility(name, !visible),
                  ),
                  // Apply red colour
                  IconButton(
                    icon: const Icon(Icons.circle, color: Colors.red, size: 18),
                    tooltip: 'Red',
                    onPressed: () => _applyColor(name, '#FF0000'),
                  ),
                  // Apply green colour
                  IconButton(
                    icon:
                        const Icon(Icons.circle, color: Colors.green, size: 18),
                    tooltip: 'Green',
                    onPressed: () => _applyColor(name, '#00C853'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Retry card ────────────────────────────────────────────────────────────

  Widget _buildRetryCard() {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.refresh),
        label: const Text('Retry loading meshes'),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
        onPressed: () async {
          setState(() => _isLoading = true);
          await _controller.waitForSceneReady(timeoutMs: 5000);
          await Future.delayed(const Duration(milliseconds: 500));
          final meshes = await _controller.getAvailableMeshes();
          setState(() {
            _availableMeshes = ['WholeModel', ...meshes];
            for (final m in _availableMeshes) {
              _visibilityMap[m] = true;
            }
            _isLoading = false;
          });
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _toggleVisibility(String name, bool visible) {
    setState(() => _visibilityMap[name] = visible);
    if (name == 'WholeModel') {
      for (final m in _availableMeshes) {
        if (m != 'WholeModel') {
          setState(() => _visibilityMap[m] = visible);
          _controller.setVisibility(m, visible);
        }
      }
    } else {
      _controller.setVisibility(name, visible);
    }
  }

  void _applyColor(String name, String hex) {
    if (name == 'WholeModel') {
      for (final m in _availableMeshes) {
        if (m != 'WholeModel') _controller.setTextureColor(m, hex);
      }
    } else {
      _controller.setTextureColor(name, hex);
    }
  }
}

// ── Re-usable UI components ───────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.child,
    required this.color,
    required this.borderColor,
  });

  final String title;
  final Widget child;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _Slider extends StatelessWidget {
  const _Slider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            activeColor: Colors.deepPurple,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            value.toStringAsFixed(2),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
