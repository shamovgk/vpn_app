// lib/features/payments/screens/payment_webview_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';
import 'package:vpn_app/features/payments/widgets/payment_webview.dart';
import 'package:vpn_app/ui/widgets/app_custom_appbar.dart';

class PaymentWebViewArgs {
  final String url;
  final String successPrefix;
  final String cancelPrefix;
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;
  const PaymentWebViewArgs({
    required this.url,
    required this.successPrefix,
    required this.cancelPrefix,
    required this.onSuccess,
    this.onCancel,
  });
}

class PaymentWebViewScreen extends StatelessWidget {
  final String url;
  final String successPrefix;
  final String cancelPrefix;
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;

  const PaymentWebViewScreen({
    super.key,
    required this.url,
    required this.successPrefix,
    required this.cancelPrefix,
    required this.onSuccess,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bgLight,
      appBar: AppCustomAppBar(
        title: 'Оплата',
        leading: IconButton(
          icon: Icon(Icons.close, color: c.textMuted),
          onPressed: () {
            if (onCancel != null) onCancel!();
            context.pop();
          },
        ),
      ),
      body: PaymentWebView(
        url: url,
        successPrefix: successPrefix,
        cancelPrefix: cancelPrefix,
        onPaymentSuccess: () {
          context.pop();
          onSuccess();
        },
        onPaymentCancel: onCancel != null
            ? () {
                context.pop();
                onCancel!();
              }
            : null,
      ),
    );
  }
}

