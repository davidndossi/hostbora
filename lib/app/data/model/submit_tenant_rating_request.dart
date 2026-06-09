/// Request body for POST /api/tenant-ratings.
class SubmitTenantRatingRequest {
  SubmitTenantRatingRequest({
    required this.phoneNumber,
    required this.tenantName,
    required this.overallStars,
    required this.paymentStars,
    required this.propertyCareStars,
    required this.communicationStars,
    required this.rentAgain,
    this.comment = '',
    this.workspace = 'rent',
    this.shareConsent = false,
    this.tenancyDurationDays = 0,
  });

  final String phoneNumber;
  final String tenantName;
  final int overallStars;
  final int paymentStars;
  final int propertyCareStars;
  final int communicationStars;
  final String rentAgain;
  final String comment;
  final String workspace;
  final bool shareConsent;
  final int tenancyDurationDays;

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'tenantName': tenantName,
        'overallStars': overallStars,
        'paymentStars': paymentStars,
        'propertyCareStars': propertyCareStars,
        'communicationStars': communicationStars,
        'rentAgain': rentAgain,
        if (comment.isNotEmpty) 'comment': comment,
        'workspace': workspace,
        'shareConsent': shareConsent,
        'tenancyDurationDays': tenancyDurationDays,
      };
}
