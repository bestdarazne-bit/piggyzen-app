import 'package:flutter/material.dart';
import 'models.dart';
import 'store.dart';
import 'theme.dart';
import 'vn_time.dart';
import 'widgets.dart';

class HomePage extends StatelessWidget {
  final AppStore store;
  const HomePage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset('assets/images/avatar.jpg', width: 34, height: 34, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('PiggyZen', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              Text(store.user.name, style: const TextStyle(fontSize: 12, color: kGrey)),
            ]),
          ]),
          actions: [
            IconButton(icon: const Icon(Icons.bar_chart_rounded), tooltip: 'Tổng kết hôm nay', onPressed: () => _showSummary(context)),
            IconButton(icon: const Icon(Icons.settings_outlined), tooltip: 'Cài đặt', onPressed: () => _showSettings(context)),
          ],
        ),
        body: PiggyBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _mascot(),
                const SizedBox(height: 18),
                _sectionLabel('💳 VÍ', kWalletBlue),
                const SizedBox(height: 8),
                _walletCard(context),
                const SizedBox(height: 10),
                _walletHistoryPreview(context),
                const SizedBox(height: 24),
                _sectionLabel('🐷 HŨ HEO ĐẤT', kHotPink),
                const SizedBox(height: 8),
                _piggyCard(context),
                const SizedBox(height: 16),
                _rollCard(context),
                const SizedBox(height: 10),
                _piggyHistoryPreview(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) => Row(children: [
        Container(width: 6, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color, letterSpacing: 0.3)),
      ]);

  // ---------- Mascot ----------
  Widget _mascot() {
    final angry = store.angry;
    final g = store.goal;
    String msg;
    if (angry) {
      msg = store.lastBlocked ? 'Hứ! Định tiêu quá tay hả? Heo không cho đâu! 😡' : 'Hôm nay bạn chi gần/vượt giới hạn Ví rồi đó! 😡';
    } else if (g == null) {
      msg = 'Tạo hũ mục tiêu để heo cùng bạn tiết kiệm nào! 🐖';
    } else if (store.goalDone) {
      msg = 'Hũ đã đầy! Bấm "Hoàn thành" để nhận thành quả nha! 🎉';
    } else {
      msg = 'Hũ đã đầy ${(store.goalProgress * 100).toStringAsFixed(0)}%! Cứ thế phát huy! 😊';
    }
    return Column(children: [
      PigMascot(angry: angry, bounceTick: store.mascotTick, celebrateTick: store.celebrateTick),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: angry ? const Color(0xFFFFE7E7) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: angry ? kDanger : kPink),
        ),
        child: Text(msg, textAlign: TextAlign.center, style: TextStyle(color: angry ? kDanger : kGrey, fontWeight: FontWeight.w600)),
      ),
    ]);
  }

  // ---------- VÍ ----------
  Widget _walletCard(BuildContext context) {
    final w = store.walletToday();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [kWalletBlue, Color(0xFF7DA6F2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: kWalletBlue.withAlpha(70), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Số dư Ví', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(fmt(store.walletBalance), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _walletStat('Nhận hôm nay', fmt(w.income))),
          Expanded(child: _walletStat('Chi hôm nay', fmt(w.expense))),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white.withAlpha(46), borderRadius: BorderRadius.circular(14)),
          child: Text('Hạn mức còn lại hôm nay: ${fmt(store.remainingDailyLimit)} / ${fmt(store.user.dailyLimit)}',
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: kWalletBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                minimumSize: const Size(0, 50),
              ),
              onPressed: () => _income(context),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Nạp tiền'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kDanger, minimumSize: const Size(0, 50)),
              onPressed: () => _spend(context),
              icon: const Icon(Icons.remove_circle_outline),
              label: const Text('Chi tiêu'),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _walletStat(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      ]);

  Widget _walletHistoryPreview(BuildContext context) {
    final list = store.walletTxns.reversed.take(4).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Giao dịch Ví gần đây', style: TextStyle(fontWeight: FontWeight.w800)),
          TextButton(onPressed: () => _fullHistory(context, wallet: true), child: const Text('Xem tất cả')),
        ]),
        if (list.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Chưa có giao dịch Ví nào.', style: TextStyle(color: kGrey))),
        for (final t in list) _walletTile(t),
      ]),
    );
  }

  Widget _walletTile(WalletTxn t) {
    final income = t.type == 'income';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Text(income ? '💰' : '💸', style: const TextStyle(fontSize: 22)),
      title: Text(t.note),
      subtitle: Text(VnTime.fmtDateTime(t.timestamp)),
      trailing: Text('${income ? '+' : '-'}${fmt(t.amount)}', style: TextStyle(color: income ? kSuccess : kDanger, fontWeight: FontWeight.bold)),
    );
  }

  // ---------- HŨ ----------
  Widget _piggyCard(BuildContext context) {
    final g = store.goal;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Số dư Hũ', style: TextStyle(color: kGrey)),
        const SizedBox(height: 2),
        Text(fmt(store.piggyBalance), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: kHotPink)),
        const SizedBox(height: 16),
        if (g == null) ...[
          const Text('Chưa có mục tiêu nào. Mỗi lúc chỉ được 1 mục tiêu.', style: TextStyle(color: kGrey)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: kHotPink, side: const BorderSide(color: kHotPink), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), minimumSize: const Size(0, 50)),
                onPressed: () => _createGoal(context),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Tạo mục tiêu'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(onPressed: () => _deposit(context), icon: const Icon(Icons.savings_outlined), label: const Text('Cất tiền')),
            ),
          ]),
        ] else ...[
          Text('🎯 ${g.name}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: store.goalProgress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 16, backgroundColor: kPink.withAlpha(60), color: kHotPink),
            ),
          ),
          const SizedBox(height: 8),
          Text('${fmt(store.piggyBalance)} / ${fmt(g.target)}  (${(store.goalProgress * 100).toStringAsFixed(0)}%)', style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(store.goalDone ? 'Đã đạt mục tiêu! 🎉' : 'Còn ${g.daysLeft(DateTime.now())} ngày', style: const TextStyle(color: kGrey)),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (!store.goalDone) ElevatedButton.icon(onPressed: () => _deposit(context), icon: const Icon(Icons.savings_outlined), label: const Text('Cất vào Hũ')),
            if (store.goalDone)
              ElevatedButton.icon(
                onPressed: () => store.completeGoal(),
                icon: const Icon(Icons.emoji_events_outlined),
                label: const Text('Hoàn thành'),
              ),
            TextButton(onPressed: () => _confirmDeleteGoal(context), child: const Text('Xóa mục tiêu', style: TextStyle(color: kDanger))),
          ]),
        ],
      ]),
    );
  }

  Widget _rollCard(BuildContext context) {
    Widget content;
    if (!store.rolledToday) {
      content = Column(children: [
        const Text('Chưa quay thử thách hôm nay', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ElevatedButton.icon(onPressed: () => _roll(context), icon: const Icon(Icons.casino_outlined), label: const Text('Quay thử thách 🎲')),
      ]);
    } else if (!store.challengeConfirmed) {
      content = Column(children: [
        Text('🐷 Cất ${fmt(store.challengeAmount)} vào Hũ', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kHotPink)),
        const SizedBox(height: 4),
        const Text('Không cần nhập lại số tiền — chỉ cần xác nhận.', style: TextStyle(color: kGrey, fontSize: 12.5)),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => _confirmRoll(context),
          icon: const Icon(Icons.check_circle_outline),
          label: Text('Xác nhận cất ${fmt(store.challengeAmount)}'),
        ),
      ]);
    } else {
      content = Text('✅ Đã cất ${fmt(store.challengeAmount)} vào Hũ hôm nay! Mai quay tiếp nhé.', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600));
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Column(children: [
        const Text('🎯 Thử thách ngẫu nhiên → Hũ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        content,
      ]),
    );
  }

  Widget _piggyHistoryPreview(BuildContext context) {
    final list = store.piggyTxns.reversed.take(4).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Lịch sử Hũ gần đây', style: TextStyle(fontWeight: FontWeight.w800)),
          TextButton(onPressed: () => _fullHistory(context, wallet: false), child: const Text('Xem tất cả')),
        ]),
        if (list.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Chưa có giao dịch Hũ nào.', style: TextStyle(color: kGrey))),
        for (final t in list) _piggyTile(t),
      ]),
    );
  }

  Widget _piggyTile(PiggyTxn t) {
    final deposit = t.type == 'deposit';
    final icon = t.source == 'random_challenge' ? '🎲' : '🐖';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Text(icon, style: const TextStyle(fontSize: 22)),
      title: Text(t.note.isEmpty ? (deposit ? 'Cất vào Hũ' : 'Rút khỏi Hũ') : t.note),
      subtitle: Text(VnTime.fmtDateTime(t.timestamp)),
      trailing: Text('${deposit ? '+' : '-'}${fmt(t.amount)}', style: TextStyle(color: deposit ? kSuccess : kDanger, fontWeight: FontWeight.bold)),
    );
  }

  // ---------- Dialogs / actions ----------
  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  Future<void> _alert(BuildContext context, String title, String msg, {bool danger = false}) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: danger ? const Color(0xFFFFEBEB) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(title, style: TextStyle(color: danger ? kDanger : kHotPink, fontWeight: FontWeight.bold)),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Heo hiểu rồi'))],
      ),
    );
  }

  Future<({int amount, String note})?> _amountForm(BuildContext context, {required String title, required String noteLabel}) {
    final amountCtl = TextEditingController();
    final noteCtl = TextEditingController();
    String? err;
    return showModalBottomSheet<({int amount, String note})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: kHotPink)),
            const SizedBox(height: 14),
            TextField(controller: amountCtl, autofocus: true, decoration: const InputDecoration(labelText: 'Số tiền (vd: 35k hoặc 35000)')),
            const SizedBox(height: 10),
            TextField(controller: noteCtl, decoration: InputDecoration(labelText: noteLabel)),
            if (err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(err!, style: const TextStyle(color: kDanger))),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                final a = parseMoney(amountCtl.text);
                if (a == null || a <= 0) {
                  setS(() => err = 'Nhập số tiền hợp lệ (vd: 35k, 35000).');
                  return;
                }
                Navigator.pop(ctx, (amount: a, note: noteCtl.text.trim()));
              },
              child: const Text('Xác nhận'),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _createGoal(BuildContext context) async {
    final name = TextEditingController();
    final target = TextEditingController();
    final days = TextEditingController();
    String? err;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎯 Tạo mục tiêu', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: kHotPink)),
            const SizedBox(height: 14),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Tên mục tiêu (vd: Mua tai nghe)')),
            const SizedBox(height: 10),
            TextField(controller: target, decoration: const InputDecoration(labelText: 'Số tiền cần đạt (vd: 500k)')),
            const SizedBox(height: 10),
            TextField(controller: days, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số ngày hoàn thành (vd: 30)')),
            if (err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(err!, style: const TextStyle(color: kDanger))),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                final tg = parseMoney(target.text);
                final d = int.tryParse(days.text.trim());
                if (name.text.trim().isEmpty || tg == null || tg <= 0 || d == null || d <= 0) {
                  setS(() => err = 'Vui lòng nhập đủ và đúng thông tin.');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Tạo mục tiêu'),
            ),
          ]),
        ),
      ),
    );
    if (ok != true) return;
    final e = store.createGoal(name.text, parseMoney(target.text)!, int.parse(days.text.trim()));
    if (context.mounted) _snack(context, e ?? 'Đã tạo mục tiêu "${name.text.trim()}" 🐖');
  }

  Future<void> _income(BuildContext context) async {
    final r = await _amountForm(context, title: '💰 Nạp tiền / Trợ cấp', noteLabel: 'Nguồn (ăn sáng, đi học, ...)');
    if (r == null) return;
    store.addIncome(r.amount, r.note);
    if (!context.mounted) return;
    final s = store.suggestSaving(r.amount);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Đã nhận ${fmt(r.amount)} vào Ví 🐖', style: const TextStyle(color: kHotPink, fontWeight: FontWeight.bold)),
        content: Text('Heo đề xuất:\n• Giữ lại tiêu ở Ví: ${fmt(s.keep)}\n• Cất riêng vào Hũ: ${fmt(s.save)}\n\n(Cất vào Hũ là một khoản tiết kiệm độc lập, không trừ vào số dư Ví của bạn.)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Để sau')),
          ElevatedButton(
            onPressed: () {
              Navigator.
