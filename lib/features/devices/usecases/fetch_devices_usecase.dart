// lib/features/devices/usecases/fetch_devices_usecase.dart
import 'package:dio/dio.dart';
import '../models/domain/device.dart';
import '../repositories/device_repository.dart';

class FetchDevicesUseCase {
  final DeviceRepository _repo;
  const FetchDevicesUseCase(this._repo);
  Future<List<Device>> call({bool force = false, CancelToken? cancelToken}) =>
      _repo.getDevices(forceRefresh: force, cancelToken: cancelToken);
}

