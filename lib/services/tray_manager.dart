import 'package:tray_manager/tray_manager.dart' as tray;
import 'package:vpn_app/main.dart';
import 'package:vpn_app/screens/vpn_screen.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vpn_provider.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class TrayManagerHandler with tray.TrayListener {
  TrayManagerHandler() {
    _initializeTray();
  }

  bool _isInitialized = false;

  Future<void> _initializeTray() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await tray.TrayManager.instance.setIcon('assets/tray_icon_disconnect.ico');
    tray.TrayManager.instance.addListener(this);
  }

  Future<void> updateTrayIconAndMenu() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final vpnProvider = Provider.of<VpnProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final menu = tray.Menu(
      items: [
        tray.MenuItem(key: 'show_window', label: 'Show Window'),
        tray.MenuItem.separator(),
        tray.MenuItem(
          key: 'connect',
          label: 'Connect',
          disabled: !authProvider.isAuthenticated || vpnProvider.isConnected || vpnProvider.isConnecting,
        ),
        tray.MenuItem(
          key: 'disconnect',
          label: 'Disconnect',
          disabled: !authProvider.isAuthenticated || !vpnProvider.isConnected,
        ),
        tray.MenuItem.separator(),
        tray.MenuItem(key: 'exit', label: 'Exit App'),
      ],
    );
    await tray.TrayManager.instance.setContextMenu(menu);
    final iconPath = vpnProvider.isConnected
        ? 'assets/tray_icon_connect.ico'
        : 'assets/tray_icon_disconnect.ico';
    await tray.TrayManager.instance.setIcon(iconPath);
  }

  @override
  void onTrayIconRightMouseDown() {
    updateTrayIconAndMenu();
    tray.TrayManager.instance.popUpContextMenu();
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
  }

  @override
  void onTrayMenuItemClick(tray.MenuItem menuItem) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final vpnProvider = Provider.of<VpnProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final animationButtonKey = VpnScreenState.getAnimationButtonKey();
    final animationButtonState = animationButtonKey?.currentState;

    switch (menuItem.key) {
      case 'show_window':
        windowManager.show();
        break;
      case 'connect':
        if (!authProvider.isAuthenticated) {
          logger.w('Cannot connect: Not authenticated');
          return;
        }
        if (vpnProvider.isConnected || vpnProvider.isConnecting) {
          logger.w('Cannot connect: Already connected or connecting');
          return;
        }
        animationButtonState?.handleTap();
        break;
      case 'disconnect':
        animationButtonState?.handleTap();
        break;
      case 'exit':
        vpnProvider.disconnect().then((_) => logger.i('VPN disconnected from tray')).catchError((e) => logger.e('Disconnect error: $e'));
        tray.TrayManager.instance.destroy();
        windowManager.destroy();
        break;
    }
    logger.i('Menu item clicked: ${menuItem.key}');
  }

  void dispose() {
    tray.TrayManager.instance.removeListener(this);
    _isInitialized = false;
  }
}

late TrayManagerHandler trayHandler;