import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'notification_service.dart';
import 'vn_time.dart';

class ActionResult {
  final bool ok;
  final String title;
  final String message;
  final bool harsh;
  ActionResult(this.ok, this.title, this.message, {this.harsh = false});
}

const kFoodKeywords = [
  'cơm', 'phở', 'bún', 'trà sữa', 'cà phê', 'cafe', 'coffee', 'bánh', 'xôi',
  'mì', 'hủ tiếu', 'lẩu', 'nướng', 'ăn vặt', 'trà', 'nước ngọt', 'pizza',
  'gà rán', 'snack', 'kem', 'ăn sáng', 'ăn trưa', 'ăn tối', 'đồ ăn',
];

const kRollOptions = [5000, 10000, 20000, 50000];

/// AppStore là NGUỒN DUY NHẤT của dữ liệu, gắn với đúng 1 [AppUser] cục bộ.
/// Nguyên tắc bất biến trong toàn bộ store này:
///   • walletBalance và piggyBalance là 2 biến ĐỘC LẬP — không có phép
///     toán nào cộng/trừ chéo giữa chúng.
///   • Chi tiêu Ví không bao giờ được phép dùng/trừ tiền Hũ.
///   • Mọi giao dịch được ghi timestamp UTC, hiển thị/gộp-ngày theo giờ
///     Việt Nam (VnTime) — không phụ thuộc múi giờ máy.
///   • Không timer/service chạy nền — mọi số liệu tính lại khi cần
///     (load khi mở app, notifyListeners khi có thao tác).
class AppStore extends ChangeNotifier {
  static const _key = 'piggyzen_data_v2';
  late SharedPreferences _prefs;

  late AppUser user;
  int walletBalance = 0;
  int piggyBalance = 0;
  Goal? goal;
  List<WalletTxn> walletTxns = [];
  List<PiggyTxn> piggyTxns = [];

  // Thử thách ngẫu nhiên của ngày hôm nay (theo giờ VN). Chưa xác nhận thì
  // Hũ không hề thay đổi.
  String? challengeId;
  int challengeAmount = 0;
  String challengeDay = '';
  bool challengeConfirmed = false;

  int mascotTick = 0; // heo nhún một lần khi có sự kiện tích cực
  int celebrateTick = 0; // heo ăn mừng khi đạt mục tiêu
  bool lastBlocked = false;
  bool _busy = false; // chặn double-submit khi bấm nút liên tục

