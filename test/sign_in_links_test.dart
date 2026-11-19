import 'package:flutter_test/flutter_test.dart';
import 'package:host_bora/app/core/utils/referral_link.dart';

void main() {
  setUp(() {
    SignInLinks.pending = false;
    ReferralLinks.pendingCode = null;
  });

  test('captures https /app/signin', () {
    expect(
      SignInLinks.capture(Uri.parse('https://hostbora.co.tz/app/signin')),
      isTrue,
    );
    expect(SignInLinks.pending, isTrue);
  });

  test('captures trailing-slash sign-in path', () {
    SignInLinks.capture(Uri.parse('https://www.hostbora.co.tz/app/signin/'));
    expect(SignInLinks.pending, isTrue);
  });

  test('captures hostbora://signin', () {
    SignInLinks.capture(Uri.parse('hostbora://signin'));
    expect(SignInLinks.pending, isTrue);
  });

  test('ignores unrelated website paths', () {
    SignInLinks.capture(Uri.parse('https://hostbora.co.tz/register.html'));
    expect(SignInLinks.pending, isFalse);
  });
}
