import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class WorkoutProvider extends ChangeNotifier {
  late List<CameraDescription> _cameras;

  CameraController? controller;

  Future<void> init() async {
    _cameras = await availableCameras();

    controller = CameraController(_cameras[1], ResolutionPreset.max);
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    controller!
        .initialize()
        .then((_) {
          notifyListeners();
        })
        .catchError((Object e) {
          if (e is CameraException) {
            switch (e.code) {
              case 'CameraAccessDenied':
                // Handle access errors here.
                break;
              default:
                // Handle other errors here.
                break;
            }
          }
        });
    notifyListeners();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
