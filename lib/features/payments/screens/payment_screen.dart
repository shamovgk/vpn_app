import 'dart:io' show Platform;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as webview_windows;
import 'package:vpn_app/ui/theme/app_colors.dart';
import 'package:vpn_app/ui/widgets/themed_background.dart';
import '../providers/payment_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  WebViewController? _mobileWebViewController;
  late final webview_windows.WebviewController _windowsController;
  StreamSubscription<String>? _winUrlSub;
  bool _windowsWebViewReady = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      _windowsController = webview_windows.WebviewController();
      _windowsController.initialize().then((_) {
        setState(() {
          _windowsWebViewReady = true;
        });
        final notifier = ref.read(paymentProvider.notifier);
        _winUrlSub = _windowsController.url.listen((currentUrl) {
          if (currentUrl.startsWith('https://sham.shetanvpn.ru/mainscreen')) {
            notifier.reset();
            Navigator.of(context).maybePop();
          }
        });
        final paymentUrl = ref.read(paymentProvider).paymentUrl;
        if (paymentUrl != null) {
          _windowsController.loadUrl(paymentUrl);
        }
      });
    }
  }

  @override
  void dispose() {
    _winUrlSub?.cancel();
    if (Platform.isWindows) {
      _windowsController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final state = ref.watch(paymentProvider);
    final notifier = ref.read(paymentProvider.notifier);
    final theme = Theme.of(context);

    Widget buildMethodSelection() {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...[
                {'title': 'Оплатить через карту', 'method': 'bank_card'},
                {'title': 'Оплатить через СБП', 'method': 'sbp'},
                {'title': 'Оплатить через СберПей', 'method': 'sberbank'},
              ].map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => notifier.fetchPaymentUrl(item['method']!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.bgLight,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 2,
                      textStyle: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 16, fontWeight: FontWeight.w500, color: colors.bgLight,
                      ),
                    ),
                    child: Text(item['title']!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 16, fontWeight: FontWeight.w500, color: colors.bgLight)),
                  ),
                ),
              )),
            ],
          ),
        ),
      );
    }

    Widget buildWebView() {
      final url = state.paymentUrl;
      if (url == null) {
        return Center(child: Text('Нет ссылки на оплату', style: TextStyle(color: colors.danger)));
      }
      if (Platform.isWindows) {
        if (!_windowsWebViewReady) {
          return const Center(child: CircularProgressIndicator());
        }
        _windowsController.loadUrl(url);
        return webview_windows.Webview(_windowsController);
      } else {
        _mobileWebViewController ??= WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (NavigationRequest request) {
                if (request.url.startsWith('https://sham.shetanvpn.ru/mainscreen')) {
                  notifier.reset();
                  Navigator.of(context).maybePop();
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(url));
        return WebViewWidget(controller: _mobileWebViewController!);
      }
    }

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textMuted),
            onPressed: () {
              notifier.reset();
              Navigator.of(context).maybePop();
            },
          ),
          title: Text(
            'Оплата подписки',
            style: theme.textTheme.headlineLarge?.copyWith(fontSize: 20, color: colors.text),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: state.loading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.error!, style: TextStyle(color: colors.danger)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: notifier.reset,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.bgLight,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: const Text('Выбрать другой способ'),
                        )
                      ],
                    ),
                  )
                : state.paymentUrl == null
                    ? buildMethodSelection()
                    : buildWebView(),
      ),
    );
  }
}
