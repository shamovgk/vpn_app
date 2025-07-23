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

class _AnimationButtonState extends ConsumerState<AnimationButton>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late GifController _controller;
  bool _isAnimating = false;
  late bool _currentIsConnected;

  @override
  void initState() {
    super.initState();
    _currentIsConnected = widget.isConnected;
    _controller = GifController(vsync: this);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _isAnimating = false;
          _currentIsConnected = !_currentIsConnected;
          _controller.reset();
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant AnimationButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isAnimating && widget.isConnected != _currentIsConnected) {
      setState(() {
        _currentIsConnected = widget.isConnected;
        _controller.reset();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> handleTap() async {
    if (widget.isConnecting || _isAnimating || widget.onConnect == null) return;
    setState(() {
      _isAnimating = true;
    });
    _controller.reset();
    _controller.forward();
    try {
      await widget.onConnect?.call();
    } catch (_) {
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final gifAsset = _isAnimating
        ? (_currentIsConnected
            ? 'assets/dark_theme_vpn_disconnect.gif'
            : 'assets/dark_theme_vpn_connect.gif')
        : (_currentIsConnected
            ? 'assets/dark_theme_vpn_disconnect.gif'
            : 'assets/dark_theme_vpn_connect.gif');

    return GestureDetector(
      onTap: widget.onConnect != null && !_isAnimating && !widget.isConnecting
          ? handleTap
          : null,
      child: AbsorbPointer(
        absorbing: _isAnimating || widget.isConnecting || widget.onConnect == null,
        child: SizedBox(
          width: 300,
          height: 300,
          child: Gif(
            image: AssetImage(gifAsset),
            controller: _controller,
            autostart: Autostart.no,
            placeholder: (context) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
