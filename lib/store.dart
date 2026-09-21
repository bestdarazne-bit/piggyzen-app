import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'notification_service.dart';

class SpendResult {
  final bool ok;
  final String title;
  final String message;
  final bool harsh; // true = hiện hộp thoại nghiêm khắc
  SpendResult(this.ok, this.title, this.message, {this.harsh = false});
}

const kFoodKeywords = [
  'cơm', 'phở', 'bún', 'trà sữa', 'cà phê', 'cafe', 'coffee', 'bánh', 'xôi',
  'mì', 'hủ tiếu', 'lẩu', 'nướng', 'ăn vặt', 'trà', 'nước ngọt', 'pizza',
  'gà rán', 'snack', 'kem', 'ăn sáng', 'ăn trưa', 'ăn tối', 'đồ ăn',
];

const kRollOptions = [5000, 10000, 20000, 50000];

class AppStore extends ChangeNotifier {
  static const _key = 'piggyzen_data_v1';
  late SharedPreferences _prefs;

  int wallet = 0;
  Goal? goal;
  List<Txn> txns = [];
  String rollDate = '';
  int rollAmount = 0;
  bool rollDone = false;

  int bounceTick = 0; // tăng lên để kích hoạt animation heo nảy
  bool lastBlocked = false;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      wallet = (m['wallet'] as int?) ?? 0;
      goal = m['goal'] == null ? null : Goal.fromJson(m['goal'] as Map<String, dynamic>);
      txns = ((m['txns'] as List?) ?? [])
          .map((e) => Txn.fromJson(e as Map<String, dynamic>))
          .toList();
      rollDate = (m['rollDate'] as String?) ?? '';
      rollAmount = (m['rollAmount'] as int?) ?? 0;
      rollDone = (m['rollDone'] as bool?) ?? false;
    } catch (e) {
      debugPrint('Load error: $e');
    }
  }

  void _commit() {
    if (txns.length > 500) txns = txns.sublist(txns.length - 500);
    _prefs.setString(
      _key,
      jsonEncode({
        'wallet': wallet,
        'goal': goal?.toJson(),
        'txns': txns.map((t) => t.toJson()).toList(),
        'rollDate': rollDate,
        'rollAmount': rollAmount,
        'rollDone': rollDone,
      }),
    );
    notifyListeners();
    NotificationService.scheduleSummary(summaryBody()).catchError((e) {
      debugPrint('Schedule error: $e');
    });
  }

  // ---------- Thống kê ----------
  ({int income, int spent, int saved}) today() {
    final k = dayKey(DateTime.now());
    int i = 0, s = 0, v = 0;
    for (final t in txns) {
      if (dayKey(t.time) != k) continue;
      if (t.type == 'income') {
        i += t.amount;
      } else if (t.type == 'spend') {
        s += t.amount;
      } else if (t.type == 'save') {
        v += t.amount;
      }
    }
    return (income: i, spent: s, saved: v);
  }

  String summaryBody() {
    final t = today();
    return 'Nhận: ${fmt(t.income)} • Chi: ${fmt(t.spent)} • Tiết kiệm: ${fmt(t.saved)} • Còn lại: ${fmt(wallet)}';
  }

  /// Heo giận khi vừa bị chặn giao dịch hoặc hôm nay đã chi quá 45%.
  bool get angry {
    if (lastBlocked) return true;
    final t = today();
    final base = wallet + t.spent;
    return t.spent > 0 && t.spent > base * 0.45;
  }

  bool get rolledToday => rollDate == dayKey(DateTime.now());

  // ---------- Hũ mục tiêu ----------
  String? createGoal(String name, int target, int days) {
    if (goal != null) return 'Bạn đang có 1 hũ chưa xong. Hoàn thành hoặc xóa hũ cũ trước nhé!';
    if (name.trim().isEmpty || target <= 0 || days <= 0) return 'Thông tin hũ chưa hợp lệ.';
    goal = Goal(name: name.trim(), target: target, days: days, createdAt: DateTime.now());
    lastBlocked = false;
    _commit();
    return null;
  }

  /// Xóa hũ chưa đạt: tiền trong hũ trả về ví.
  void deleteGoal() {
    final g = goal;
    if (g == null) return;
    if (g.saved > 0) {
      wallet += g.saved;
      txns.add(Txn(type: 'refund', amount: g.saved, note: 'Xóa hũ "${g.name}"', time: DateTime.now()));
    }
    goal = null;
    _commit();
  }

  /// Hoàn thành hũ: tiền trong hũ dùng cho mục tiêu.
  void completeGoal() {
    final g = goal;
    if (g == null || !g.done) return;
    txns.add(Txn(type: 'goal_done', amount: g.saved, note: 'Hoàn thành "${g.name}"', time: DateTime.now()));
    goal = null;
    bounceTick++;
    _commit();
  }

  // ---------- Tiền ----------
  void addIncome(int amount, String note) {
    wallet += amount;
    lastBlocked = false;
    txns.add(Txn(type: 'income', amount: amount, note: note.isEmpty ? 'Trợ cấp' : note, time: DateTime.now()));
    _commit();
  }

  /// Gợi ý: giữ lại ~30%, cất phần còn lại.
  ({int keep, int save}) suggest(int amount) {
    final keep = ((amount * 0.3) / 1000).round() * 1000;
    return (keep: keep, save: amount - keep);
  }

  String? saveToJar(int amount, {String note = 'Bỏ heo'}) {
    if (goal == null) return 'Chưa có hũ mục tiêu. Hãy tạo hũ trước!';
    if (amount <= 0) return 'Số tiền không hợp lệ.';
    if (amount > wallet) return 'Ví chỉ còn ${fmt(wallet)}, không đủ để cất ${fmt(amount)}.';
    wallet -= amount;
    goal!.saved += amount;
    lastBlocked = false;
    bounceTick++;
    txns.add(Txn(type: 'save', amount: amount, note: note, time: DateTime.now()));
    _commit();
    return null;
  }

  SpendResult spend(int amount, String note) {
    final maxAllowed = (wallet * 0.45).floor();
    if (amount > wallet || amount > maxAllowed) {
      lastBlocked = true;
      notifyListeners();
      return SpendResult(
        false,
        '🚫 GIAO DỊCH BỊ KHÓA',
        'Khoản chi ${fmt(amount)} vượt quá 45% số dư (${fmt(wallet)}).\n'
        'Mức tối đa được phép: ${fmt(maxAllowed)}.\n\n'
        'Heo KHÔNG cho phép. Bạn có THỰC SỰ cần khoản này không? Đừng để ví cạn rồi mới hối hận!',
        harsh: true,
      );
    }
    wallet -= amount;
    lastBlocked = false;
    txns.add(Txn(type: 'spend', amount: amount, note: note.isEmpty ? 'Chi tiêu' : note, time: DateTime.now()));
    _commit();

    final low = note.toLowerCase();
    final isFood = kFoodKeywords.any((k) => low.contains(k));
    if (isFood) {
      final g = goal;
      final extra = g == null
          ? ''
          : '\nSố tiền này bằng ${(amount * 100 / g.target).toStringAsFixed(1)}% hũ "${g.name}" của bạn.';
      return SpendResult(
        true,
        '😤 LẠI ĂN NGOÀI À?',
        'Bạn vừa chi ${fmt(amount)} cho "$note". Cơm nhà rẻ hơn nhiều, trà sữa/cà phê không phải nhu cầu thiết yếu!$extra\n\nLần sau nhịn đi, cất vào hũ heo!',
        harsh: true,
      );
    }
    return SpendResult(true, 'Đã ghi chi tiêu', 'Đã trừ ${fmt(amount)}. Ví còn ${fmt(wallet)}.');
  }

  // ---------- Thử thách hằng ngày ----------
  String? roll() {
    if (rolledToday) return 'Hôm nay bạn đã quay rồi. Mai quay tiếp nhé!';
    final options = kRollOptions.where((o) => o <= wallet).toList();
    if (options.isEmpty) return 'Ví không đủ ${fmt(kRollOptions.first)} để làm thử thách.';
    rollAmount = options[Random().nextInt(options.length)];
    rollDate = dayKey(DateTime.now());
    rollDone = false;
    _commit();
    return null;
  }

  String? confirmRoll() {
    if (!rolledToday || rollDone) return 'Không có thử thách để xác nhận.';
    final err = saveToJar(rollAmount, note: 'Thử thách hôm nay');
    if (err != null) return err;
    rollDone = true;
    _commit();
    return null;
  }
}
