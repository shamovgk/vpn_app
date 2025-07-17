import 'package:flutter/material.dart';
import 'package:vpn_app/providers/device_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/login_screen.dart';
import 'services/tray_manager.dart';
import 'screens/vpn_screen.dart';
import 'providers/vpn_provider.dart';
import 'providers/theme_provider.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final apiService = ApiService();

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
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService: apiService)),
        ChangeNotifierProvider(create: (_) => DeviceProvider(apiService: apiService)),
        ChangeNotifierProvider(create: (_) => VpnProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'UgbuganVPN',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: Consumer<AuthProvider>(
            builder: (context, authProvider, _) => 
              authProvider.isLoggedIn ? const VpnScreen() : const LoginScreen(),
          ),
        );
      },
    );
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
