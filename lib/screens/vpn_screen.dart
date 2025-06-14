import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:window_size/window_size.dart' as window_size;
import 'dart:io' show Platform; // Импорт для проверки платформы
import '../providers/vpn_provider.dart';
import 'settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VpnScreen(),
    );
  }
}

class VpnScreen extends StatefulWidget {
  const VpnScreen({super.key});

  @override
  State<VpnScreen> createState() => _VpnScreenState();
}

class _VpnScreenState extends State<VpnScreen> {
  int _selectedIndex = 0; // Индекс активной страницы

  static final List<Widget> _pages = <Widget>[
    _HomeContent(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    // Установка размера окна при запуске для десктопных платформ
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      window_size.setWindowMinSize(const Size(400, 800)); // Минимальные размеры
      window_size.setWindowMaxSize(const Size(500, 900)); // Максимальные размеры
      window_size.setWindowFrame(Rect.fromLTWH(0, 0, 400, 800)); // Начальный размер
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF142F1F), // Тёмный фон #142F1F
      body: Center(
        child: SizedBox(
          width: 360, // Типичная ширина телефона
          height: 640, // Типичная высота телефона
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Центральный контент
              Expanded(
                child: _pages[_selectedIndex],
              ),
              // Нижняя панель навигации
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: Color(0xFF142F1F).withAlpha(230), // Полупрозрачный тёмный фон
                child: BottomNavigationBar(
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings),
                      label: '',
                    ),
                  ],
                  currentIndex: _selectedIndex,
                  selectedItemColor: Color(0xFF719EA6), // #719EA6 для активной иконки
                  unselectedItemColor: Color(0xFFABCF9C).withAlpha(150), // #ABCF9C для неактивных
                  onTap: _onItemTapped,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Содержимое главной страницы с плейсхолдером и кнопкой
class _HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vpnProvider = Provider.of<VpnProvider>(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Плейсхолдер вместо анимации
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation,
              child: child,
            ),
          ),
          child: vpnProvider.isConnecting
              ? Container(
                  key: const ValueKey('connecting'),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SpinKitCircle(color: Color(0xFF719EA6), size: 50), // Индикатор
                      const SizedBox(height: 10),
                      Text(
                        'Подключение... (Плейсхолдер)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF719EA6), // #719EA6
                        ),
                      ),
                    ],
                  ),
                )
              : Text(
                  vpnProvider.isConnected ? 'Подключено' : 'Отключено',
                  key: ValueKey(vpnProvider.isConnected),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: vpnProvider.isConnected
                        ? Color(0xFFABCF9C) // #ABCF9C для подключённого
                        : Color(0xFF719EA6), // #719EA6 для отключённого
                  ),
                ),
        ),
        const SizedBox(height: 40),
        // Кнопка Connect/Disconnect
        SizedBox(
          width: 200,
          height: 48,
          child: ElevatedButton(
            onPressed: vpnProvider.isConnecting
                ? null
                : () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    Future<void> handleVpnAction() async {
                      if (vpnProvider.isConnected) {
                        await vpnProvider.disconnect();
                      } else {
                        await vpnProvider.connect();
                      }
                    }

                    try {
                      await handleVpnAction();
                    } catch (e) {
                      if (context.mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Ошибка: $e')),
                        );
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: vpnProvider.isConnected
                  ? Colors.red
                  : Color(0xFF719EA6), // #719EA6 для Connect
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 5,
            ),
            child: vpnProvider.isConnecting
                ? SpinKitCircle(color: Colors.white, size: 24)
                : Text(
                    vpnProvider.isConnected ? 'Отключить' : 'Подключить',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}