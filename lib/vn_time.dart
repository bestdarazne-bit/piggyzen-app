import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Toàn bộ app dùng giờ Việt Nam (Asia/Ho_Chi_Minh, UTC+7) cho mọi tính toán
/// ngày/giờ — không phụ thuộc múi giờ máy/server. Không timer, chỉ tính
/// theo timestamp khi cần (mở app / resume / thao tác), không chạy nền.
class VnTime {
  static bool _inited = false;
  static tz.Location? _loc;

  static void ensureInit() {
    if (_inited) return;
    tzdata.initializeTimeZones();
    _loc = tz.getLocation('Asia/Ho_Chi_Minh');
    _inited = true;
  }

  static tz.Location get loc {
    ensureInit();
    return _loc!;
  }

  /// Thời điểm hiện tại, theo giờ Việt Nam.
  static tz.TZDateTime now() => tz.TZDateTime.now(loc);

  static tz.TZDateTime fromInstant(DateTime instant) =>
      tz.TZDateTime.from(instant.isUtc ? instant : instant.toUtc(), loc);

  /// Khóa ngày (yyyy-MM-dd) theo giờ Việt Nam, dùng để nhóm giao dịch theo
  /// ngày và reset hạn mức chi tiêu / thử thách đúng theo ngày VN.
  static String dayKey([DateTime? instant]) {
    final v = instant == null ? now() : fromInstant(instant);
    return '${v.year}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
  }

  static String fmtDateTime(DateTime instant) {
    final v = fromInstant(instant);
    final hh = v.hour.toString().padLeft(2, '0');
    final mm = v.minute.toString().padLeft(2, '0');
    return '${v.day.toString().padLeft(2, '0')}/${v.month.toString().padLeft(2, '0')}/${v.year} $hh:$mm';
  }

  static String fmtTime(DateTime instant) {
    final v = fromInstant(instant);
    final hh = v.hour.toString().padLeft(2, '0');
    final mm = v.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

