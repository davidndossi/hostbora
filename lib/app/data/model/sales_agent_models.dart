class ReferralValidation {
  const ReferralValidation({
    required this.valid,
    this.agentCode,
    this.agentName,
  });

  final bool valid;
  final String? agentCode;
  final String? agentName;

  factory ReferralValidation.fromJson(Map<String, dynamic> json) {
    return ReferralValidation(
      valid: json['valid'] == true,
      agentCode: json['agentCode']?.toString(),
      agentName: json['agentName']?.toString(),
    );
  }
}

class SalesAgentSummary {
  const SalesAgentSummary({
    required this.id,
    required this.agentCode,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.region,
    required this.status,
    this.userId,
  });

  final int id;
  final String agentCode;
  final String fullName;
  final String phone;
  final String email;
  final String region;
  final String status;
  final String? userId;

  factory SalesAgentSummary.fromJson(Map<String, dynamic> json) {
    return SalesAgentSummary(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      agentCode: json['agentCode']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      userId: json['userId']?.toString(),
    );
  }
}

class ReferredCustomerRow {
  const ReferredCustomerRow({
    required this.customerUserId,
    required this.customerPhone,
    required this.customerName,
    required this.plan,
    required this.subscriptionStatus,
    required this.paidMonthsCount,
    required this.registeredAtMs,
    required this.active,
  });

  final String customerUserId;
  final String customerPhone;
  final String customerName;
  final String plan;
  final String subscriptionStatus;
  final int paidMonthsCount;
  final int registeredAtMs;
  final bool active;

  factory ReferredCustomerRow.fromJson(Map<String, dynamic> json) {
    return ReferredCustomerRow(
      customerUserId: json['customerUserId']?.toString() ?? '',
      customerPhone: json['customerPhone']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      plan: json['plan']?.toString() ?? 'none',
      subscriptionStatus: json['subscriptionStatus']?.toString() ?? '',
      paidMonthsCount: int.tryParse(json['paidMonthsCount']?.toString() ?? '') ?? 0,
      registeredAtMs: int.tryParse(json['registeredAtMs']?.toString() ?? '') ?? 0,
      active: json['active'] == true,
    );
  }
}

class CommissionRow {
  const CommissionRow({
    required this.id,
    required this.eventType,
    required this.plan,
    required this.amountTzs,
    required this.commissionTzs,
    required this.status,
    required this.periodMonth,
    required this.createdAtMs,
  });

  final int id;
  final String eventType;
  final String plan;
  final int amountTzs;
  final int commissionTzs;
  final String status;
  final String periodMonth;
  final int createdAtMs;

  factory CommissionRow.fromJson(Map<String, dynamic> json) {
    return CommissionRow(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      eventType: json['eventType']?.toString() ?? '',
      plan: json['plan']?.toString() ?? '',
      amountTzs: int.tryParse(json['amountTzs']?.toString() ?? '') ?? 0,
      commissionTzs: int.tryParse(json['commissionTzs']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? '',
      periodMonth: json['periodMonth']?.toString() ?? '',
      createdAtMs: int.tryParse(json['createdAtMs']?.toString() ?? '') ?? 0,
    );
  }
}

class SalesAgentDashboard {
  const SalesAgentDashboard({
    required this.agent,
    required this.inviteUrl,
    required this.invited,
    required this.registered,
    required this.active,
    required this.totalRecruited,
    required this.activeSubscribers,
    required this.paidSubscribers,
    required this.byTier,
    required this.commissionThisMonthTzs,
    required this.commissionApprovedTzs,
    required this.periodMonth,
    required this.customers,
    required this.recentCommissions,
  });

  final SalesAgentSummary agent;
  final String inviteUrl;
  final int invited;
  final int registered;
  final int active;
  final int totalRecruited;
  final int activeSubscribers;
  final int paidSubscribers;
  final Map<String, int> byTier;
  final int commissionThisMonthTzs;
  final int commissionApprovedTzs;
  final String periodMonth;
  final List<ReferredCustomerRow> customers;
  final List<CommissionRow> recentCommissions;

  factory SalesAgentDashboard.fromJson(Map<String, dynamic> json) {
    final tierRaw = json['byTier'];
    final tiers = <String, int>{};
    if (tierRaw is Map) {
      tierRaw.forEach((key, value) {
        tiers[key.toString()] = int.tryParse(value.toString()) ?? 0;
      });
    }
    final customersRaw = json['customers'];
    final commissionsRaw = json['recentCommissions'];
    final agent = SalesAgentSummary.fromJson(
      (json['agent'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final recruited = int.tryParse(json['totalRecruited']?.toString() ?? '') ?? 0;
    final activeSubs =
        int.tryParse(json['activeSubscribers']?.toString() ?? '') ?? 0;
    final registered =
        int.tryParse(json['registered']?.toString() ?? '') ?? recruited;
    final active = int.tryParse(json['active']?.toString() ?? '') ?? activeSubs;
    final invited = int.tryParse(json['invited']?.toString() ?? '') ??
        (registered > 0 ? registered : 0);
    final inviteUrl = json['inviteUrl']?.toString().trim() ?? '';
    return SalesAgentDashboard(
      agent: agent,
      inviteUrl: inviteUrl.isNotEmpty
          ? inviteUrl
          : 'https://hostbora.co.tz/r/${agent.agentCode}',
      invited: invited,
      registered: registered,
      active: active,
      totalRecruited: recruited,
      activeSubscribers: activeSubs,
      paidSubscribers: int.tryParse(json['paidSubscribers']?.toString() ?? '') ?? 0,
      byTier: tiers,
      commissionThisMonthTzs:
          int.tryParse(json['commissionThisMonthTzs']?.toString() ?? '') ?? 0,
      commissionApprovedTzs:
          int.tryParse(json['commissionApprovedTzs']?.toString() ?? '') ?? 0,
      periodMonth: json['periodMonth']?.toString() ?? '',
      customers: customersRaw is List
          ? customersRaw
              .whereType<Map>()
              .map((e) => ReferredCustomerRow.fromJson(e.cast<String, dynamic>()))
              .toList()
          : const [],
      recentCommissions: commissionsRaw is List
          ? commissionsRaw
              .whereType<Map>()
              .map((e) => CommissionRow.fromJson(e.cast<String, dynamic>()))
              .toList()
          : const [],
    );
  }
}

class CreateSalesAgentRequest {
  CreateSalesAgentRequest({
    required this.fullName,
    this.phone,
    this.email,
    this.region,
    this.agentCode,
    this.userId,
  });

  final String fullName;
  final String? phone;
  final String? email;
  final String? region;
  final String? agentCode;
  final String? userId;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (email != null && email!.isNotEmpty) 'email': email,
      if (region != null && region!.isNotEmpty) 'region': region,
      if (agentCode != null && agentCode!.isNotEmpty) 'agentCode': agentCode,
      if (userId != null && userId!.isNotEmpty) 'userId': userId,
    };
  }
}
