// lib/features/payments/widgets/payment_webview.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as webview_windows;

class PaymentWebView extends StatelessWidget {
  final String url;
  final String successPrefix;
  final String cancelPrefix;
  final VoidCallback onPaymentSuccess;
  final VoidCallback? onPaymentCancel;

  const PaymentWebView({
    super.key,
    required this.url,
    required this.successPrefix,
    required this.cancelPrefix,
    required this.onPaymentSuccess,
    this.onPaymentCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
      return _WindowsPaymentWebView(
        url: url,
        successPrefix: successPrefix,
        cancelPrefix: cancelPrefix,
        onPaymentSuccess: onPaymentSuccess,
        onPaymentCancel: onPaymentCancel,
      );
    } else {
      return _MobilePaymentWebView(
        url: url,
        successPrefix: successPrefix,
        cancelPrefix: cancelPrefix,
        onPaymentSuccess: onPaymentSuccess,
        onPaymentCancel: onPaymentCancel,
      );
    }
  }
}

// --- Mobile ---
class _MobilePaymentWebView extends StatefulWidget {
  final String url;
  final String successPrefix;
  final String cancelPrefix;
  final VoidCallback onPaymentSuccess;
  final VoidCallback? onPaymentCancel;

  const _MobilePaymentWebView({
    required this.url,
    required this.successPrefix,
    required this.cancelPrefix,
    required this.onPaymentSuccess,
    this.onPaymentCancel,
  });

  @override
  State<_MobilePaymentWebView> createState() => _MobilePaymentWebViewState();
}

class _MobilePaymentWebViewState extends State<_MobilePaymentWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final u = request.url;
            if (u.startsWith(widget.successPrefix)) {
              widget.onPaymentSuccess();
              return NavigationDecision.prevent;
            }
            if (u.startsWith(widget.cancelPrefix)) {
              if (widget.onPaymentCancel != null) widget.onPaymentCancel!();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}

// --- Windows ---
class _WindowsPaymentWebView extends StatefulWidget {
  final String url;
  final String successPrefix;
  final String cancelPrefix;
  final VoidCallback onPaymentSuccess;
  final VoidCallback? onPaymentCancel;

  const _WindowsPaymentWebView({
    required this.url,
    required this.successPrefix,
    required this.cancelPrefix,
    required this.onPaymentSuccess,
    this.onPaymentCancel,
  });

  @override
  State<_WindowsPaymentWebView> createState() => _WindowsPaymentWebViewState();
}

class _WindowsPaymentWebViewState extends State<_WindowsPaymentWebView> {
  late final webview_windows.WebviewController _controller;
  StreamSubscription<String>? _urlSub;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = webview_windows.WebviewController();
    _controller.initialize().then((_) {
      setState(() => _ready = true);
      _controller.loadUrl(widget.url);
      _urlSub = _controller.url.listen((u) {
        if (u.startsWith(widget.successPrefix)) {
          widget.onPaymentSuccess();
        } else if (u.startsWith(widget.cancelPrefix)) {
          if (widget.onPaymentCancel != null) widget.onPaymentCancel!();
        }
      });
    });
  }

  @override
  void dispose() {
    _urlSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Center(child: CircularProgressIndicator());
    return webview_windows.Webview(_controller);
  }
}
