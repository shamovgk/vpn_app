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
}