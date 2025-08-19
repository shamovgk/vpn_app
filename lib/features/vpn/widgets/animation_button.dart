// lib/features/vpn/widgets/animation_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gif/gif.dart';

class AnimationButton extends ConsumerStatefulWidget {
  final bool isConnected;
  final bool isConnecting;
  final Future<void> Function()? onConnect;

  const AnimationButton({
    super.key,
    required this.isConnected,
    required this.isConnecting,
    required this.onConnect,
  });

  @override
  ConsumerState<AnimationButton> createState() => _AnimationButtonState();
}

enum _Kind { connect, disconnect }

class _AnimationButtonState extends ConsumerState<AnimationButton>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // === НАСТРОЙКИ СКОРОСТИ ===
  // 1.0 — как есть; 1.2 — быстрее на 20%; 0.9 — медленнее на 10% и т.д.
  static const double kSpeed = 1.05;
  // Базовая длительность проигрыша гифки в мс. Увеличь, если хочется медленнее.
  static const int kNominalMs = 1500;

  // Контроллеры: light/dark × connect/disconnect
  late final GifController _ctlConnectLight;
  late final GifController _ctlDisconnectLight;
  late final GifController _ctlConnectDark;
  late final GifController _ctlDisconnectDark;

  bool _animating = false;
  _Kind? _animKind;
  bool? _animThemeIsDark;

  _Kind? _idleKind;
  bool? _idleThemeIsDark;
  bool _bootstrapped = false;
  bool? _pendingIdleThemeIsDark;

  // Прогрев ассетов GIF — уменьшает шанс FormatException у декодера
  Future<void> _precacheGifs() async {
    final assets = const [
      AssetImage('assets/anim/dark/connect.gif'),
      AssetImage('assets/anim/dark/disconnect.gif'),
      AssetImage('assets/anim/light/connect.gif'),
      AssetImage('assets/anim/light/disconnect.gif'),
    ];
    for (final a in assets) {
      try {
        await precacheImage(a, context);
      } catch (_) {}
    }
  }

  @override
  void initState() {
    super.initState();

    _ctlConnectLight = GifController(vsync: this);
    _ctlDisconnectLight = GifController(vsync: this);
    _ctlConnectDark = GifController(vsync: this);
    _ctlDisconnectDark = GifController(vsync: this);

    void attach(GifController c) {
      c.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          final active = _currentAnimatingController();
          if (identical(c, active)) {
            setState(() {
              _animating = false;
              _animKind = null;
              _animThemeIsDark = null;
              if (_pendingIdleThemeIsDark != null) {
                _idleThemeIsDark = _pendingIdleThemeIsDark!;
                _pendingIdleThemeIsDark = null;
              }
            });
          }
        }
      });
    }

    attach(_ctlConnectLight);
    attach(_ctlDisconnectLight);
    attach(_ctlConnectDark);
    attach(_ctlDisconnectDark);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheGifs();
    });
  }

  @override
  void dispose() {
    _ctlConnectLight.dispose();
    _ctlDisconnectLight.dispose();
    _ctlConnectDark.dispose();
    _ctlDisconnectDark.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  int _indexFor({required bool isDark, required _Kind kind}) {
    if (isDark) {
      return kind == _Kind.connect ? 0 : 1;
    } else {
      return kind == _Kind.connect ? 2 : 3;
    }
  }

  GifController _controllerFor({required bool isDark, required _Kind kind}) {
    if (isDark) {
      return kind == _Kind.connect ? _ctlConnectDark : _ctlDisconnectDark;
    } else {
      return kind == _Kind.connect ? _ctlConnectLight : _ctlDisconnectLight;
    }
  }

  GifController? _currentAnimatingController() {
    final kind = _animKind;
    final dark = _animThemeIsDark;
    if (kind == null || dark == null) return null;
    return _controllerFor(isDark: dark, kind: kind);
  }

  void _bootstrapIfNeeded(BuildContext context) {
    if (_bootstrapped) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _idleKind = widget.isConnected ? _Kind.disconnect : _Kind.connect;
    _idleThemeIsDark = isDark;
    _bootstrapped = true;
  }

  // Длительность с учётом множителя
  Duration get _playDuration =>
      Duration(milliseconds: (kNominalMs / kSpeed).round());

  Future<void> _onTap() async {
    if (widget.isConnecting || _animating || widget.onConnect == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kind = widget.isConnected ? _Kind.disconnect : _Kind.connect;

    setState(() {
      _animating = true;
      _animKind = kind;
      _animThemeIsDark = isDark;
      _idleKind = kind;
      _idleThemeIsDark = isDark;
    });

    final ctl = _controllerFor(isDark: isDark, kind: kind);

    // Запуск с нужной длительностью без обращения к protected duration.
    ctl.value = 0.0;
    // Не await — окончание поймает statusListener, чтобы не блокировать onConnect.
    // Если нужно дождаться окончания — добавь await.
    // ignore: discarded_futures
    ctl.animateTo(1.0, duration: _playDuration, curve: Curves.linear);

    try {
      await widget.onConnect?.call();
    } catch (_) {
      // Ошибку покажет родитель; анимацию не прерываем.
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _bootstrapIfNeeded(context);

    final isDarkNow = Theme.of(context).brightness == Brightness.dark;

    if (_bootstrapped) {
      if (!_animating) {
        if (_idleThemeIsDark != isDarkNow) {
          setState(() {
            _idleThemeIsDark = isDarkNow;
          });
        }
      } else {
        _pendingIdleThemeIsDark = isDarkNow;
      }
    }

    final showDark =
        _animating ? (_animThemeIsDark ?? isDarkNow) : (_idleThemeIsDark ?? isDarkNow);
    final showKind =
        _animating ? (_animKind ?? (_idleKind ?? _Kind.connect)) : (_idleKind ?? _Kind.connect);

    final activeIndex = _indexFor(isDark: showDark, kind: showKind);

    return GestureDetector(
      onTap: widget.onConnect != null && !_animating && !widget.isConnecting ? _onTap : null,
      child: AbsorbPointer(
        absorbing: _animating || widget.isConnecting || widget.onConnect == null,
        child: SizedBox(
          width: 300,
          height: 300,
          child: IndexedStack(
            index: activeIndex,
            children: [
              // dark/connect
              Gif(
                image: const AssetImage('assets/anim/dark/connect.gif'),
                autostart: Autostart.no,
                placeholder: (context) => const SizedBox.shrink(),
                controller: _ctlConnectDark,
              ),
              // dark/disconnect
              Gif(
                image: const AssetImage('assets/anim/dark/disconnect.gif'),
                autostart: Autostart.no,
                placeholder: (context) => const SizedBox.shrink(),
                controller: _ctlDisconnectDark,
              ),
              // light/connect
              Gif(
                image: const AssetImage('assets/anim/light/connect.gif'),
                autostart: Autostart.no,
                placeholder: (context) => const SizedBox.shrink(),
                controller: _ctlConnectLight,
              ),
              // light/disconnect
              Gif(
                image: const AssetImage('assets/anim/light/disconnect.gif'),
                autostart: Autostart.no,
                placeholder: (context) => const SizedBox.shrink(),
                controller: _ctlDisconnectLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
