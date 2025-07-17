class Device {
  final int id;
  final String deviceToken;
  final String deviceModel;
  final String deviceOS;
  final String lastSeen;

  Device({
    required this.id,
    required this.deviceToken,
    required this.deviceModel,
    required this.deviceOS,
    required this.lastSeen,
  });

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        id: json['id'],
        deviceToken: json['device_token'],
        deviceModel: json['device_model'] ?? 'Unknown Model',
        deviceOS: json['device_os'] ?? 'Unknown OS',
        lastSeen: json['last_seen'] ?? '',
      );
}
