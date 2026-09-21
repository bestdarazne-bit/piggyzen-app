import 'package:flutter/material.dart';
import 'models.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

class HomePage extends StatelessWidget {
  final AppStore store;
  const HomePage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/avatar.jpg', width: 32, height: 32),
            ),
            const SizedBox(width: 8),
            const Text('PiggyZen', style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          actions: [
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded),
              tooltip: 'Tổng kết hôm nay',
              onPressed: () => _showSummary(context),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _mascot(),
            const SizedBox(height: 16),
            _walletCard(),
            const SizedBox(height: 16),
            _goalCard(context),
            const SizedBox(height: 16),
            _actions(context),
            const SizedBox(height: 16),
            _rollCard(context),
            const SizedBox(height: 16),
            _history(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---------- UI blocks ----------
  BoxDecoration _card({Color color = Colors.white}) => BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: kPink.withAlpha(90), blurRadius: 14, offset: const Offset(0, 6))],
      );

  Widget _mascot() {
    final angry = store.angry;
    final g = store.goal;
    String msg;
    if (angry) {
      msg = store.lastBlocked
          ? 'Hứ! Định tiêu quá tay hả? Heo không cho đâu! 😡'
          : 'Hôm nay bạn tiêu quá tay rồi đó! Heo đang giận! 😡';
    } else if (g == null) {
      msg = 'Tạo hũ mục tiêu đầu tiên để heo cùng bạn tiết kiệm nào! 🐖';
    } else if (g.done) {
      msg = 'Hũ đã đầy! Bấm "Hoàn thành" để nhận thành quả nha! 🎉';
    } else {
      msg = 'Hũ đã đầy ${(g.progress * 100).toStringAsFixed(0)}%! Giỏi lắm, cứ thế phát huy! 😊';
    }
    return Column(children: [
      PigMascot(angry: angry, bounceTick: store.bounceTick),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: angry ? const Color(0xFFFFE0E0) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: angry ? kDanger : kPink),
        ),
        child: Text(msg, textAlign: TextAlign.center, style: TextStyle(color: angry ? kDanger : kGrey, fontWeight: FontWeight.w600)),
      ),
    ]);
  }

  Widget _walletCard() {
    final t = store.today();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [kPink, kHotPink], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: kHotPink.withAlpha(90), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Ví hiện tại', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(fmt(store.wallet), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(spacing: 14, children: [
          Text('Nhận: ${fmt(t.income)}', style: const TextStyle(color: Colors.white)),
          Text('Chi: ${fmt(t.spent)}', style: const TextStyle(color: Colors.white)),
          Text('Cất hũ: ${fmt(t.saved)}', style: const TextStyle(color: Colors.white)),
        ]),
      ]),
    );
  }

  Widget _goalCard(BuildContext context) {
    final g = store.goal;
    if (g == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: _card(),
        child: Column(children: [
          const Text('🏺 Chưa có hũ mục tiêu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Mỗi lúc chỉ được 1 hũ duy nhất.', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _createGoal(context),
            icon: const Icon(Icons.add),
            label: const Text('Tạo hũ mục tiêu'),
          ),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('🏺 ${g.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kHotPink)),
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: g.progress),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOut,
          builder: (_, v, __) => ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(value: v, minHeight: 18, backgroundColor: kPink.withAlpha(70), color: kHotPink),
          ),
        ),
        const SizedBox(height: 8),
        Text('${fmt(g.saved)} / ${fmt(g.target)}  (${(g.progress * 100).toStringAsFixed(0)}%)', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(g.done
            ? 'Đã đạt mục tiêu! 🎉'
            : 'Còn ${g.daysLeft} ngày • cần cất ~${fmt(g.dailyNeeded)}/ngày'),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          if (!g.done)
            ElevatedButton.icon(
              onPressed: () => _manualSave(context),
              icon: const Icon(Icons.savings),
              label: const Text('Cất vào hũ'),
            ),
          if (g.done)
            ElevatedButton.icon(
              onPressed: () {
                store.completeGoal();
                showCoinDrop(context);
              },
              icon: const Icon(Icons.emoji_events),
              label: const Text('Hoàn thành hũ'),
            ),
          TextButton(onPressed: () => _confirmDelete(context), child: const Text('Xóa hũ', style: TextStyle(color: kDanger))),
        ]),
      ]),
    );
  }

  Widget _actions(BuildContext context) {
    return Row(children: [
      Expanded(child: ElevatedButton.icon(onPressed: () => _income(context), icon: const Icon(Icons.add_circle_outline), label: const Text('Nạp tiền'))),
      const SizedBox(width: 12),
      Expanded(child: ElevatedButton.icon(onPressed: () => _spend(context), icon: const Icon(Icons.remove_circle_outline), label: const Text('Chi tiêu'))),
    ]);
  }

  Widget _rollCard(BuildContext context) {
    Widget content;
    if (!store.rolledToday) {
      content = Column(children: [
        const Text('Chưa quay thử thách hôm nay', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ElevatedButton.icon(onPressed: () => _roll(context), icon: const Icon(Icons.casino), label: const Text('Quay thử thách 🎲')),
      ]);
    } else {
      content = Column(children: [
        Text('Hôm nay bỏ heo ${fmt(store.rollAmount)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kHotPink)),
        const SizedBox(height: 10),
        store.rollDone
            ? const Text('✅ Đã hoàn thành! Ngày mai quay tiếp nhé.')
            : ElevatedButton.icon(onPressed: () => _confirmRoll(context), icon: const Icon(Icons.check_circle), label: const Text('Đã bỏ heo')),
      ]);
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _card(),
      child: Column(children: [
        const Text('🎯 Thử thách ngẫu nhiên', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        content,
      ]),
    );
  }

  Widget _history() {
    final list = store.txns.reversed.take(15).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🧾 Giao dịch gần đây', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (list.isEmpty) const Text('Chưa có giao dịch nào.'),
        for (final t in list) _txnTile(t),
      ]),
    );
  }

  Widget _txnTile(Txn t) {
    final icons = {'income': '💰', 'spend': '💸', 'save': '🐖', 'refund': '↩️', 'goal_done': '🎉'};
    final plus = t.type == 'income' || t.type == 'refund';
    final sign = t.type == 'goal_done' ? '' : (plus ? '+' : '-');
    final color = plus ? Colors.green.shade600 : (t.type == 'spend' ? kDanger : kHotPink);
    final hh = t.time.hour.toString().padLeft(2, '0');
    final mm = t.time.minute.toString().padLeft(2, '0');
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Text(icons[t.type] ?? '•', style: const TextStyle(fontSize: 24)),
      title: Text(t.note),
      subtitle: Text('${t.time.day}/${t.time.month} $hh:$mm'),
      trailing: Text('$sign${fmt(t.amount)}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  // ---------- Actions ----------
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
        title: Text(title, style: TextStyle(color: danger ? kDanger : kHotPink, fontWeight: FontWeight.bold)),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Heo hiểu rồi'))],
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
            const Text('🏺 Tạo hũ mục tiêu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kHotPink)),
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
              child: const Text('Tạo hũ'),
            ),
          ]),
        ),
      ),
    );
    if (ok != true) return;
    final e = store.createGoal(name.text, parseMoney(target.text)!, int.parse(days.text.trim()));
    if (context.mounted) _snack(context, e ?? 'Đã tạo hũ "${name.text.trim()}" 🐖');
  }

  Future<({int amount, String note})?> _amountForm(
    BuildContext context, {
    required String title,
    required String noteLabel,
  }) {
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
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kHotPink)),
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

  Future<void> _income(BuildContext context) async {
    final r = await _amountForm(context, title: '💰 Nạp tiền / Trợ cấp', noteLabel: 'Nguồn (ăn sáng, đi học, ...)');
    if (r == null) return;
    store.addIncome(r.amount, r.note);
    if (!context.mounted) return;
    final s = store.suggest(r.amount);
    final hasGoal = store.goal != null && !store.goal!.done;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Đã nhận ${fmt(r.amount)} 🐖', style: const TextStyle(color: kHotPink, fontWeight: FontWeight.bold)),
        content: Text(hasGoal
            ? 'Heo đề xuất:\n• Giữ lại tiêu: ${fmt(s.keep)}\n• Cất vào hũ NGAY: ${fmt(s.save)}'
            : 'Bạn chưa có hũ mục tiêu đang chạy. Hãy tạo hũ để heo giúp bạn cất tiền!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Để sau')),
          if (hasGoal)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                final e = store.saveToJar(s.save);
                if (e != null) {
                  _snack(context, e);
                } else {
                  showCoinDrop(context);
                }
              },
              child: Text('Cất ${fmt(s.save)}'),
            ),
        ],
      ),
    );
  }

  Future<void> _spend(BuildContext context) async {
    final r = await _amountForm(context, title: '💸 Chi tiêu', noteLabel: 'Ghi chú (vd: cơm trưa)');
    if (r == null) return;
    final res = store.spend(r.amount, r.note);
    if (!context.mounted) return;
    if (res.harsh) {
      await _alert(context, res.title, res.message, danger: true);
    } else {
      _snack(context, res.message);
    }
  }

  Future<void> _manualSave(BuildContext context) async {
    final r = await _amountForm(context, title: '🐖 Cất vào hũ', noteLabel: 'Ghi chú (không bắt buộc)');
    if (r == null) return;
    final e = store.saveToJar(r.amount, note: r.note.isEmpty ? 'Bỏ heo' : r.note);
    if (!context.mounted) return;
    if (e != null) {
      _snack(context, e);
    } else {
      showCoinDrop(context);
    }
  }

  void _roll(BuildContext context) {
    final e = store.roll();
    if (e != null) _snack(context, e);
  }

  void _confirmRoll(BuildContext context) {
    final e = store.confirmRoll();
    if (e != null) {
      _snack(context, e);
    } else {
      showCoinDrop(context);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final g = store.goal!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa hũ?'),
        content: Text('Xóa hũ "${g.name}"? ${g.saved > 0 ? 'Số tiền ${fmt(g.saved)} trong hũ sẽ trả về ví.' : ''}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Giữ lại')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: kDanger))),
        ],
      ),
    );
    if (ok == true) store.deleteGoal();
  }

  Future<void> _showSummary(BuildContext context) {
    final t = store.today();
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📊 Tổng kết hôm nay', style: TextStyle(color: kHotPink, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tổng nhận: ${fmt(t.income)}'),
          Text('Tổng chi: ${fmt(t.spent)}'),
          Text('Tổng tiết kiệm: ${fmt(t.saved)}'),
          const Divider(),
          Text('Số dư còn lại: ${fmt(store.wallet)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
      ),
    );
  }
}

