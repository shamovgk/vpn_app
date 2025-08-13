// lib/features/devices/providers/device_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/core/cache/swr/swr_store.dart';

import '../../../core/api/api_service.dart';
import '../../../core/platform/device_id.dart';
import '../repositories/device_repository.dart';
import '../repositories/device_repository_impl.dart';
import '../usecases/fetch_devices_usecase.dart';
import '../usecases/refresh_devices_usecase.dart';
import '../usecases/add_current_device_usecase.dart';
import '../usecases/remove_device_usecase.dart';
import '../usecases/update_current_last_seen_usecase.dart';
import 'device_controller.dart';

export 'device_controller.dart';

/// Платформенная инфа текущего устройства (token/model/os)
final currentDeviceInfoProvider = FutureProvider<DevicePlatformInfo>((ref) async {
  return DeviceId.getCurrentDeviceInfo();
}, name: 'currentDeviceInfo');

/// Только стабильный токен текущего устройства
final currentDeviceTokenProvider = FutureProvider<String>((ref) async {
  return DeviceId.getDeviceToken();
}, name: 'currentDeviceToken');

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final api = ref.read(apiServiceProvider);
  final swr = ref.read(swrStoreProvider);
  return DeviceRepositoryImpl(api, swr);
}, name: 'deviceRepository');

final fetchDevicesUseCaseProvider = Provider((ref) => FetchDevicesUseCase(ref.read(deviceRepositoryProvider)), name: 'fetchDevicesUC');
final refreshDevicesUseCaseProvider = Provider((ref) => RefreshDevicesUseCase(ref.read(deviceRepositoryProvider)), name: 'refreshDevicesUC');
final addCurrentDeviceUseCaseProvider = Provider((ref) => AddCurrentDeviceUseCase(ref.read(deviceRepositoryProvider)), name: 'addCurrentDeviceUC');
final removeDeviceUseCaseProvider = Provider((ref) => RemoveDeviceUseCase(ref.read(deviceRepositoryProvider)), name: 'removeDeviceUC');
final updateCurrentLastSeenUseCaseProvider = Provider((ref) => UpdateCurrentLastSeenUseCase(ref.read(deviceRepositoryProvider)), name: 'updateLastSeenUC');

final deviceControllerProvider =
    StateNotifierProvider<DeviceController, DeviceState>((ref) {
  final ctrl = DeviceController(
    ref.read(fetchDevicesUseCaseProvider),
    ref.read(refreshDevicesUseCaseProvider),
    ref.read(addCurrentDeviceUseCaseProvider),
    ref.read(removeDeviceUseCaseProvider),
    ref.read(updateCurrentLastSeenUseCaseProvider),
  );
  // привязываем onDispose(cancel)
  ctrl.bind(ref);
  return ctrl;
}, name: 'deviceController');
