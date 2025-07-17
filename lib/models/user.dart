class User {
  final String username;
  final String? email;
  final bool isPaid;
  final int subscriptionLevel;
  final String? trialEndDate;
  final int deviceCount;

  User({
    required this.username,
    this.email,
    required this.isPaid,
    required this.subscriptionLevel,
    this.trialEndDate,
    required this.deviceCount,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      isPaid: (json['is_paid'] ?? json['isPaid']) == 1 || (json['is_paid'] ?? json['isPaid']) == true,
      subscriptionLevel: (json['subscription_level'] ?? json['subscriptionLevel']) as int? ?? 0,
      trialEndDate: json['trial_end_date'] as String? ?? json['trialEndDate'] as String?,
      deviceCount: (json['device_count'] ?? json['deviceCount']) as int? ?? 0,
    );
  }
}
