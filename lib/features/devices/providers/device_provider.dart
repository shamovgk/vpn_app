import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_service.dart';
import '../services/device_service.dart';
import '../models/device.dart';

// Провайдер DeviceService
final deviceServiceProvider = Provider<DeviceService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return DeviceService(apiService);
});

// StateNotifier для управления списком устройств
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

  Future<void> removeDevice(int deviceId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await deviceService.removeDevice(deviceId);
      await fetchDevices();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Riverpod StateNotifierProvider
final deviceProvider = StateNotifierProvider<DeviceNotifier, DeviceState>((ref) {
  final service = ref.watch(deviceServiceProvider);
  return DeviceNotifier(service);
});
