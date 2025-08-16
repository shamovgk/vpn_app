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

  // Текущий анимирующий контроллер
  GifController? _currentAnimatingController() {
    final kind = _animKind;
    final dark = _animThemeIsDark;
    if (kind == null || dark == null) return null;
    return _controllerFor(isDark: dark, kind: kind);
  }

  // Инициализируем «стартовый» показ
  void _bootstrapIfNeeded(BuildContext context) {
    if (_bootstrapped) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // В покое показываем «что будет при следующем тапе»
    _idleKind = widget.isConnected ? _Kind.disconnect : _Kind.connect;
    _idleThemeIsDark = isDark;
    _bootstrapped = true;
  }

  Future<void> _onTap() async {
    if (widget.isConnecting || _animating || widget.onConnect == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kind = widget.isConnected ? _Kind.disconnect : _Kind.connect;

    setState(() {
      _animating = true;
      _animKind = kind;
      _animThemeIsDark = isDark;
      // После завершения останемся на последнем кадре этого же набора
      _idleKind = kind;
      _idleThemeIsDark = isDark;
    });

    final ctl = _controllerFor(isDark: isDark, kind: kind);
    ctl.reset();
    ctl.forward();

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

    // Во время анимации держим тему/направление зафиксированными.
    final showDark = _animating ? (_animThemeIsDark ?? isDarkNow) : (_idleThemeIsDark ?? isDarkNow);
    final showKind = _animating ? (_animKind ?? (_idleKind ?? _Kind.connect)) : (_idleKind ?? _Kind.connect);

    final activeIndex = _indexFor(isDark: showDark, kind: showKind);

    // NB: Все 4 Gif находятся в дереве постоянно — никакой подмены ассетов.
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
                controller: _ctlConnectDark,
                autostart: Autostart.no,
                placeholder: (context) => const SizedBox.shrink(),
              ),
              // dark/disconnect
              Gif(
                image: const AssetImage('assets/anim/dark/disconnect.gif'),
                controller: _ctlDisconnectDark,
                autostart: Autostart.no,
                placeholder: (context) => const SizedBox.shrink(),
              ),
              // light/connect
              Gif(
                image: const AssetImage('assets/anim/light/connect.gif'),
                controller: _ctlConnectLight,
                autostart: Autostart.no,
                placeholder: (context) => const SizedBox.shrink(),
              ),
              // light/disconnect
              Gif(
                image: const AssetImage('assets/anim/light/disconnect.gif'),
                controller: _ctlDisconnectLight,
                autostart: Autostart.no,
                placeholder: (context) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
