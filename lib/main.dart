import 'package:flutter/material.dart';
import 'home_page.dart';
import 'notification_service.dart';
import 'store.dart';
import 'theme.dart';
import 'vn_time.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  VnTime.ensureInit();

  final store = AppStore();
  await store.load();
  try {
    await NotificationService.init();
    await NotificationService.scheduleAll(store.summaryBody());
  } catch (e) {
    debugPrint('Notification init error: $e');
  }
  runApp(PiggyZenApp(store: store));
}

class PiggyZenApp extends StatefulWidget {
  final AppStore store;
  const PiggyZenApp({super.key, required this.store});

  @override
  State<PiggyZenApp> createState() => _PiggyZenAppState();
}

/// Khi app resume (quay lại foreground), refresh dữ liệu MỘT LẦN — không
/// có timer/service nào chạy trong lúc app ở nền.
class _PiggyZenAppState extends State<PiggyZenApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.store.load().then((_) => widget.store.notifyListeners());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PiggyZen',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: HomePage(store: widget.store),
    );
  }
}
