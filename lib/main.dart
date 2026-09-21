import 'package:flutter/material.dart';
import 'home_page.dart';
import 'notification_service.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

class PiggyZenApp extends StatelessWidget {
  final AppStore store;
  const PiggyZenApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PiggyZen',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: HomePage(store: store),
    );
  }
}
