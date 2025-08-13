// lib/features/devices/usecases/update_current_last_seen_usecase.dart
import 'package:dio/dio.dart';
import '../../../core/platform/device_id.dart';
import '../repositories/device_repository.dart';

class UpdateCurrentLastSeenUseCase {
  final DeviceRepository _repo;
  const UpdateCurrentLastSeenUseCase(this._repo);

  Future<void> call({CancelToken? cancelToken}) async {
    final token = await DeviceId.getDeviceToken();
    await _repo.updateLastSeen(token, cancelToken: cancelToken);
  }
}

