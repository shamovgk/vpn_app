// lib/core/config/app_config.dart
class AppConfig {
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  /// Префиксы диплинков оплаты
  final String paymentSuccessPrefix;
  final String paymentCancelPrefix;

  const AppConfig({
    required this.baseUrl,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.paymentSuccessPrefix,
    required this.paymentCancelPrefix,
  });

  static const _kDefaultBaseUrl = 'https://sham.shetanvpn.ru';
  static const _kDefaultConnectMs = 15000;
  static const _kDefaultReceiveMs = 15000;

  static const _kDefaultPaySuccess = 'https://sham.shetanvpn.ru/payment-return';
  static const _kDefaultPayCancel  = 'https://sham.shetanvpn.ru/payment-return';

  static AppConfig fromEnv() {
    final baseUrl = const String.fromEnvironment('BASE_URL', defaultValue: _kDefaultBaseUrl);
    final connectMs = int.tryParse(
      const String.fromEnvironment('CONNECT_TIMEOUT_MS', defaultValue: '$_kDefaultConnectMs'),
    ) ?? _kDefaultConnectMs;
    final receiveMs = int.tryParse(
      const String.fromEnvironment('RECEIVE_TIMEOUT_MS', defaultValue: '$_kDefaultReceiveMs'),
    ) ?? _kDefaultReceiveMs;

    final paySuccess = const String.fromEnvironment('PAYMENT_SUCCESS_PREFIX', defaultValue: _kDefaultPaySuccess);
    final payCancel  = const String.fromEnvironment('PAYMENT_CANCEL_PREFIX',  defaultValue: _kDefaultPayCancel);

    return AppConfig(
      baseUrl: baseUrl,
      connectTimeout: Duration(milliseconds: connectMs),
      receiveTimeout: Duration(milliseconds: receiveMs),
      paymentSuccessPrefix: paySuccess,
      paymentCancelPrefix: payCancel,
    );
  }
}
