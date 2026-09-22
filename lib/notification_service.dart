import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'vn_time.dart';

/// Chỉ dùng để ĐĂNG KÝ lịch thông báo với hệ điều hành (Android
/// AlarmManager) — không phải app tự chạy nền: không timer, không
/// service, không polling. Sau khi zonedSchedule xong, app không giữ bất
/// kỳ vòng lặp nào để canh giờ cả.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    VnTime.ensureInit();
    tz.setLocalLocation(VnTime.loc);

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));

    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await impl?.requestNotificationsPermission();
  }

  static tz.TZDateTime _next(int hour, int minute) {
    final now = VnTime.now();
    var t = tz.TZDateTime(VnTime.loc, now.year, now.month, now.day, hour, minute);
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
          channelDescription: 'Nhắc nhập trợ cấp, chi tiêu và tổng kết ngày (giờ Việt Nam)',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Đặt lịch cả 4 thông báo hằng ngày theo giờ Việt Nam.
  static Future<void> scheduleAll(String summaryBody) async {
    await _daily(1, 6, 0, '🐖 Sáng rồi!', 'Nhập tiền ăn sáng / đi học hôm nay vào Ví nhé.');
    await _daily(2, 13, 0, '🐖 Trưa rồi!', 'Nhập tiền trợ cấp bữa trưa vào Ví. Ăn ít thôi, cất nhiều vào Hũ!');
    await _daily(3, 20, 0, '🐖 Kiểm tra số dư', 'Vào app kiểm tra số dư Ví và nhập các khoản chi trong ngày.');
    await scheduleSummary(summaryBody);
  }

  /// Thông báo 21:00. Nội dung là số liệu mới nhất tính đến lần cuối bạn
  /// mở app / ghi giao dịch (không có tiến trình nền nào tính lại theo thời gian thực).
  static Future<void> scheduleSummary(String body) {
    return _daily(4, 21, 0, '📊 Tổng kết tài chính hôm nay', body);
  }
}
