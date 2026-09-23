import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/blocked_app.dart';
import 'package:sweat_lock/data/models/workout_session.dart';
import 'package:sweat_lock/services/blocking_service.dart';
import 'package:sweat_lock/services/ios_nudge_service.dart';
import 'package:sweat_lock/services/music_service.dart';
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

  String _playlistUrl = MusicService.defaultSpotify;
  String get playlistUrl => _playlistUrl;

  String? _appName;
  String? get appName => _appName;

  bool _isDown = false;
  DateTime? _lastRepAt;
  static const _minRepGap = Duration(milliseconds: 900);
  static const _minLikelihood = 0.55;

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
    _lastRepAt = null;
    _feedback = 'Get into position — full body in frame';
    _unlockedAppId = unlockedAppId;

    BlockedApp? blocked;
    if (unlockedAppId != null) {
      for (final a in HiveService.getBlockedApps()) {
        if (a.id == unlockedAppId) {
          blocked = a;
          break;
        }
      }
    }

    _targetReps =
        targetReps ?? blocked?.requiredReps ?? HiveService.getDefaultReps();
    _exerciseType = exerciseType ??
        blocked?.exerciseType ??
        HiveService.getDefaultExercise();

    final genres = blocked?.musicGenres.isNotEmpty == true
        ? blocked!.musicGenres
        : HiveService.getMusicGenres();
    final resolved = MusicService.instance.resolve(
      genres: genres,
      playlistName: playlistName ?? blocked?.playlistName,
      playlistUrl: playlistUrl ?? blocked?.playlistUrl,
    );
    _playlistName = resolved.name;
    _playlistUrl = resolved.url;
    if (HiveService.getPreferYoutubeMusic() && genres.isNotEmpty) {
      final g = genres.first.toLowerCase();
      final yt = MusicService.youtubeByGenre[g];
      if (yt != null) _playlistUrl = yt;
    }

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
          model: PoseDetectionModel.accurate,
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

  Future<bool> openMusic() => MusicService.instance.openPlaylist(_playlistUrl);

  Future<void> startWorkout() async {
    if (controller == null || !controller!.value.isInitialized) return;
    if (_isWorkoutActive) return;

    _isWorkoutActive = true;
    _currentReps = 0;
    _isDown = false;
    _lastRepAt = null;
    _feedback = 'Start $_exerciseType — keep form strict';
    notifyListeners();

    // Kick off music in the background (Spotify / YT Music)
    unawaited(openMusic());

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
      await _grantUnlockAfterWorkout();
    }

    notifyListeners();
  }

  Future<void> _grantUnlockAfterWorkout() async {
    final mins = HiveService.getUnlockDurationMinutes();
    if (Platform.isIOS) {
      await IosNudgeService.instance.onWorkoutCompleted(unlockMinutes: mins);
    } else if (Platform.isAndroid) {
      await BlockingService.instance.grantCurrentUnlock(minutes: mins);
      await BlockingService.instance.startListening();
    }
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
      } else {
        _feedback = 'Step into frame — full body visible';
        notifyListeners();
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

  bool _ok(PoseLandmark? lm) =>
      lm != null && lm.likelihood >= _minLikelihood;

  bool _canCountRep() {
    if (_lastRepAt == null) return true;
    return DateTime.now().difference(_lastRepAt!) >= _minRepGap;
  }

  void _registerRep(String goodMsg) {
    if (!_canCountRep()) return;
    _lastRepAt = DateTime.now();
    _isDown = false;
    _currentReps++;
    _feedback = _currentReps >= _targetReps ? 'Great job!' : goodMsg;
    notifyListeners();
    if (_currentReps >= _targetReps) stopWorkout(completed: true);
  }

  void _countPushUps(Pose pose) {
    final ls = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rs = pose.landmarks[PoseLandmarkType.rightShoulder];
    final le = pose.landmarks[PoseLandmarkType.leftElbow];
    final re = pose.landmarks[PoseLandmarkType.rightElbow];
    final lw = pose.landmarks[PoseLandmarkType.leftWrist];
    final rw = pose.landmarks[PoseLandmarkType.rightWrist];
    final lh = pose.landmarks[PoseLandmarkType.leftHip];
    final rh = pose.landmarks[PoseLandmarkType.rightHip];

    if (!_ok(ls) || !_ok(rs) || !_ok(le) || !_ok(re) || !_ok(lw) || !_ok(rw)) {
      _feedback = 'Show shoulders, elbows & wrists clearly';
      notifyListeners();
      return;
    }
    if (!_ok(lh) || !_ok(rh)) {
      _feedback = 'Include hips in frame for real push-ups';
      notifyListeners();
      return;
    }

    final shoulderY = (ls!.y + rs!.y) / 2;
    final hipY = (lh!.y + rh!.y) / 2;
    final bodyFlat = (shoulderY - hipY).abs() < 120;
    if (!bodyFlat) {
      _feedback = 'Get into plank / push-up position';
      notifyListeners();
      return;
    }

    final leftAngle = _angle(ls, le!, lw!);
    final rightAngle = _angle(rs, re!, rw!);
    final avgAngle = (leftAngle + rightAngle) / 2;

    if (avgAngle < 85 && !_isDown) {
      _isDown = true;
      _feedback = 'Push up!';
      notifyListeners();
    } else if (avgAngle > 155 && _isDown) {
      _registerRep('Good push-up!');
    } else if (!_isDown && avgAngle > 120) {
      _feedback = 'Lower your chest toward the floor';
      notifyListeners();
    }
  }

  void _countSquats(Pose pose) {
    final lh = pose.landmarks[PoseLandmarkType.leftHip];
    final rh = pose.landmarks[PoseLandmarkType.rightHip];
    final lk = pose.landmarks[PoseLandmarkType.leftKnee];
    final rk = pose.landmarks[PoseLandmarkType.rightKnee];
    final la = pose.landmarks[PoseLandmarkType.leftAnkle];
    final ra = pose.landmarks[PoseLandmarkType.rightAnkle];
    final ls = pose.landmarks[PoseLandmarkType.leftShoulder];

    if (!_ok(lh) || !_ok(rh) || !_ok(lk) || !_ok(rk) || !_ok(la) || !_ok(ra)) {
      _feedback = 'Show hips, knees & ankles — full body';
      notifyListeners();
      return;
    }
    if (!_ok(ls)) {
      _feedback = 'Step back so shoulders are visible too';
      notifyListeners();
      return;
    }

    final leftAngle = _angle(lh!, lk!, la!);
    final rightAngle = _angle(rh!, rk!, ra!);
    final avgAngle = (leftAngle + rightAngle) / 2;

    if (avgAngle < 95 && !_isDown) {
      _isDown = true;
      _feedback = 'Drive up!';
      notifyListeners();
    } else if (avgAngle > 160 && _isDown) {
      _registerRep('Good squat!');
    } else if (!_isDown) {
      _feedback = 'Sit back deeper into the squat';
      notifyListeners();
    }
  }

  void _countSitUps(Pose pose) {
    final ls = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rs = pose.landmarks[PoseLandmarkType.rightShoulder];
    final lh = pose.landmarks[PoseLandmarkType.leftHip];
    final rh = pose.landmarks[PoseLandmarkType.rightHip];
    final lk = pose.landmarks[PoseLandmarkType.leftKnee];

    if (!_ok(ls) || !_ok(rs) || !_ok(lh) || !_ok(rh) || !_ok(lk)) {
      _feedback = 'Lie on your back — shoulders, hips & knees visible';
      notifyListeners();
      return;
    }

    final torso = _angle(ls!, lh!, lk!);

    if (torso > 140 && (ls.y - lh.y).abs() < 50 && !_isDown) {
      _isDown = true;
      _feedback = 'Curl up toward knees';
      notifyListeners();
    } else if (torso < 70 && _isDown) {
      _registerRep('Good sit-up!');
    } else if (!_isDown) {
      _feedback = 'Lie flat, then sit up fully';
      notifyListeners();
    }
  }

  void _countJumpingJacks(Pose pose) {
    final lw = pose.landmarks[PoseLandmarkType.leftWrist];
    final rw = pose.landmarks[PoseLandmarkType.rightWrist];
    final la = pose.landmarks[PoseLandmarkType.leftAnkle];
    final ra = pose.landmarks[PoseLandmarkType.rightAnkle];
    final ls = pose.landmarks[PoseLandmarkType.leftShoulder];
    final lh = pose.landmarks[PoseLandmarkType.leftHip];

    if (!_ok(lw) || !_ok(rw) || !_ok(la) || !_ok(ra) || !_ok(ls) || !_ok(lh)) {
      _feedback = 'Full body in frame for jumping jacks';
      notifyListeners();
      return;
    }

    final armSpread = (lw!.x - rw!.x).abs();
    final legSpread = (la!.x - ra!.x).abs();
    final armsUp = lw.y < ls!.y && rw.y < ls.y;

    if (armSpread > 140 && legSpread > 90 && armsUp && !_isDown) {
      _isDown = true;
      _feedback = 'Jump feet together, arms down';
      notifyListeners();
    } else if (armSpread < 50 && legSpread < 35 && _isDown) {
      _registerRep('Good jumping jack!');
    } else if (!_isDown) {
      _feedback = 'Jump out — arms up, feet wide';
      notifyListeners();
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
