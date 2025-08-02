import '../../../core/api_service.dart';
import '../models/device.dart';

class DeviceService {
  final ApiService api;

  DeviceService(this.api);

  Future<List<Device>> fetchDevices() async {
    final res = await api.get('/devices/get-devices', auth: true);
    if (res is List) {
      return res.map((item) => Device.fromJson(item)).toList();
    }
    throw Exception('Некорректный формат ответа');
  }

  Future<void> removeDevice(String deviceToken) async {
    await api.post('/devices/remove-device', {'device_token': deviceToken}, auth: true);
  }

  Future<void> addDevice({
    required String deviceToken,
    required String deviceModel,
    required String deviceOS,
  }) async {
    await api.post('/devices/add-device', {
      'device_token': deviceToken,
      'device_model': deviceModel,
      'device_os': deviceOS,
    }, auth: true);
  }
}
