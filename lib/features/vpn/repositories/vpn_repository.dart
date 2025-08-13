// lib/features/vpn/repositories/vpn_repository.dart
import 'package:dio/dio.dart' show CancelToken;
import 'package:vpn_app/features/vpn/models/vpn_config.dart';

abstract class VpnRepository {
  Future<void> connect();
  Future<void> disconnect();
  Future<bool> isConnected();

  /// Можно отменять загрузку конфига (например, при уходе со спорта)
  Future<VpnConfig> fetchConfig({CancelToken? cancelToken});
}
