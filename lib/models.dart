import 'dart:math';

String fmt(int v) {
  final s = v.abs().toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '${v < 0 ? '-' : ''}${b}đ';
}

/// Hiểu: 35k, 35000, 35.000, 1tr, 2tr
int? parseMoney(String raw) {
  var s = raw.toLowerCase().replaceAll(RegExp(r'[\s\.,đ₫]'), '');
  int mult = 1;
  if (s.endsWith('tr')) {
    mult = 1000000;
    s = s.substring(0, s.length - 2);
  } else if (s.endsWith('k')) {
    mult = 1000;
    s = s.substring(0, s.length - 1);
  }
  final n = int.tryParse(s);
  return n == null ? null : n * mult;
}

String newId() =>
    '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(99999)}';

/// Hồ sơ user cục bộ trên máy — mọi dữ liệu tài chính đều gắn với đúng
/// user.id này, không hard-code, không lẫn giữa các user (nếu sau này hỗ
/// trợ nhiều hồ sơ trên cùng máy).
class AppUser {
  String id;
  String name;
  int dailyLimit; // hạn mức chi tiêu Ví / ngày

  AppUser({required this.id, required this.name, this.dailyLimit = 100000});

  factory AppUser.newLocal() => AppUser(id: newId(), name: 'Bạn');

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'dailyLimit': dailyLimit};

  factory AppUser.fromJson(Map<String, dynamic> m) => AppUser(
        id: m['id'] as String,
        name: (m['name'] as String?) ?? 'Bạn',
        dailyLimit: (m['dailyLimit'] as int?) ?? 100000,
      );
}

/// Hũ mục tiêu hiện tại (chỉ 1 hũ tại một thời điểm). Tiến độ được tính
/// dựa trên số dư Hũ hiện có (piggyBalance), KHÔNG lưu trùng một số tiền
/// "saved" riêng để tránh lệch dữ liệu.
class Goal {
  String name;
  int target;
  int days;
  DateTime createdAt;

  Goal({required this.name, required this.target, required this.days, required this.createdAt});

  int daysLeft(DateTime nowInstant) {
    final end = createdAt.add(Duration(days: days));
    final d = end.difference(nowInstant).inDays + 1;
    return d < 0 ? 0 : d;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'target': target,
        'days': days,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory Goal.fromJson(Map<String, dynamic> m) => Goal(
        name: m['name'] as String,
        target: m['target'] as int,
        days: m['days'] as int,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}

/// Giao dịch VÍ — chỉ 2 loại: income | expense. Không liên quan gì tới Hũ.
class WalletTxn {
  final String id;
  final String type; // income | expense
  final int amount;
  final String category;
  final String note;
  final DateTime timestamp; // lưu UTC, hiển thị theo giờ VN

  WalletTxn({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.note,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'category': category,
        'note': note,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'timezone': 'Asia/Ho_Chi_Minh',
      };

  factory WalletTxn.fromJson(Map<String, dynamic> m) => WalletTxn(
        id: (m['id'] as String?) ?? newId(),
        type: m['type'] as String,
        amount: m['amount'] as int,
        category: (m['category'] as String?) ?? '',
        note: (m['note'] as String?) ?? '',
        timestamp: DateTime.parse(m['timestamp'] as String),
      );
}

/// Giao dịch HŨ HEO ĐẤT — độc lập hoàn toàn với Ví.
/// type: deposit | withdrawal. source: manual | random_challenge.
class PiggyTxn {
  final String id;
  final String type;
  final int amount;
  final String source;
  final String? challengeId;
  final String note;
  final DateTime timestamp;

  PiggyTxn({
    required this.id,
    required this.type,
    required this.amount,
    required this.source,
    this.challengeId,
    this.note = '',
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'source': source,
        'challengeId': challengeId,
        'note': note,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'timezone': 'Asia/Ho_Chi_Minh',
      };

  factory PiggyTxn.fromJson(Map<String, dynamic> m) => PiggyTxn(
        id: (m['id'] as String?) ?? newId(),
        type: m['type'] as String,
        amount: m['amount'] as int,
        source: (m['source'] as String?) ?? 'manual',
        challengeId: m['challengeId'] as String?,
        note: (m['note'] as String?) ?? '',
        timestamp: DateTime.parse(m['timestamp'] as String),
      );
}
