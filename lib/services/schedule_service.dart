import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/focus_schedule.dart';

class ScheduleService {
  ScheduleService._();
  static final instance = ScheduleService._();

  FocusSchedule get schedule => HiveService.getFocusSchedule();

  bool get isInFocusWindow => schedule.isActiveAt(DateTime.now());

  /// During focus hours, treat blocking as immediate regardless of timed mode.
  String effectiveBlockMode() {
    if (isInFocusWindow) return 'immediate';
    return HiveService.getBlockMode();
  }
}
