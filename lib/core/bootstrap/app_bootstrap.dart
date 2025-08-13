// lib/core/bootstrap/app_bootstrap.dart
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data' show ByteData, Uint8List;
import 'dart:ui' as ui show instantiateImageCodec, PlatformDispatcher;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/core/providers/provider_observer.dart';
import 'package:window_manager/window_manager.dart';

import '../monitoring/error_reporter.dart';
import '../router/app_router.dart';
import '../../ui/theme/theme_provider.dart';
import '../platform/tray/tray_manager.dart';
import '../network/connectivity_provider.dart';
import '../../features/payments/deeplink/deeplink_handler.dart';

class AppBootstrap {
  static Future<void> run() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Desktop окно/трей
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.ensureInitialized();
      await windowManager.setPreventClose(true);
      trayHandler = TrayManagerHandler();
      windowManager.addListener(_MyWindowListener());
      const windowOptions = WindowOptions(center: true, skipTaskbar: false);
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
      });
    }

    // Мониторинг — пока логгером, но единая точка для будущего Sentry/Crashlytics
    installGlobalErrorHandlers(LogOnlyErrorReporter());

    // Запуск приложения
    runApp(
      ProviderScope(
        observers: [AppProviderObserver()],
        child: _Bootstrap(child: const _MyApp()),
      ),
    );
  }
}

/// Прелоад ассетов/инициализация на первом кадре
class _Bootstrap extends ConsumerStatefulWidget {
  final Widget child;
  const _Bootstrap({required this.child});

  @override
  ConsumerState<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends ConsumerState<_Bootstrap> {
  bool _assetsPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Прелоад ассетов
    if (!_assetsPrecached) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await _precacheInitial(
            backgroundPath: 'assets/background.png',
            animAssets: const [
              // DARK
              'assets/anim/dark/connect.gif',
              'assets/anim/dark/disconnect.gif',
              // LIGHT
              'assets/anim/light/connect.gif',
              'assets/anim/light/disconnect.gif',
            ],
          );
        } catch (_) {/* ignore */}
      });
      _assetsPrecached = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Включаем side-effects провайдеров (просто наблюдаем)
    ref.watch(swrRefreshOnReconnectProvider);      // SWR refresh при восстановлении сети
    ref.watch(paymentDeeplinkInitializerProvider); // слушатель диплинков оплаты
    return widget.child;
  }
}

class _MyApp extends ConsumerWidget {
  const _MyApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'UgbuganVPN',
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
      themeMode: theme.themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _AppScrollBehavior(),
    );
  }
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class _MyWindowListener extends WindowListener {
  @override
  void onWindowClose() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.hide();
    }
  }
}

const _kGifLogicalSize = Size(300, 300);

Future<void> _precacheInitial({
  required String backgroundPath,
  List<String> animAssets = const <String>[],
  Size gifLogicalTarget = _kGifLogicalSize,
}) async {
  await _precacheBackground(backgroundPath);

  if (animAssets.isNotEmpty) {
    await _precacheImages(animAssets, gifLogicalTarget: gifLogicalTarget);
  }
}

Future<void> _precacheBackground(String assetPath) async {
  try {
    final view = ui.PlatformDispatcher.instance.views.first;
    final widthPx = view.physicalSize.width.round();
    final heightPx = view.physicalSize.height.round();

    final provider = ResizeImage(
      AssetImage(assetPath),
      width: widthPx,
      height: heightPx,
    );

    await _warmUp(provider);
  } catch (_) {
    // игнорим: фон подгрузится лениво
  }
}

Future<void> _precacheImages(
  List<String> assets, {
  required Size gifLogicalTarget,
}) async {
  int? targetWidthPx;
  int? targetHeightPx;
  try {
    final view = ui.PlatformDispatcher.instance.views.first;
    final dpr = view.devicePixelRatio;
    targetWidthPx = (gifLogicalTarget.width * dpr).round();
    targetHeightPx = (gifLogicalTarget.height * dpr).round();
  } catch (_) {
    // если что-то не так с view — декодируем без таргетных размеров
  }

  for (final raw in assets) {
    final path = raw.trim().replaceAll(RegExp(r'^"+|"+$'), '');
    final isGif = path.toLowerCase().endsWith('.gif');

    ByteData? bytes;
    try {
      bytes = await rootBundle.load(path);
    } catch (_) {
      // если файла нет — пропустим; дальше fallback
    }

    try {
      if (isGif && bytes != null) {
        await _warmUpGifAllFrames(
          bytes.buffer.asUint8List(),
          targetWidthPx: targetWidthPx,
          targetHeightPx: targetHeightPx,
        );
      } else {
        await _warmUp(AssetImage(path));
      }
    } catch (_) {
      // игнорим отдельные сбои, чтобы не блокировать загрузку приложения
    }
  }
}

Future<void> _warmUp(ImageProvider provider) async {
  final stream = provider.resolve(const ImageConfiguration());
  final completer = Completer<void>();

  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (ImageInfo _, bool _) {
      if (!completer.isCompleted) completer.complete();
      stream.removeListener(listener);
    },
    onError: (Object _, StackTrace? _) {
      if (!completer.isCompleted) completer.complete();
      stream.removeListener(listener);
    },
  );

  stream.addListener(listener);
  await completer.future;
}

Future<void> _warmUpGifAllFrames(
  Uint8List bytes, {
  int? targetWidthPx,
  int? targetHeightPx,
}) async {
  final codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: targetWidthPx,
    targetHeight: targetHeightPx,
  );

  for (var i = 0; i < codec.frameCount; i++) {
    await codec.getNextFrame();
  }
}
