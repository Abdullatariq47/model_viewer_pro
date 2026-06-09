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

// Meshes that are shown by default on first load.
const List<String> _kInitialMeshes = [
  'dress_whole',
  'sleeves_p',
  'edging_square',
  'band_2b',
];

const List<String> grop1 = [
  'spread_2b',
  'point_2b',
  'band_2b',
];

const List<List<String>> _meshGroups = [
  grop1,
];

class _DemoScreenState extends State<DemoScreen> {
  final ModelViewerProController _controller = ModelViewerProController();

  List<String> _availableMeshes = [];
  final Map<String, bool> _visibilityMap = {};
  bool _isLoading = true;
  bool _isGrounded = true;
  double _exposure = 0.5;
  double _shadowIntensity = 1.0;
  double _shadowSoftness = 0.5;
  final Map<int, String> _activeMeshInGroup = {};

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
                    cameraTarget: "0m 30m 0m",
                    backgroundColor: Colors.grey,
                    initialLoadingMeshes: _kInitialMeshes,
                    onLoad: (List<String> meshes) {
                      setState(() {
                        // Prepend a virtual 'WholeModel' target for bulk ops.
                        _availableMeshes = ['WholeModel', ...meshes];
                        _isLoading = false;

                        // Set all initially to false or visible based on _kInitialMeshes
                        for (final name in _availableMeshes) {
                          if (name == 'WholeModel') {
                            _visibilityMap[name] = true;
                          } else {
                            _visibilityMap[name] =
                                _kInitialMeshes.contains(name);
                          }
                        }

                        // For each exclusive group, ensure only the first one (or initially visible one) is active
                        for (int i = 0; i < _meshGroups.length; i++) {
                          final group = _meshGroups[i];
                          if (group.isNotEmpty) {
                            String? activeMesh;
                            for (var mesh in group) {
                              if (_visibilityMap[mesh] == true) {
                                activeMesh = mesh;
                                break;
                              }
                            }
                            activeMesh ??= group.first;
                            _activeMeshInGroup[i] = activeMesh;

                            // Sync visibility map with group exclusivity
                            for (var mesh in group) {
                              _visibilityMap[mesh] = (mesh == activeMesh);
                              if (mesh != activeMesh) {
                                _controller.setVisibility(mesh, false);
                              } else {
                                _controller.setVisibility(mesh, true);
                              }
                            }
                          }
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
                  if (_availableMeshes.isNotEmpty) ...[
                    _buildGroupCard(),
                    const SizedBox(height: 8),
                    _buildMeshCard(),
                  ] else if (!_isLoading)
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

  // ── Exclusive Groups Card ───────────────────────────────────────────────────

  Widget _buildGroupCard() {
    return Column(
      children: List.generate(_meshGroups.length, (index) {
        final group = _meshGroups[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: _Card(
            title: 'Group ${index + 1} (Exclusive)',
            color: Colors.orange.shade50,
            borderColor: Colors.orange.shade200,
            child: RadioGroup<String>(
              groupValue: _activeMeshInGroup[index],
              onChanged: (val) => _onExclusiveMeshChanged(index, group, val!),
              child: Column(
                children: group.map((meshName) {
                  return RadioListTile<String>(
                    title: Text(meshName, style: const TextStyle(fontSize: 13)),
                    value: meshName,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  );
                }).toList(),
              ),
            ),
          ),
        );
      }),
    );
  }

  void _onExclusiveMeshChanged(
      int groupIndex, List<String> group, String selectedMesh) {
    setState(() {
      _activeMeshInGroup[groupIndex] = selectedMesh;
      for (final m in group) {
        _visibilityMap[m] = (m == selectedMesh);
      }
    });

    _controller.setExclusiveMesh(group, selectedMesh);

    for (int i = 1; i <= 12; i++) {
      Future<void>.delayed(Duration(milliseconds: 50 * i), () {
        if (mounted) setState(() {});
      });
    }
  }

  // ── Mesh list card ────────────────────────────────────────────────────────

  Widget _buildMeshCard() {
    // Split into visible / hidden groups (exclude WholeModel row — shown separately).
    final meshOnly = _availableMeshes.where((m) => m != 'WholeModel').toList();
    final visibleMeshes =
        meshOnly.where((m) => _visibilityMap[m] == true).toList();
    final hiddenMeshes =
        meshOnly.where((m) => _visibilityMap[m] != true).toList();
    final total = meshOnly.length;
    final showing = visibleMeshes.length;

    return _Card(
      title: 'Meshes',
      color: Colors.cyan.shade50,
      borderColor: Colors.cyan.shade200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary bar ──────────────────────────────────────────────────
          Row(
            children: [
              _StatusBadge(
                  label: '$showing shown', color: Colors.green.shade700),
              const SizedBox(width: 6),
              _StatusBadge(
                  label: '${total - showing} hidden',
                  color: Colors.grey.shade500),
              const Spacer(),
              // Whole-model toggle
              _WholeModelToggle(
                allVisible: showing == total,
                someVisible: showing > 0 && showing < total,
                onToggle: (v) {
                  for (final m in meshOnly) {
                    _toggleVisibility(m, v);
                  }
                  _toggleVisibility('WholeModel', v);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Mesh rows ────────────────────────────────────────────────────
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView(
              shrinkWrap: true,
              children: [
                // Visible section
                if (visibleMeshes.isNotEmpty) ...[
                  _buildSectionHeader('Visible (${visibleMeshes.length})',
                      Colors.green.shade700),
                ],
                ...visibleMeshes
                    .map((name) => _buildMeshRow(name, visible: true)),
                // Hidden section
                if (hiddenMeshes.isNotEmpty) ...[
                  _buildSectionHeader(
                      'Hidden (${hiddenMeshes.length})', Colors.grey.shade600),
                ],
                ...hiddenMeshes
                    .map((name) => _buildMeshRow(name, visible: false)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 2),
      child: Row(
        children: [
          Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }

  Widget _buildMeshRow(String name, {required bool visible}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: visible
            ? Colors.white.withValues(alpha: 0.8)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: visible ? Colors.cyan.shade200 : Colors.grey.shade300),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Icon(
          visible ? Icons.view_in_ar : Icons.view_in_ar_outlined,
          size: 16,
          color: visible ? Colors.cyan.shade700 : Colors.grey.shade400,
        ),
        title: Text(
          name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: visible ? Colors.black87 : Colors.grey.shade500,
            decoration: visible ? null : TextDecoration.lineThrough,
            decorationColor: Colors.grey.shade400,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Visibility toggle
            GestureDetector(
              onTap: () => _toggleVisibility(name, !visible),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  visible ? Icons.visibility : Icons.visibility_off,
                  key: ValueKey(visible),
                  color: visible ? Colors.deepPurple : Colors.grey.shade400,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Red colour
            IconButton(
              icon: const Icon(Icons.circle, color: Colors.red, size: 16),
              tooltip: 'Red',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => _applyColor(name, '#FF0000'),
            ),
            // Green colour
            IconButton(
              icon: Icon(Icons.circle, color: Colors.green.shade600, size: 16),
              tooltip: 'Green',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => _applyColor(name, '#00C853'),
            ),
          ],
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
    // Update Flutter UI first for instant feedback.
    setState(() => _visibilityMap[name] = visible);
    // Then fire the JS call to update the WebView renderer.
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

    // Schedule 12 Flutter frame rebuilds spaced 50 ms apart, matching the
    // JS-side exposure pump ticks.  Each rebuild causes Flutter to re-composite
    // the WebView's latest WebGL surface so the mesh change is visible on screen
    // WITHOUT the user needing to touch/drag the 3D viewer.
    for (int i = 1; i <= 12; i++) {
      Future<void>.delayed(Duration(milliseconds: 50 * i), () {
        if (mounted) setState(() {});
      });
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

/// Small pill badge showing a count label.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

/// Whole-model show/hide toggle button with indeterminate state support.
class _WholeModelToggle extends StatelessWidget {
  const _WholeModelToggle({
    required this.allVisible,
    required this.someVisible,
    required this.onToggle,
  });
  final bool allVisible;
  final bool someVisible;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final icon = allVisible
        ? Icons.visibility
        : someVisible
            ? Icons.visibility_outlined
            : Icons.visibility_off;
    final color = allVisible
        ? Colors.deepPurple
        : someVisible
            ? Colors.deepPurple.shade200
            : Colors.grey.shade500;
    final label = allVisible ? 'Hide all' : 'Show all';

    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 15, color: color),
      label: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      onPressed: () => onToggle(!allVisible),
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
