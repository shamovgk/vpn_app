import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';

import 'ui/theme/theme_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/vpn/screens/vpn_screen.dart';
import 'tray_manager.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);

    trayHandler = TrayManagerHandler();
    windowManager.addListener(MyWindowListener());

    WindowOptions windowOptions = WindowOptions(
      center: true,
      skipTaskbar: false,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
    });
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider); // ThemeProvider
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'UgbuganVPN',
      theme: theme.lightTheme, // твой кастомный lightTheme
      darkTheme: theme.darkTheme, // твой кастомный darkTheme
      themeMode: theme.themeMode, // текущий режим (dark/light/system)
      home: const _EntryScreen(), // обертка для авторизации
      debugShowCheckedModeBanner: false,
    );
  }
}

// Этот виджет не пересобирает всю MaterialApp при изменении состояния авторизации!
class _EntryScreen extends ConsumerWidget {
  const _EntryScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return auth.isLoggedIn ? const VpnScreen() : const LoginScreen();
  }
}

class MyWindowListener extends WindowListener {
  @override
  void onWindowClose() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.hide();
    }
  }
}
