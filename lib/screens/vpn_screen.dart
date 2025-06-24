import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vpn_app/providers/vpn_provider.dart';
import 'package:logger/logger.dart';
import 'package:gif/gif.dart';
import 'settings_screen.dart';

final logger = Logger();

class VpnScreen extends StatefulWidget {
  const VpnScreen({super.key});

  @override
  State<VpnScreen> createState() => _VpnScreenState();
}

class _VpnScreenState extends State<VpnScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[Center(child: _AnimationButton()), SettingsScreen()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: _pages,
              ),
            ),
            Container(
              padding: EdgeInsets.zero,
              color: Theme.of(context).scaffoldBackgroundColor.withAlpha(230),
              child: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
                  BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Theme.of(context).primaryColor,
                unselectedItemColor: const Color(0xFFABCF9C).withAlpha(150),
                onTap: _onItemTapped,
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimationButton extends StatefulWidget {
  @override
  __AnimationButtonState createState() => __AnimationButtonState();
}

class __AnimationButtonState extends State<_AnimationButton> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late GifController _controller;
  bool _isAnimating = false; // Флаг для управления анимацией

  @override
  void initState() {
    super.initState();
    _controller = GifController(vsync: this);
    _controller.reset(); // Инициализируем в начальном состоянии
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true; // Сохраняем состояние виджета

  Future<void> _handleTap() async {
    final vpnProvider = Provider.of<VpnProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (vpnProvider.isConnecting || _isAnimating) return;

    setState(() {
      _isAnimating = true; // Устанавливаем флаг анимации
    });

    try {
      // Запускаем анимацию и операцию параллельно
      if (vpnProvider.isConnected) {
        await Future.wait([
          _controller.reverse(), // Анимация назад
          vpnProvider.disconnect(), // Отключение VPN
        ]);
      } else {
        await Future.wait([
          _controller.forward(), // Анимация вперёд
          vpnProvider.connect(), // Подключение VPN
        ]);
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      setState(() {
        _isAnimating = false; // Сбрасываем флаг после завершения
      });
      _controller.stop(); // Останавливаем анимацию
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Обязательный вызов для AutomaticKeepAliveClientMixin
    return GestureDetector(
      onTap: _handleTap,
      child: SizedBox(
        width: 300,
        height: 300,
        child: Gif(
          image: const AssetImage('assets/vpn_animation.gif'),
          controller: _controller,
          autostart: Autostart.no, // Отключаем автозапуск
          placeholder: (context) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}