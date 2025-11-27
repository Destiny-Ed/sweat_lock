import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class WorkoutProvider extends ChangeNotifier {
  late List<CameraDescription> _cameras;

  CameraController? controller;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
    _cameras = await availableCameras();

    controller = CameraController(_cameras[1], ResolutionPreset.max);
    await Future.delayed(const Duration(seconds: 1));
    controller!
        .initialize()
        .then((_) {
          _isLoading = false;
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
          _isLoading = false;
          notifyListeners();
        });
  }

  // @override
  // void dispose() {
  //   controller?.dispose();
  //   super.dispose();
  // }
}
