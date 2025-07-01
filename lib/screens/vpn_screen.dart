import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vpn_app/providers/vpn_provider.dart';
import 'package:logger/logger.dart';
import 'package:gif/gif.dart';
import 'package:vpn_app/screens/about_screen.dart';
import 'package:vpn_app/screens/settings_screen.dart';
import 'package:vpn_app/providers/auth_provider.dart';
import 'package:vpn_app/providers/theme_provider.dart';
import 'package:vpn_app/screens/login_screen.dart';
import 'package:vpn_app/screens/payment_screen.dart';

final logger = Logger();

class VpnScreen extends StatefulWidget {
  const VpnScreen({super.key});

  @override
  State<VpnScreen> createState() => VpnScreenState();
}

class VpnScreenState extends State<VpnScreen> {
  final GlobalKey<AnimationButtonState> _animationButtonKey = GlobalKey<AnimationButtonState>();
  static VpnScreenState? _instance;

  @override
  void initState() {
    super.initState();
    _instance = this;
  }

  @override
  void dispose() {
    _instance = null;
    super.dispose();
  }

  static GlobalKey<AnimationButtonState>? getAnimationButtonKey() => _instance?._animationButtonKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          title: Text(
            'UgbuganVPN',
            style: theme.textTheme.headlineLarge?.copyWith(fontSize: 20),
          ),
          centerTitle: true,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: theme.textTheme.bodyMedium?.color),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        drawer: Drawer(
          backgroundColor: theme.scaffoldBackgroundColor,
          width: 200,
          shape: LinearBorder(),
          child: SizedBox(
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: double.infinity,
                  color: theme.scaffoldBackgroundColor,
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                  child: Text(
                    textAlign: TextAlign.center,
                    authProvider.isAuthenticated ? authProvider.username ?? 'Пользователь' : 'Гость',
                    style: theme.textTheme.headlineLarge?.copyWith(fontSize: 20),
                  ),
                ),
                Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.payment, color: theme.textTheme.bodyMedium?.color),
                      title: Text('Подписаться', style: theme.textTheme.bodyMedium),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PaymentScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.settings, color: theme.textTheme.bodyMedium?.color),
                      title: Text('Настройки', style: theme.textTheme.bodyMedium),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.info, color: theme.textTheme.bodyMedium?.color),
                      title: Text('О нас', style: theme.textTheme.bodyMedium),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AboutScreen()),
                        );
                      },
                    ),
                  ],
                ),
                Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.brightness_6, color: theme.textTheme.bodyMedium?.color),
                      title: Text('Смена темы', style: theme.textTheme.bodyMedium),
                      onTap: () {
                        Navigator.pop(context);
                        themeProvider.toggleTheme();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Тема изменена на ${themeProvider.themeMode == ThemeMode.dark ? 'Тёмную' : 'Светлую'}'),
                            backgroundColor: Theme.of(context).extension<CustomColors>()!.success,
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.logout, color: theme.textTheme.bodyMedium?.color),
                      title: Text('Выйти', style: theme.textTheme.bodyMedium),
                      onTap: () {
                        Navigator.pop(context);
                        authProvider.logout();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (Route<dynamic> route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: AnimationButton(key: _animationButtonKey),
          ),
        ),
      ),
    );
  }
}

class AnimationButton extends StatefulWidget {
  const AnimationButton({super.key});

  @override
  AnimationButtonState createState() => AnimationButtonState();
}

class AnimationButtonState extends State<AnimationButton> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late GifController _controller;
  bool _isAnimating = false;
  bool _currentIsConnected = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = GifController(vsync: this);
    _controller.reset();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isAnimating && mounted) {
        setState(() {
          _isAnimating = false;
          _currentIsConnected = Provider.of<VpnProvider>(context, listen: false).isConnected;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized && mounted) {
        setState(() {
          _isInitialized = true;
          _currentIsConnected = Provider.of<VpnProvider>(context, listen: false).isConnected;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> handleTap() async {
    final vpnProvider = Provider.of<VpnProvider>(context, listen: false);
    if (vpnProvider.isConnecting || _isAnimating) return;

    setState(() {
      _isAnimating = true;
      _currentIsConnected = vpnProvider.isConnected;
    });

    _controller.reset();
    await _controller.forward();
    if (_currentIsConnected) {
      await vpnProvider.disconnect();
    } else {
      await vpnProvider.connect();
    }

    setState(() {
      _isAnimating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTap: handleTap,
      child: SizedBox(
        width: 300,
        height: 300,
        child: Gif(
          image: _currentIsConnected
              ? const AssetImage('assets/dark_theme_vpn_disconnect.gif')
              : const AssetImage('assets/dark_theme_vpn_connect.gif'),
          controller: _controller,
          autostart: Autostart.no,
          placeholder: (context) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}