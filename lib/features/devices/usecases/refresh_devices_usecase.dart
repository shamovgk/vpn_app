// lib/features/devices/usecases/refresh_devices_usecase.dart
import 'package:dio/dio.dart';
import '../models/domain/device.dart';
import '../repositories/device_repository.dart';

class RefreshDevicesUseCase {
  final DeviceRepository _repo;
  const RefreshDevicesUseCase(this._repo);
  Future<List<Device>> call({CancelToken? cancelToken}) => _repo.refresh(cancelToken: cancelToken);
}

