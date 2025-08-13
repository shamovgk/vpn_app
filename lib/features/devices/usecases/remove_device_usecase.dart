// lib/features/devices/usecases/remove_device_usecase.dart
import 'package:dio/dio.dart';
import '../repositories/device_repository.dart';

class RemoveDeviceUseCase {
  final DeviceRepository _repo;
  const RemoveDeviceUseCase(this._repo);
  Future<void> call(String token, {CancelToken? cancelToken}) =>
      _repo.removeDevice(token, cancelToken: cancelToken);
}