  Future<void> load() async {
    VnTime.ensureInit();
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_key);
    if (raw == null) {
      user = AppUser.newLocal();
      return;
    }
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      user = m['user'] == null ? AppUser.newLocal() : AppUser.fromJson(m['user'] as Map<String, dynamic>);
      walletBalance = (m['walletBalance'] as int?) ?? 0;
      piggyBalance = (m['piggyBalance'] as int?) ?? 0;
      goal = m['goal'] == null ? null : Goal.fromJson(m['goal'] as Map<String, dynamic>);
      walletTxns = ((m['walletTxns'] as List?) ?? [])
          .map((e) => WalletTxn.fromJson(e as Map<String, dynamic>))
          .toList();
      piggyTxns = ((m['piggyTxns'] as List?) ?? [])
          .map((e) => PiggyTxn.fromJson(e as Map<String, dynamic>))
          .toList();
      challengeId = m['challengeId'] as String?;
      challengeAmount = (m['challengeAmount'] as int?) ?? 0;
      challengeDay = (m['challengeDay'] as String?) ?? '';
      challengeConfirmed = (m['challengeConfirmed'] as bool?) ?? false;
    } catch (e) {
      debugPrint('Load error: $e');
      user = AppUser.newLocal();
    }
  }

  void _commit() {
    // Giới hạn lịch sử để tránh file dữ liệu phình to vô hạn.
    if (walletTxns.length > 1000) walletTxns = walletTxns.sublist(walletTxns.length - 1000);
    if (piggyTxns.length > 1000) piggyTxns = piggyTxns.sublist(piggyTxns.length - 1000);
    _prefs.setString(
      _key,
      jsonEncode({
        'user': user.toJson(),
        'walletBalance': walletBalance,
        'piggyBalance': piggyBalance,
        'goal': goal?.toJson(),
        'walletTxns': walletTxns.map((t) => t.toJson()).toList(),
        'piggyTxns': piggyTxns.map((t) => t.toJson()).toList(),
        'challengeId': challengeId,
        'challengeAmount': challengeAmount,
        'challengeDay': challengeDay,
        'challengeConfirmed': challengeConfirmed,
      }),
    );
    notifyListeners();
    NotificationService.scheduleSummary(summaryBody()).catchError((e) {
      debugPrint('Schedule error: $e');
    });
  }

  void updateSettings({String? name, int? dailyLimit}) {
    if (name != null && name.trim().isNotEmpty) user.name = name.trim();
    if (dailyLimit != null && dailyLimit > 0) user.dailyLimit = dailyLimit;
    _commit();
  }

  // ---------- Thống kê VÍ (theo ngày giờ Việt Nam) ----------
  ({int income, int expense}) walletToday() {
    final k = VnTime.dayKey();
    int i = 0, e = 0;
    for (final t in walletTxns) {
      if (VnTime.dayKey(t.timestamp) != k) continue;
      if (t.type == 'income') i += t.amount;
      if (t.type == 'expense') e += t.amount;
    }
    return (income: i, expense: e);
  }

  int get todaySpent => walletToday().expense;
  int get remainingDailyLimit => (user.dailyLimit - todaySpent).clamp(0, user.dailyLimit);

  String summaryBody() {
    final w = walletToday();
    return 'Ví — Nhận: ${fmt(w.income)} • Chi: ${fmt(w.expense)} • Còn: ${fmt(walletBalance)}  |  Hũ: ${fmt(piggyBalance)}';
  }

  /// Heo giận khi vừa bị chặn 1 giao dịch, hoặc hôm nay đã chi gần/vượt
  /// giới hạn — chỉ dựa trên dữ liệu VÍ, không liên quan Hũ.
  bool get angry {
    if (lastBlocked) return true;
    final e = todaySpent;
    if (e <= 0) return false;
    if (e >= user.dailyLimit) return true;
    final base = walletBalance + e;
    return base > 0 && e > base * 0.45;
  }

  bool get rolledToday => challengeDay == VnTime.dayKey();

  // ---------- HŨ MỤC TIÊU (chỉ 1 hũ tại một thời điểm) ----------
  double get goalProgress {
    final g = goal;
    if (g == null || g.target == 0) return 0;
    return (piggyBalance / g.target).clamp(0.0, 1.0).toDouble();
  }

  bool get goalDone {
    final g = goal;
    return g != null && piggyBalance >= g.target;
  }

  String? createGoal(String name, int target, int days) {
    if (goal != null) return 'Bạn đang có 1 hũ chưa xong. Hoàn thành hoặc xóa hũ cũ trước nhé!';
    if (name.trim().isEmpty || target <= 0 || days <= 0) return 'Thông tin hũ chưa hợp lệ.';
    goal = Goal(name: name.trim(), target: target, days: days, createdAt: DateTime.now().toUtc());
    lastBlocked = false;
    _commit();
    return null;
  }

  /// Xóa hũ chưa xong: chỉ hủy mục tiêu, KHÔNG rút tiền khỏi Hũ và
  /// TUYỆT ĐỐI không chuyển gì sang Ví — tiền vẫn nằm nguyên trong Hũ,
  /// sẵn sàng cho mục tiêu tiếp theo.
  void deleteGoal() {
    if (goal == null) return;
    goal = null;
    _commit();
  }

  /// Hoàn thành hũ: "đập heo" — rút đúng số tiền mục tiêu ra khỏi Hũ để
  /// dùng vào việc đã đặt ra. Đây là một withdrawal của Hũ, không đụng gì
  /// đến Ví.
  void completeGoal() {
    final g = goal;
    if (g == null || !goalDone) return;
    final amount = g.target > piggyBalance ? piggyBalance : g.target;
    piggyBalance -= amount;
    piggyTxns.add(PiggyTxn(
      id: newId(),
      type: 'withdrawal',
      amount: amount,
      source: 'manual',
      note: 'Hoàn thành mục tiêu "${g.name}"',
      timestamp: DateTime.now().toUtc(),
    ));
    goal = null;
    celebrateTick++;
    _commit();
  }

  // ---------- VÍ: thu nhập & chi tiêu ----------
  void addIncome(int amount, String note, {String category = 'Trợ cấp'}) {
    if (_busy) return;
    _busy = true;
    walletBalance += amount;
    lastBlocked = false;
    walletTxns.add(WalletTxn(
      id: newId(),
      type: 'income',
      amount: amount,
      category: category,
      note: note.isEmpty ? category : note,
      timestamp: DateTime.now().toUtc(),
    ));
    _commit();
    _busy = false;
  }

  /// Gợi ý: giữ lại ~30% để tiêu, phần còn lại nên cất vào Hũ (không tự
  /// động trừ Ví — đây chỉ là gợi ý, muốn cất thật thì gọi [depositToPiggy]).
  ({int keep, int save}) suggestSaving(int amount) {
    final keep = ((amount * 0.3) / 1000).round() * 1000;
    return (keep: keep, save: amount - keep);
  }

  ActionResult spend(int amount, String note, {String category = 'Chi tiêu'}) {
    if (amount <= 0) return ActionResult(false, 'Lỗi', 'Số tiền không hợp lệ.');
    if (amount > walletBalance) {
      return ActionResult(false, 'Không đủ số dư', 'Ví chỉ còn ${fmt(walletBalance)}, không đủ để chi ${fmt(amount)}.');
    }

    // Quy tắc 1: hạn mức chi tiêu/ngày (mặc định 100.000đ), KHÔNG tính tiền Hũ.
    final spentToday = todaySpent;
    if (spentToday + amount > user.dailyLimit) {
      lastBlocked = true;
      notifyListeners();
      return ActionResult(
        false,
        '⚠️ Đã vượt giới hạn chi tiêu hôm nay',
        'Giới hạn: ${fmt(user.dailyLimit)}\nĐã chi: ${fmt(spentToday)}\nGiao dịch: ${fmt(amount)}',
        harsh: true,
      );
    }

    // Quy tắc 2: một khoản chi không được vượt quá 45% số dư Ví hiện tại.
    final maxAllowed = (walletBalance * 0.45).floor();
    if (amount > maxAllowed) {
      lastBlocked = true;
      notifyListeners();
      return ActionResult(
        false,
        '🚫 GIAO DỊCH BỊ KHÓA',
        'Khoản chi ${fmt(amount)} vượt quá 45% số dư Ví (${fmt(walletBalance)}).\n'
            'Mức tối đa được phép: ${fmt(maxAllowed)}.\n\n'
            'Heo KHÔNG cho phép. Bạn có THỰC SỰ cần khoản này không?',
        harsh: true,
      );
    }

    walletBalance -= amount;
    lastBlocked = false;
    walletTxns.add(WalletTxn(
      id: newId(),
      type: 'expense',
      amount: amount,
      category: category,
      note: note.isEmpty ? 'Chi tiêu' : note,
      timestamp: DateTime.now().toUtc(),
    ));
    _commit();

    final low = note.toLowerCase();
    if (kFoodKeywords.any((k) => low.contains(k))) {
      return ActionResult(
        true,
        '😤 LẠI ĂN NGOÀI À?',
        'Bạn vừa chi ${fmt(amount)} cho "$note". Cơm nhà rẻ hơn nhiều, trà sữa/cà phê không phải nhu cầu thiết yếu!\n\nLần sau nhịn đi, cất vào Hũ heo!',
        harsh: true,
      );
    }
    return ActionResult(true, 'Đã ghi chi tiêu', 'Đã trừ ${fmt(amount)} khỏi Ví. Ví còn ${fmt(walletBalance)}.');
  }

  // ---------- HŨ: cất tiền thủ công (độc lập với Ví, không cần có mục
  // tiêu đang chạy — Hũ luôn là một khoản tiết kiệm riêng của bạn) ----------
  String? depositToPiggy(int amount, {String note = 'Bỏ heo'}) {
    if (amount <= 0) return 'Số tiền không hợp lệ.';
    piggyBalance += amount;
    piggyTxns.add(PiggyTxn(
      id: newId(),
      type: 'deposit',
      amount: amount,
      source: 'manual',
      note: note,
      timestamp: DateTime.now().toUtc(),
    ));
    mascotTick++;
    _commit();
    return null;
  }

  // ---------- Thử thách ngẫu nhiên → thẳng vào Hũ ----------
  String? rollChallenge() {
    if (rolledToday) return 'Hôm nay bạn đã quay rồi. Mai quay tiếp nhé!';
    challengeAmount = kRollOptions[Random().nextInt(kRollOptions.length)];
    challengeId = newId();
    challengeDay = VnTime.dayKey();
    challengeConfirmed = false;
    _commit();
    return null;
  }

  /// Xác nhận thử thách: cộng ĐÚNG số tiền đã random vào Hũ, không yêu cầu
  /// nhập lại. Có khóa [_busy]/[challengeConfirmed] để không cộng trùng
  /// nếu user bấm nút nhiều lần.
  String? confirmChallenge() {
    if (!rolledToday || challengeConfirmed) return null;
    if (_busy) return null;
    _busy = true;
    piggyBalance += challengeAmount;
    piggyTxns.add(PiggyTxn(
      id: newId(),
      type: 'deposit',
      amount: challengeAmount,
      source: 'random_challenge',
      challengeId: challengeId,
      note: 'Thử thách ngẫu nhiên',
      timestamp: DateTime.now().toUtc(),
    ));
    challengeConfirmed = true;
    mascotTick++;
    _commit();
    _busy = false;
    return null;
  }
}

