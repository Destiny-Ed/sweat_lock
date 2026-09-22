import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/blocked_app.dart';
import 'package:sweat_lock/data/models/workout_session.dart';
import 'package:uuid/uuid.dart';

class WorkoutProvider extends ChangeNotifier {
  CameraController? controller;
  PoseDetector? _poseDetector;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isDetecting = false;
  bool _isWorkoutActive = false;
  bool get isWorkoutActive => _isWorkoutActive;

  int _currentReps = 0;
  int get currentReps => _currentReps;

  int _targetReps = defaultReps;
  int get targetReps => _targetReps;

  String _exerciseType = defaultExercise;
  String get exerciseType => _exerciseType;

  String _feedback = 'Get into position';
  String get feedback => _feedback;

  String _playlistName = 'Workout Mix';
  String get playlistName => _playlistName;

  String _playlistUrl =
      'https://open.spotify.com/playlist/37i9dQZF1DX70RN3TfWWJh';
  String get playlistUrl => _playlistUrl;

  String? _appName;
  String? get appName => _appName;

  bool _isDown = false;
  String? _sessionId;
  String? _unlockedAppId;

  DateTime? _startedAt;

  Future<void> init({
    int? targetReps,
    String? exerciseType,
    String? unlockedAppId,
    String? playlistName,
    String? playlistUrl,
    String? appName,
  }) async {
    _isLoading = true;
    _currentReps = 0;
    _isDown = false;
    _feedback = 'Get into position';
    _unlockedAppId = unlockedAppId;

    // Resolve from saved BlockedApp when possible
    BlockedApp? blocked;
    if (unlockedAppId != null) {
      final apps = HiveService.getBlockedApps();
      for (final a in apps) {
        if (a.id == unlockedAppId) {
          blocked = a;
          break;
        }
      }
    }

    _targetReps = targetReps ?? blocked?.requiredReps ?? HiveService.getDefaultReps();
    _exerciseType =
        exerciseType ?? blocked?.exerciseType ?? HiveService.getDefaultExercise();
    _playlistName = playlistName ?? blocked?.playlistName ?? 'Workout Mix';
    _playlistUrl = playlistUrl ??
        blocked?.playlistUrl ??
        'https://open.spotify.com/playlist/37i9dQZF1DX70RN3TfWWJh';
    _appName = appName ?? blocked?.appName;

    _sessionId = const Uuid().v4();
    _startedAt = DateTime.now();
    notifyListeners();

    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await controller!.initialize();

      _poseDetector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
          model: PoseDetectionModel.base,
        ),
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('WorkoutProvider init error: $e');
      _isLoading = false;
      _feedback = 'Camera error. Please allow camera access.';
      notifyListeners();
    }
  }

  Future<void> startWorkout() async {
    if (controller == null || !controller!.value.isInitialized) return;
    if (_isWorkoutActive) return;

    _isWorkoutActive = true;
    _currentReps = 0;
    _isDown = false;
    _feedback = 'Start ${_exerciseType}!';
    notifyListeners();

    await controller!.startImageStream(_processCameraImage);
  }

  Future<void> stopWorkout({bool completed = false}) async {
    _isWorkoutActive = false;

    try {
      if (controller != null && controller!.value.isStreamingImages) {
        await controller!.stopImageStream();
      }
    } catch (_) {}

    final session = WorkoutSession(
      id: _sessionId ?? const Uuid().v4(),
      exerciseType: _exerciseType,
      targetReps: _targetReps,
      completedReps: _currentReps,
      startedAt: _startedAt ?? DateTime.now(),
      completedAt: completed ? DateTime.now() : null,
      unlockedAppId: _unlockedAppId,
    );
    await HiveService.saveSession(session);

    if (completed) {
      await _updateProgress();
    }

    notifyListeners();
  }

  Future<void> _updateProgress() async {
    final progress = HiveService.getProgress();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int newStreak = progress.currentStreak;
    if (progress.lastWorkoutDate != null) {
      final last = DateTime(
        progress.lastWorkoutDate!.year,
        progress.lastWorkoutDate!.month,
        progress.lastWorkoutDate!.day,
      );
      final diff = today.difference(last).inDays;
      if (diff == 1) {
        newStreak += 1;
      } else if (diff > 1) {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    final updated = progress.copyWith(
      currentStreak: newStreak,
      longestStreak: max(newStreak, progress.longestStreak),
      totalReps: progress.totalReps + _currentReps,
      totalWorkouts: progress.totalWorkouts + 1,
      lastWorkoutDate: now,
    );

    await HiveService.saveProgress(updated);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting || !_isWorkoutActive || _poseDetector == null) return;
    _isDetecting = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      final poses = await _poseDetector!.processImage(inputImage);
      if (poses.isNotEmpty) {
        _analyzePose(poses.first);
      }
    } catch (e) {
      debugPrint('Pose detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  void _analyzePose(Pose pose) {
    switch (_exerciseType.toLowerCase()) {
      case 'squats':
        _countSquats(pose);
        break;
      case 'sit-ups':
        _countSitUps(pose);
        break;
      case 'jumping jacks':
        _countJumpingJacks(pose);
        break;
      case 'push-ups':
      default:
        _countPushUps(pose);
        break;
    }
  }

  void _countPushUps(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if ([leftShoulder, rightShoulder, leftElbow, rightElbow, leftWrist, rightWrist]
        .contains(null)) {
      _feedback = 'Make sure your upper body is visible';
      notifyListeners();
      return;
    }

    final leftAngle = _angle(leftShoulder!, leftElbow!, leftWrist!);
    final rightAngle = _angle(rightShoulder!, rightElbow!, rightWrist!);
    final avgAngle = (leftAngle + rightAngle) / 2;

    if (avgAngle < 100 && !_isDown) {
      _isDown = true;
      _feedback = 'Go lower!';
      notifyListeners();
    } else if (avgAngle > 150 && _isDown) {
      _isDown = false;
      _currentReps++;
      _feedback = _currentReps >= _targetReps ? 'Great job!' : 'Good rep!';
      notifyListeners();
      if (_currentReps >= _targetReps) stopWorkout(completed: true);
    }
  }

  void _countSquats(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if ([leftHip, rightHip, leftKnee, rightKnee, leftAnkle, rightAnkle]
        .contains(null)) {
      _feedback = 'Make sure your full body is visible';
      notifyListeners();
      return;
    }

    final leftAngle = _angle(leftHip!, leftKnee!, leftAnkle!);
    final rightAngle = _angle(rightHip!, rightKnee!, rightAnkle!);
    final avgAngle = (leftAngle + rightAngle) / 2;

    if (avgAngle < 100 && !_isDown) {
      _isDown = true;
      _feedback = 'Thighs parallel!';
      notifyListeners();
    } else if (avgAngle > 150 && _isDown) {
      _isDown = false;
      _currentReps++;
      _feedback = _currentReps >= _targetReps ? 'Great job!' : 'Good squat!';
      notifyListeners();
      if (_currentReps >= _targetReps) stopWorkout(completed: true);
    }
  }

  void _countSitUps(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if ([leftShoulder, rightShoulder, leftHip, rightHip].contains(null)) {
      _feedback = 'Lie down and keep body visible';
      notifyListeners();
      return;
    }

    final shoulderY = (leftShoulder!.y + rightShoulder!.y) / 2;
    final hipY = (leftHip!.y + rightHip!.y) / 2;
    final diff = (shoulderY - hipY).abs();

    if (diff < 40 && !_isDown) {
      _isDown = true;
      _feedback = 'Curl up!';
      notifyListeners();
    } else if (diff > 80 && _isDown) {
      _isDown = false;
      _currentReps++;
      _feedback = _currentReps >= _targetReps ? 'Great job!' : 'Good sit-up!';
      notifyListeners();
      if (_currentReps >= _targetReps) stopWorkout(completed: true);
    }
  }

  void _countJumpingJacks(Pose pose) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if ([leftWrist, rightWrist, leftAnkle, rightAnkle].contains(null)) {
      _feedback = 'Make sure full body is visible';
      notifyListeners();
      return;
    }

    final armSpread = (leftWrist!.x - rightWrist!.x).abs();
    final legSpread = (leftAnkle!.x - rightAnkle!.x).abs();

    if (armSpread > 120 && legSpread > 80 && !_isDown) {
      _isDown = true;
      _feedback = 'Jump back!';
      notifyListeners();
    } else if (armSpread < 60 && legSpread < 40 && _isDown) {
      _isDown = false;
      _currentReps++;
      _feedback =
          _currentReps >= _targetReps ? 'Great job!' : 'Good jumping jack!';
      notifyListeners();
      if (_currentReps >= _targetReps) stopWorkout(completed: true);
    }
  }

  double _angle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final ab = Offset(a.x - b.x, a.y - b.y);
    final cb = Offset(c.x - b.x, c.y - b.y);
    final dot = ab.dx * cb.dx + ab.dy * cb.dy;
    final magAB = sqrt(ab.dx * ab.dx + ab.dy * ab.dy);
    final magCB = sqrt(cb.dx * cb.dx + cb.dy * cb.dy);
    if (magAB == 0 || magCB == 0) return 0;
    final cos = (dot / (magAB * magCB)).clamp(-1.0, 1.0);
    return acos(cos) * 180 / pi;
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = controller!.description;
    final sensorOrientation = camera.sensorOrientation;

    final rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || image.planes.isEmpty) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  double get progress =>
      _targetReps == 0 ? 0 : (_currentReps / _targetReps).clamp(0.0, 1.0);

  @override
  void dispose() {
    try {
      controller?.dispose();
      _poseDetector?.close();
    } catch (_) {}
    super.dispose();
  }
}
