String fmt(int v) {
  final s = v.abs().toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '${v < 0 ? '-' : ''}${b}đ';
}

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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

class Goal {
  String name;
  int target;
  int days;
  int saved;
  DateTime createdAt;

  Goal({
    required this.name,
    required this.target,
    required this.days,
    this.saved = 0,
    required this.createdAt,
  });

  double get progress => target == 0 ? 0 : (saved / target).clamp(0.0, 1.0).toDouble();
  bool get done => saved >= target;

  int get daysLeft {
    final end = createdAt.add(Duration(days: days));
    final d = end.difference(DateTime.now()).inDays + 1;
    return d < 0 ? 0 : d;
  }

  int get dailyNeeded {
    final remain = target - saved;
    if (remain <= 0) return 0;
    final d = daysLeft == 0 ? 1 : daysLeft;
    return (remain / d).ceil();
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'target': target,
        'days': days,
        'saved': saved,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Goal.fromJson(Map<String, dynamic> m) => Goal(
        name: m['name'] as String,
        target: m['target'] as int,
        days: m['days'] as int,
        saved: (m['saved'] as int?) ?? 0,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}

/// type: income | spend | save | refund | goal_done
class Txn {
  final String type;
  final int amount;
  final String note;
  final DateTime time;

  Txn({required this.type, required this.amount, required this.note, required this.time});

  Map<String, dynamic> toJson() => {
        'type': type,
        'amount': amount,
        'note': note,
        'time': time.toIso8601String(),
      };

  factory Txn.fromJson(Map<String, dynamic> m) => Txn(
        type: m['type'] as String,
        amount: m['amount'] as int,
        note: (m['note'] as String?) ?? '',
        time: DateTime.parse(m['time'] as String),
      );
}
