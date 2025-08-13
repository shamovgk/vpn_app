// lib/features/devices/repositories/device_repository.dart
import 'package:dio/dio.dart';
import '../models/domain/device.dart';

abstract class DeviceRepository {
  Future<List<Device>> getDevices({bool forceRefresh = false, CancelToken? cancelToken});
  Future<List<Device>> refresh({CancelToken? cancelToken});
  Future<void> addDevice({required String token, required String model, required String os, CancelToken? cancelToken});
  Future<void> removeDevice(String token, {CancelToken? cancelToken});
  Future<void> updateLastSeen(String token, {CancelToken? cancelToken});
}

