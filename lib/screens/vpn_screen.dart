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
  bool _hasShownTrialNotification = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated && authProvider.trialEndDate != null && !_hasShownTrialNotification) {
      final trialEnd = DateTime.parse(authProvider.trialEndDate!);
      final daysLeft = trialEnd.difference(DateTime.now()).inDays;
      if (daysLeft > 0 && !authProvider.isPaid) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final customColors = Theme.of(context).extension<CustomColors>()!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Вам доступен пробный период в $daysLeft дней'),
                backgroundColor: customColors.info,
                duration: const Duration(seconds: 3),
              ),
            );
            _hasShownTrialNotification = true;
          }
        });
      } else if (!authProvider.isPaid && trialEnd.isBefore(DateTime.now())) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final customColors = Theme.of(context).extension<CustomColors>()!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Срок действия пробного периода истёк, оплатите VPN'),
                backgroundColor: customColors.warning,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'Оплатить',
                  textColor: customColors.success,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PaymentScreen()),
                    ).then((_) {
                      setState(() {});
                    });
                  },
                ),
              ),
            );
            _hasShownTrialNotification = true;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        image: const DecorationImage(
          image: AssetImage('assets/background.png'),
          fit: BoxFit.fitWidth,
        ),
      ),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent, 
            elevation: 0, 
            title: Text(
              'UgbuganVPN',
              style: theme.textTheme.headlineLarge?.copyWith(fontSize: 20),
            ),
            centerTitle: true,
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: theme.textTheme.headlineLarge?.color),
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
                          ).then((_) {
                            setState(() {});
                          });
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
                          final customColors = Theme.of(context).extension<CustomColors>()!;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Тема изменена на ${themeProvider.themeMode == ThemeMode.dark ? 'Тёмную' : 'Светлую'}'),
                              backgroundColor: customColors.success,
                              duration: const Duration(seconds: 3),
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
                          final customColors = Theme.of(context).extension<CustomColors>()!;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Logged out successfully'),
                              backgroundColor: customColors.success,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (Route<dynamic> route) => false,
                            );
                          }
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
    if (vpnProvider.isConnecting || _isAnimating || !vpnProvider.isConnectionAllowed()) return;

    setState(() {
      _isAnimating = true;
      _currentIsConnected = vpnProvider.isConnected;
    });

    _controller.reset();
    await _controller.forward();
    try {
      if (_currentIsConnected) {
        await vpnProvider.disconnect();
      } else {
        await vpnProvider.connect();
      }
    } catch (e) {
      if (!mounted) return;
      final customColors = Theme.of(context).extension<CustomColors>()!;
      if (e.toString().contains('Срок действия пробного периода истёк')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Срок действия пробного периода истёк'),
            backgroundColor: customColors.warning,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (e.toString().contains('Подключение заблокировано')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Оплатите подписку для подключения'),
            backgroundColor: customColors.warning,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка подключения: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      logger.e('VPN operation error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAnimating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final vpnProvider = Provider.of<VpnProvider>(context, listen: false);
    return GestureDetector(
      onTap: vpnProvider.isConnectionAllowed() ? handleTap : null,
      child: AbsorbPointer(
        absorbing: !vpnProvider.isConnectionAllowed(),
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
      ),
    );
  }
}