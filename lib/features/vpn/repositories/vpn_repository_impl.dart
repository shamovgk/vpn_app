// lib/features/vpn/repositories/vpn_repository_impl.dart
import 'dart:async';
import 'dart:math' as math;
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

  static const String _tunnelName = 'vpn_app_tunnel';
  static const String _bundleId   = 'com.example.vpn_app';

  Future<void> _ensureInitialized() async {
    await _vpn.initialize(interfaceName: _tunnelName);
    await _clearTempFiles();
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

    const maxAttempts = 5;
    var backoff = const Duration(milliseconds: 300);
    final rnd = math.Random();

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await _vpn.start(
          serverAddress: cfg.endpoint,
          wgQuickConfig: wgQuick,
          providerBundleIdentifier: _bundleId,
        );
        return; // успех
      } catch (e) {
        if (_isMarkedForDeleteError(e) && attempt < maxAttempts) {
          // 1) Даём Windows закончить delete старого сервиса
          await _vpn.waitServiceDeleted(timeout: const Duration(seconds: 7));
          // 2) Джиттер, чтобы не биться ровно в одну и ту же фазу SCM
          final jitterMs = 100 + rnd.nextInt(150); // 100..250мс
          await Future.delayed(backoff + Duration(milliseconds: jitterMs));
          backoff = Duration(milliseconds: (backoff.inMilliseconds * 1.8).ceil());
          // 3) Следующий заход
          continue;
        }
        rethrow;
      }
    }
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

  bool _isMarkedForDeleteError(Object e) {
    final s = e.toString();
    return s.contains('1072') ||
           s.contains('ERROR_SERVICE_MARKED_FOR_DELETE') ||
           s.toLowerCase().contains('marked for delete') ||
           (s.toLowerCase().contains('sid') && s.contains('1072'));
  }
}
