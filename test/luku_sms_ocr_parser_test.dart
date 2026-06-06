import 'package:flutter_test/flutter_test.dart';
import 'package:host_bora/app/modules/rent/smart_utility_dashboard/utils/luku_sms_ocr_parser.dart';

void main() {
  test('parses multiple LUKU token SMS records from OCR text', () {
    const text = '''
Thu, 19 Feb at 02:35
LUKU Token 6486 3184 0944 4541
8689 , Units 280.7KWH, Meter No.
22124058284, TZS100000

Sun, 22 Mar at 19:17
LUKU Token 5580 2084 4506 6976
1010 , Units 2.8KWH, Meter No.
43029371218, TZS1000
''';

    final records = const LukuSmsOcrParser().parse(
      text,
      now: DateTime(2026, 6, 2),
    );

    expect(records, hasLength(2));
    expect(records.first.token, '64863184094445418689');
    expect(records.first.unitsKwh, 280.7);
    expect(records.first.meterNumber, '22124058284');
    expect(records.first.amountTsh, 100000);
    expect(records.first.date, DateTime(2026, 2, 19, 2, 35));

    expect(records.last.token, '55802084450669761010');
    expect(records.last.unitsKwh, 2.8);
    expect(records.last.meterNumber, '43029371218');
    expect(records.last.amountTsh, 1000);
    expect(records.last.date, DateTime(2026, 3, 22, 19, 17));
  });
}
