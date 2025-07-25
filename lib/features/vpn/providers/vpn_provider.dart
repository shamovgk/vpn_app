import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_service.dart';
import '../services/vpn_service.dart';

// State
class VpnState {
  final bool isConnecting;
  final bool isConnected;
  final String? error;

  const VpnState({
    this.isConnecting = false,
    this.isConnected = false,
    this.error,
  });

  VpnState copyWith({
    bool? isConnecting,
    bool? isConnected,
    String? error,
  }) {
    return VpnState(
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      error: error,
    );
  }
}

final vpnServiceProvider = Provider<VpnService>((ref) => VpnService());

final vpnProvider = StateNotifierProvider<VpnNotifier, VpnState>((ref) {
  final service = ref.watch(vpnServiceProvider);
  final apiService = ref.watch(apiServiceProvider);
  return VpnNotifier(service, apiService);
});

class VpnNotifier extends StateNotifier<VpnState> {
  final VpnService service;
  final ApiService apiService;

  VpnNotifier(this.service, this.apiService) : super(const VpnState());

  Future<void> connect({
    required bool isPaid,
    required String? trialEndDate,
    required int deviceCount,
    required int subscriptionLevel,
  }) async {
    state = state.copyWith(isConnecting: true, error: null);
    try {
      await service.connect(
        apiService: apiService,
        isPaid: isPaid,
        trialEndDate: trialEndDate,
        deviceCount: deviceCount,
        subscriptionLevel: subscriptionLevel,
      );
      state = state.copyWith(isConnecting: false, isConnected: true, error: null);
    } catch (e) {
      state = state.copyWith(isConnecting: false, isConnected: false, error: e.toString());
    }
  }

  Future<void> disconnect() async {
    state = state.copyWith(isConnecting: true, error: null);
    try {
      await service.disconnect();
      state = state.copyWith(isConnecting: false, isConnected: false, error: null);
    } catch (e) {
      state = state.copyWith(isConnecting: false, error: e.toString());
    }
  }
}
