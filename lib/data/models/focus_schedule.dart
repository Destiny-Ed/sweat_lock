/// Weekly focus window when locked apps are forced closed / hard-blocked.
class FocusSchedule {
  final bool enabled;
  /// 0–23
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  /// DateTime.weekday values: 1 = Mon … 7 = Sun
  final List<int> weekdays;

  const FocusSchedule({
    this.enabled = false,
    this.startHour = 9,
    this.startMinute = 0,
    this.endHour = 17,
    this.endMinute = 0,
    this.weekdays = const [1, 2, 3, 4, 5],
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
        'weekdays': weekdays,
      };

  static int _i(dynamic v, int fallback) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  factory FocusSchedule.fromJson(Map<String, dynamic> json) {
    final daysRaw = json['weekdays'];
    List<int> days = const [1, 2, 3, 4, 5];
    if (daysRaw is List && daysRaw.isNotEmpty) {
      days = daysRaw.map((e) => _i(e, 1)).toList();
    }
    return FocusSchedule(
      enabled: json['enabled'] == true,
      startHour: _i(json['startHour'], 9).clamp(0, 23),
      startMinute: _i(json['startMinute'], 0).clamp(0, 59),
      endHour: _i(json['endHour'], 17).clamp(0, 23),
      endMinute: _i(json['endMinute'], 0).clamp(0, 59),
      weekdays: days,
    );
  }

  FocusSchedule copyWith({
    bool? enabled,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    List<int>? weekdays,
  }) {
    return FocusSchedule(
      enabled: enabled ?? this.enabled,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      weekdays: weekdays ?? this.weekdays,
    );
  }

  String get timeRangeLabel {
    final s =
        '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
    final e =
        '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
    return '$s – $e';
  }

  String get label {
    final days = weekdays.map(_dayShort).join(', ');
    return '$days · $timeRangeLabel';
  }

  static String _dayShort(int d) =>
      const ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d];

  /// True if [now] falls inside this schedule (handles overnight windows).
  bool isActiveAt(DateTime now) {
    if (!enabled) return false;
    if (!weekdays.contains(now.weekday)) return false;

    final start = startHour * 60 + startMinute;
    final end = endHour * 60 + endMinute;
    final cur = now.hour * 60 + now.minute;

    if (start == end) return true; // full day
    if (start < end) {
      return cur >= start && cur < end;
    }
    // overnight e.g. 22:00–07:00
    return cur >= start || cur < end;
  }
}
