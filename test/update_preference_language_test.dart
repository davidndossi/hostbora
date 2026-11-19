import 'package:flutter_test/flutter_test.dart';
import 'package:host_bora/app/data/model/update_preference_request.dart';

void main() {
  test('reads language from nested preference payloads', () {
    expect(
      UpdatePreferenceRequest.parseLanguage({
        'data': {
          'preferences': {'language': 'sw_TZ'},
        },
      }),
      'sw',
    );
    expect(
      UpdatePreferenceRequest.parseLanguage({'language': 'en'}),
      'en',
    );
    expect(
      UpdatePreferenceRequest.parseLanguage({'locale': 'SW'}),
      'sw',
    );
    expect(UpdatePreferenceRequest.parseLanguage({'language': 'fr'}), isNull);
    expect(UpdatePreferenceRequest.parseLanguage(null), isNull);
  });
}
