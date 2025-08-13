// lib/features/vpn/repositories/vpn_repository_impl.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vpn_app/features/vpn/mappers/vpn_mapper.dart';
import 'package:vpn_app/features/vpn/models/dto/vpn_config_dto.dart';
import 'package:vpn_app/features/vpn/models/vpn_config.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';

import '../../../core/api/api_service.dart';
import '../../../core/errors/error_mapper.dart';
import '../platform/vpn_channel.dart';
import '../platform/vpn_isolates.dart';
import '../platform/vpn_permissions.dart';
import 'vpn_repository.dart';

class VpnRepositoryImpl implements VpnRepository {
  VpnRepositoryImpl(this._api);

  final ApiService _api;

  final VpnChannel _vpn = VpnChannel();
  Completer<void>? _initC;

  static const String _tunnelName = 'vpn_app_tunnel';
  static const String _bundleId   = 'com.example.vpn_app';

  Future<void> _ensureInitialized() async {
    if (_initC != null && _initC!.isCompleted) return;
    _initC ??= Completer<void>();
    try {
      await _vpn.initialize(interfaceName: _tunnelName);
      await _clearTempFiles();
      _initC?.complete();
    } catch (e) {
      _initC?.completeError(e);
      rethrow;
    }
  }

  Future<void> _clearTempFiles() async {
    try {
      final tmp = await getTemporaryDirectory();
      final entries = tmp.listSync().where((f) => f.path.contains('wg_'));
      for (final f in entries) {
        try { await f.delete(); } catch (_) {}
      }
    } catch (_) {}
  }

  @override
  Future<VpnConfig> fetchConfig({CancelToken? cancelToken}) async {
    try {
      final res = await _api.get('/vpn/get-vpn-config', cancelToken: cancelToken);
      final code = res.statusCode ?? 0;
      if (code < 200 || code >= 300) throwFromResponse(res);
      final map = (res.data as Map).cast<String, dynamic>();
      final dto = VpnConfigDto.fromJson(map);
      return vpnConfigFromDto(dto);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> connect() async {
    await _ensureInitialized();
    final ok = await ensureVpnPermission();
    if (!ok) throw Exception('VPN permission denied');

    await _clearTempFiles();

    final cfg = await fetchConfig();
    await validateConfigIsolate(cfg);
    final wgQuick = await buildWgQuickIsolate(cfg);

    await _vpn.start(
      serverAddress: cfg.endpoint,
      wgQuickConfig: wgQuick,
      providerBundleIdentifier: _bundleId,
    );
  }

  @override
  Future<void> disconnect() async {
    await _vpn.stop();
  }

  @override
  Future<bool> isConnected() async {
    final s = await _vpn.stage();
    return s == VpnStage.connected;
  }
}
