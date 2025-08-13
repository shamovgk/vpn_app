// lib/features/subscription/models/subscription_state.dart
import 'package:vpn_app/features/subscription/models/subscription_status.dart';

sealed class SubscriptionState {
  const SubscriptionState();
}

class SubscriptionIdle extends SubscriptionState {
  const SubscriptionIdle();
}

class SubscriptionLoading extends SubscriptionState {
  const SubscriptionLoading();
}

class SubscriptionReady extends SubscriptionState {
  final SubscriptionStatus status;
  const SubscriptionReady(this.status);
}

class SubscriptionError extends SubscriptionState {
  final String message;
  const SubscriptionError(this.message);
}
