/// Flutter 3D — display and control interactive 3D models (GLB/GLTF)
/// using model-viewer under the hood.
///
/// Use [ModelViewerProViewer] to embed a 3D model in your widget tree and
/// [ModelViewerProController] to control it at runtime (meshes, camera,
/// animations, lighting, environment images, etc.).
library model_viewer_pro;

// Core widget and controller
export 'src/viewer.dart';
export 'src/controller.dart';

// Feature mixins — re-exported so consumers can use type annotations
export 'src/operations/mesh_operations.dart';
export 'src/operations/environment_operations.dart';
export 'src/operations/lighting_operations.dart';
export 'src/operations/camera_operations.dart';
export 'src/operations/animation_operations.dart';
export 'src/operations/asset_loader_operations.dart';
