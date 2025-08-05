import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

final vpnAccessProvider = Provider<bool>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return false;
  final trialEnd = user.trialEndDate != null ? DateTime.tryParse(user.trialEndDate!) : null;
  final trialActive = trialEnd != null && trialEnd.isAfter(DateTime.now());
  return user.isPaid || trialActive;
});
