import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/device.dart';

class DeviceProvider with ChangeNotifier {
  final ApiService apiService;
  List<Device> _devices = [];
  bool _isLoading = false;
  String? _error;

  DeviceProvider({required this.apiService});

  List<Device> get devices => _devices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDevices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await apiService.get('/devices/get-devices', auth: true);
      _devices = (res as List).map((item) => Device.fromJson(item)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> removeDevice(int deviceId) async {
    try {
      await apiService.post('/devices/remove-device', {'device_id': deviceId}, auth: true);
      await fetchDevices();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
