import 'package:flutter/material.dart';
import 'package:vpn_app/ui/theme/app_colors.dart';
import 'package:vpn_app/features/payments/widgets/payment_webview.dart';
import 'package:vpn_app/ui/widgets/app_custom_appbar.dart';

class PaymentWebViewScreen extends StatelessWidget {
  final String url;
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;

  const PaymentWebViewScreen({
    super.key,
    required this.url,
    required this.onSuccess,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
  
    return Scaffold(
      backgroundColor: colors.bgLight,
      appBar: AppCustomAppBar(
        title: 'Оплата',
        leading: IconButton(
          icon: Icon(Icons.close, color: colors.textMuted),
          onPressed: () {
            if (onCancel != null) onCancel!();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: PaymentWebView(
        url: url,
        onPaymentSuccess: () {
          onSuccess();
          Navigator.of(context).pop();
        },
        onPaymentCancel: onCancel != null
            ? () {
                onCancel!();
                Navigator.of(context).pop();
              }
            : null,
      ),
    );
  }
}
