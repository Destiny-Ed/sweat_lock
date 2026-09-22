class BlockedApp {
  final String id;
  final String appName;
  final String packageName; // Android
  final String bundleId; // iOS
  final String? iconPath;
  final int requiredReps;
  final String exerciseType; // push-ups, squats, sit-ups, jumping jacks
  final bool isActive;
  final String playlistName;
  final String playlistUrl; // dummy deep link for now
  final List<String> musicGenres;

  BlockedApp({
    required this.id,
    required this.appName,
    required this.packageName,
    this.bundleId = '',
    this.iconPath,
    this.requiredReps = 20,
    this.exerciseType = 'push-ups',
    this.isActive = true,
    this.playlistName = 'Workout Mix',
    this.playlistUrl =
        'https://open.spotify.com/playlist/37i9dQZF1DX70RN3TfWWJh',
    this.musicGenres = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'appName': appName,
        'packageName': packageName,
        'bundleId': bundleId,
        'iconPath': iconPath,
        'requiredReps': requiredReps,
        'exerciseType': exerciseType,
        'isActive': isActive,
        'playlistName': playlistName,
        'playlistUrl': playlistUrl,
        'musicGenres': musicGenres,
      };

  factory BlockedApp.fromJson(Map<String, dynamic> json) => BlockedApp(
        id: json['id'] as String,
        appName: json['appName'] as String,
        packageName: json['packageName'] as String? ?? '',
        bundleId: json['bundleId'] as String? ?? '',
        iconPath: json['iconPath'] as String?,
        requiredReps: json['requiredReps'] as int? ?? 20,
        exerciseType: json['exerciseType'] as String? ?? 'push-ups',
        isActive: json['isActive'] as bool? ?? true,
        playlistName: json['playlistName'] as String? ?? 'Workout Mix',
        playlistUrl: json['playlistUrl'] as String? ??
            'https://open.spotify.com/playlist/37i9dQZF1DX70RN3TfWWJh',
        musicGenres: List<String>.from(json['musicGenres'] as List? ?? []),
      );

  BlockedApp copyWith({
    String? id,
    String? appName,
    String? packageName,
    String? bundleId,
    String? iconPath,
    int? requiredReps,
    String? exerciseType,
    bool? isActive,
    String? playlistName,
    String? playlistUrl,
    List<String>? musicGenres,
  }) {
    return BlockedApp(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      bundleId: bundleId ?? this.bundleId,
      iconPath: iconPath ?? this.iconPath,
      requiredReps: requiredReps ?? this.requiredReps,
      exerciseType: exerciseType ?? this.exerciseType,
      isActive: isActive ?? this.isActive,
      playlistName: playlistName ?? this.playlistName,
      playlistUrl: playlistUrl ?? this.playlistUrl,
      musicGenres: musicGenres ?? this.musicGenres,
    );
  }
}

/// Suggested social apps for onboarding (Android package names where known)
class SuggestedApp {
  final String name;
  final String packageName;

  const SuggestedApp({
    required this.name,
    required this.packageName,
  });
}
