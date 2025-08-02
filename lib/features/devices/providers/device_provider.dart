import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_app/features/devices/services/device_id_helper.dart';
import '../../../core/api_service.dart';
import '../services/device_service.dart';
import '../models/device.dart';

// Провайдер DeviceService
final deviceServiceProvider = Provider<DeviceService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return DeviceService(apiService);
});

// FutureProvider для текущего device_token (используй для сравнения)
final currentDeviceTokenProvider = FutureProvider<String>((ref) async {
  return await getDeviceToken();
});

// State для управления списком устройств
class DeviceState {
  final List<Device> devices;
  final bool isLoading;
  final String? error;

  DeviceState({
    this.devices = const [],
    this.isLoading = false,
    this.error,
  });

  DeviceState copyWith({
    List<Device>? devices,
    bool? isLoading,
    String? error,
  }) =>
      DeviceState(
        devices: devices ?? this.devices,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// Notifier
class DeviceNotifier extends StateNotifier<DeviceState> {
  final DeviceService deviceService;

  DeviceNotifier(this.deviceService) : super(DeviceState());

  Future<void> fetchDevices() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final devices = await deviceService.fetchDevices();
      state = state.copyWith(devices: devices, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Удалить устройство по токену (например, из списка)
  Future<void> removeDevice(String deviceToken) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await deviceService.removeDevice(deviceToken);
      await fetchDevices();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Добавить текущее устройство (автоматически)
  Future<void> addCurrentDevice() async {
    try {
      final deviceToken = await getDeviceToken();
      final deviceInfo = DeviceInfoPlugin();
      String deviceModel = "Unknown", deviceOS = Platform.operatingSystem;

      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        deviceModel = android.model;
        deviceOS = 'Android';
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        deviceModel = ios.utsname.machine;
        deviceOS = 'iOS';
      } else if (Platform.isWindows) {
        final win = await deviceInfo.windowsInfo;
        deviceModel = win.computerName;
        deviceOS = 'Windows';
      } else if (Platform.isMacOS) {
        final mac = await deviceInfo.macOsInfo;
        deviceModel = mac.model;
        deviceOS = 'MacOS';
      }

      await deviceService.addDevice(
        deviceToken: deviceToken,
        deviceModel: deviceModel,
        deviceOS: deviceOS,
      );
      await fetchDevices();
    } catch (e) {
      // Если дубликат device_token (уже добавлен) — игнорируем ошибку
      if (!e.toString().contains("UNIQUE constraint failed")) {
        state = state.copyWith(error: e.toString());
      }
    }
  }
}

// Provider
final deviceProvider = StateNotifierProvider<DeviceNotifier, DeviceState>((ref) {
  final service = ref.watch(deviceServiceProvider);
  return DeviceNotifier(service);
});
