import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/login_screen.dart';
import 'providers/auth_provider.dart';
import 'services/tray_manager.dart';
import 'screens/vpn_screen.dart';
import 'providers/vpn_provider.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await windowManager.setPreventClose(true);
  
  trayHandler = TrayManagerHandler();
  windowManager.addListener(MyWindowListener());

  WindowOptions windowOptions = WindowOptions(
    center: true,
    skipTaskbar: false,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setTitle('TowerVPN');
    await windowManager.setMinimumSize(const Size(360, 640));
    await windowManager.setMaximumSize(const Size(360, 640));
    await windowManager.show();
    });

  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuthStatus()),
          ChangeNotifierProvider(create: (_) => VpnProvider()),
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
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'TowerVPN',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: Color(0xFF719EA6), fontSize: 24, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF719EA6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
        ),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) => authProvider.isAuthenticated ? const VpnScreen() : const LoginScreen(),
      ),
    );
  }
}
class MyWindowListener extends WindowListener {
  @override
  void onWindowClose() async {
    await windowManager.hide();
  }
}