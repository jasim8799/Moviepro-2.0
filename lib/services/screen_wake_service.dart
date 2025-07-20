import 'package:wakelock_plus/wakelock_plus.dart';

class ScreenWakeService {
  static Future<void> keepScreenOn() async {
    try {
      await WakelockPlus.enable();
    } catch (e) {
      print('Failed to keep screen on: \$e');
    }
  }

  static Future<void> allowScreenOff() async {
    try {
      await WakelockPlus.disable();
    } catch (e) {
      print('Failed to allow screen off: \$e');
    }
  }
}
