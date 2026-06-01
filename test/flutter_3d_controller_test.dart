import 'package:flutter_test/flutter_test.dart';
import 'package:model_viewer_pro/model_viewer_pro.dart';

void main() {
  group('ModelViewerProController', () {
    late ModelViewerProController controller;

    setUp(() {
      controller = ModelViewerProController();
    });

    test('can be instantiated', () {
      expect(controller, isNotNull);
      expect(controller.webViewController, isNull);
    });

    test('exposes MeshOperations', () async {
      final result = await controller.getAvailableMeshes();
      expect(result, isEmpty);
    });

    test('exposes AnimationOperations', () async {
      await controller.playAnimation();
      await controller.pauseAnimation();
      expect(true, isTrue);
    });

    test('exposes CameraOperations', () async {
      await controller.setCameraTarget(0, 1, 0);
      expect(true, isTrue);
    });
    
    test('exposes EnvironmentOperations', () async {
      final result = await controller.loadSkyboxFromAsset('assets/test.jpg');
      expect(result, isFalse);
    });
  });
}
