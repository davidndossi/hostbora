class HostNetworkReferral {
  HostNetworkReferral({
    required this.referredUserId,
    required this.referralCode,
    required this.registrationDate,
    this.activationDate,
    required this.rewardStatus,
    this.fullName,
    this.username,
  });

  factory HostNetworkReferral.fromJson(Map<String, dynamic> json) {
    return HostNetworkReferral(
      referredUserId: json['referredUserId']?.toString() ?? '',
      referralCode: json['referralCode']?.toString() ?? '',
      registrationDate: _toInt(json['registrationDate']),
      activationDate: json['activationDate'] == null ? null : _toInt(json['activationDate']),
      rewardStatus: json['rewardStatus']?.toString() ?? 'pending',
      fullName: json['fullName']?.toString(),
      username: json['username']?.toString(),
    );
  }

  final String referredUserId;
  final String referralCode;
  final int registrationDate;
  final int? activationDate;
  final String rewardStatus;
  final String? fullName;
  final String? username;
}

class HostNetwork {
  HostNetwork({
    required this.referralCode,
    required this.inviteUrl,
    required this.invited,
    required this.registered,
    required this.activeHosts,
    required this.hbPoints,
    required this.freeMonths,
    this.referrals = const [],
  });

  factory HostNetwork.fromJson(Map<String, dynamic> json) {
    final raw = json['referrals'];
    return HostNetwork(
      referralCode: json['referralCode']?.toString() ?? '',
      inviteUrl: json['inviteUrl']?.toString() ?? '',
      invited: _toInt(json['invited']),
      registered: _toInt(json['registered']),
      activeHosts: _toInt(json['activeHosts']),
      hbPoints: _toInt(json['hbPoints']),
      freeMonths: _toInt(json['freeMonths']),
      referrals: raw is List
          ? raw
                .whereType<Map>()
                .map((item) => HostNetworkReferral.fromJson(Map<String, dynamic>.from(item)))
                .toList()
          : const [],
    );
  }

  final String referralCode;
  final String inviteUrl;
  final int invited;
  final int registered;
  final int activeHosts;
  final int hbPoints;
  final int freeMonths;
  final List<HostNetworkReferral> referrals;
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
