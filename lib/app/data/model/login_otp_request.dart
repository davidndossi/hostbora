/// Passwordless login OTP request / verify payloads.
class LoginOtpRequest {
  LoginOtpRequest({
    this.msisdn,
    this.channel,
    this.otp,
    this.firebaseToken,
  });

  final String? msisdn;
  /// `EMAIL` or `SMS` (WhatsApp reserved).
  final String? channel;
  final String? otp;
  final String? firebaseToken;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (msisdn != null) map['msisdn'] = msisdn;
    if (channel != null) map['channel'] = channel;
    if (otp != null) map['otp'] = otp;
    if (firebaseToken != null && firebaseToken!.isNotEmpty) {
      map['firebaseToken'] = firebaseToken;
    }
    return map;
  }
}
