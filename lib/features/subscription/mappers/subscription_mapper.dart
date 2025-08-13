// lib/features/subscription/mappers/subscription_mapper.dart
import '../models/subscription_status.dart';

SubscriptionStatus subscriptionStatusFromMap(Map<String, dynamic> json) {
  String? str(dynamic v) => v?.toString();

  return SubscriptionStatus(
    isTrial: (json['is_trial'] ?? json['isTrial'] ?? false) == true,
    trialEndDate: str(json['trial_end_date'] ?? json['trialEndDate'] ?? json['end_date']),
    isPaid: (json['is_paid'] ?? json['isPaid'] ?? false) == true,
    paidUntil: str(json['paid_until'] ?? json['paidUntil'] ?? json['end_date']),
    canUse: (json['can_use'] ?? json['canUse'] ?? false) == true,
    deviceCount: (json['device_count'] ?? json['deviceCount'] ?? 0) as int,
    maxDevices: (json['max_devices'] ?? json['maxDevices'] ?? 3) as int,
  );
}
