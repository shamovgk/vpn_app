class User {
  final String username;
  final String? email;
  final bool isPaid;
  final String? trialEndDate;
  final String? paidUntil;
  final int deviceCount;

  User({
    required this.username,
    this.email,
    required this.isPaid,
    this.trialEndDate,
    this.paidUntil,
    required this.deviceCount,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      isPaid: (json['is_paid'] ?? json['isPaid']) == 1 || (json['is_paid'] ?? json['isPaid']) == true,
      trialEndDate: json['trial_end_date'] as String? ?? json['trialEndDate'] as String?,
      paidUntil: json['paid_until'] as String? ?? json['paidUntil'] as String?,
      deviceCount: (json['device_count'] ?? json['deviceCount']) as int? ?? 0,
    );
  }
}
