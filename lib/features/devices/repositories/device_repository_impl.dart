// lib/features/devices/repositories/device_repository_impl.dart
import 'dart:async';
import 'package:dio/dio.dart';

import 'package:vpn_app/core/cache/swr/swr_keys.dart';
import 'package:vpn_app/core/cache/swr/swr_store.dart';
import 'package:vpn_app/features/devices/mappers/device_mapper.dart';

import '../../../core/api/api_service.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/cache/disk_cache.dart';
import '../models/domain/device.dart';
import '../models/dto/device_dto.dart';
import 'device_repository.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final ApiService _api;
  late final SwrEntry<List<Device>> _devicesEntry;
  final Duration _ttl;

  DeviceRepositoryImpl(
    this._api,
    SwrStore swr, {
    Duration ttl = const Duration(minutes: 5),
  }) : _ttl = ttl {
    _devicesEntry = swr.register<List<Device>>(
      key: SwrKeys.devices,
      ttl: ttl,
      fetcher: () async => _fetchDevices(),
    );

    // Гидратируем из снапшота (не блокируя UI)
    unawaited(_hydrateFromSnapshot());
  }

  static const _getPath = '/devices/get-devices';
  static const _addPath = '/devices/add-device';
  static const _removePath = '/devices/remove-device';
  static const _seenPath = '/devices/update-last-seen';

  static List<Device> _fromListJson(List raw) {
    return raw
        .whereType<Map>()
        .map((e) => DeviceDto.fromJson(e.cast<String, dynamic>()))
        .map(deviceFromDto)
        .toList(growable: false);
  }

  static Future<List<Device>> _fromResponse(Response res) async {
    final status = res.statusCode ?? 0;
    if (status < 200 || status >= 300) throwFromResponse(res);
    final data = res.data;
    if (data is! List) {
      throw Exception('Некорректный формат ответа');
    }
    return _fromListJson(data);
  }

  Future<void> _hydrateFromSnapshot() async {
    final snap = await DiskCache.getJson<List>(SwrKeys.devices, ttl: _ttl);
    if (snap is List && snap.isNotEmpty) {
      final mapped = _fromListJson(snap);
      if (mapped.isNotEmpty) {
        _devicesEntry.setOptimistic(mapped);
      }
    }
  }

  Future<List<Device>> _fetchDevices({CancelToken? cancelToken}) async {
    final res = await _api.get(_getPath, cancelToken: cancelToken);
    // Сохраняем JSON-снапшот как есть
    if (res.data is List) {
      unawaited(DiskCache.putJson(SwrKeys.devices, res.data));
    }
    return _fromResponse(res);
  }

  @override
  Future<List<Device>> getDevices({bool forceRefresh = false, CancelToken? cancelToken}) async {
    if (forceRefresh || !_devicesEntry.hasValue) {
      final list = await _fetchDevices(cancelToken: cancelToken);
      _devicesEntry.setOptimistic(list);
      unawaited(_devicesEntry.revalidateIfNeeded());
      return list;
    }
    return _devicesEntry.get(forceRefresh: false);
  }

  @override
  Future<List<Device>> refresh({CancelToken? cancelToken}) async {
    final list = await _fetchDevices(cancelToken: cancelToken);
    _devicesEntry.setOptimistic(list);
    return list;
  }

  @override
  Future<void> addDevice({required String token, required String model, required String os, CancelToken? cancelToken}) async {
    final res = await _api.post(_addPath,
        data: {'device_token': token, 'device_model': model, 'device_os': os},
        cancelToken: cancelToken);
    final status = res.statusCode ?? 0;
    if (status < 200 || status >= 300) throwFromResponse(res);
    _devicesEntry.touch();
    unawaited(_devicesEntry.revalidateIfNeeded());
  }

  @override
  Future<void> removeDevice(String token, {CancelToken? cancelToken}) async {
    final prev = _devicesEntry.value;
    if (prev != null) {
      final updated = prev.where((d) => d.token != token).toList(growable: false);
      _devicesEntry.setOptimistic(updated);
    }
    try {
      final res = await _api.post(_removePath, data: {'device_token': token}, cancelToken: cancelToken);
      final status = res.statusCode ?? 0;
      if (status < 200 || status >= 300) throwFromResponse(res);
      unawaited(_devicesEntry.refresh());
    } catch (e) {
      if (prev != null) _devicesEntry.setOptimistic(prev);
      rethrow;
    }
  }

  @override
  Future<void> updateLastSeen(String token, {CancelToken? cancelToken}) async {
    final res = await _api.post(_seenPath, data: {'device_token': token}, cancelToken: cancelToken);
    final status = res.statusCode ?? 0;
    if (status < 200 || status >= 300) throwFromResponse(res);
    _devicesEntry.touch();
  }
}

