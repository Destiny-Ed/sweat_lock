import 'package:device_apps/device_apps.dart';

class AppService {
  static Future<List<Application>> loadAndroidApps() async {
    final apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: false,
      onlyAppsWithLaunchIntent: true,
    );

    return apps;
    // final prefsBox = HiveService.prefsBox;
    // final selected = Set<String>.from(
    //   prefsBox.get('blocked_packages', defaultValue: <String>[]),
    // );
  }

  // static Future<List<dynamic>> pickIOSApps() async {
  //   final permission = await AppLimiter().requestIosPermission();

  //   if (!permission) {
  //     log("permission declined");
  //     return [];
  //   }

  //   final result = await AppLimiter().blockAndUnblockIOSApp();
  //   log("Selected Apps");
  //   return [];
  //   // final prefsBox = HiveService.prefsBox;
  //   // final selected = Set<String>.from(
  //   //   prefsBox.get('blocked_packages', defaultValue: <String>[]),
  //   // );
  // }
}
