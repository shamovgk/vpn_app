class VpnConfig {
  final String privateKey;
  final String address;
  final String dns;
  final String serverPublicKey;
  final String endpoint;
  final String allowedIps;

  VpnConfig({
    required this.privateKey,
    required this.address,
    required this.dns,
    required this.serverPublicKey,
    required this.endpoint,
    required this.allowedIps,
  });

  factory VpnConfig.fromJson(Map<String, dynamic> json) {
    return VpnConfig(
      privateKey: json['privateKey'],
      address: json['address'],
      dns: json['dns'] ?? '1.1.1.1',
      serverPublicKey: json['serverPublicKey'],
      endpoint: json['endpoint'],
      allowedIps: json['allowedIps'] ?? '0.0.0.0/0, ::/0',
    );
  }
}
