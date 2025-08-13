// lib/features/devices/usecases/add_current_device_usecase.dart
import 'package:dio/dio.dart';
import '../../../core/platform/device_id.dart';
import '../repositories/device_repository.dart';

class AddCurrentDeviceUseCase {
  final DeviceRepository _repo;
  const AddCurrentDeviceUseCase(this._repo);

  Future<void> call({CancelToken? cancelToken}) async {
    final info = await DeviceId.getCurrentDeviceInfo();
    await _repo.addDevice(token: info.token, model: info.model, os: info.os, cancelToken: cancelToken);
  }
}

