import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));

    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await impl?.requestNotificationsPermission();
  }

  static tz.TZDateTime _next(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
    return t;
  }

  static Future<void> _daily(int id, int h, int m, String title, String body) {
    return _plugin.zonedSchedule(
      id,
      title,
      body,
      _next(h, m),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'piggyzen_daily',
          'Nhắc nhở PiggyZen',
          channelDescription: 'Nhắc nhập trợ cấp, chi tiêu và tổng kết ngày',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Đặt lịch cả 4 thông báo hằng ngày.
  static Future<void> scheduleAll(String summaryBody) async {
    await _daily(1, 6, 0, '🐖 Sáng rồi!', 'Nhập tiền ăn sáng / đi học hôm nay để heo tính phần cất hũ nhé.');
    await _daily(2, 13, 0, '🐖 Trưa rồi!', 'Nhập tiền trợ cấp bữa trưa. Nhớ: ăn ít thôi, cất nhiều vào!');
    await _daily(3, 20, 0, '🐖 Kiểm tra số dư', 'Vào app kiểm tra số dư và nhập các khoản chi trong ngày.');
    await scheduleSummary(summaryBody);
  }

  /// Thông báo 21:00. Nội dung được cập nhật mỗi khi dữ liệu thay đổi.
  static Future<void> scheduleSummary(String body) {
    return _daily(4, 21, 0, '📊 Tổng kết tài chính hôm nay', body);
  }
}
