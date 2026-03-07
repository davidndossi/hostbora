import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static const separator = ',';

  final NumberFormat _formatter = NumberFormat('#,##0.##');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Short-circuit if the new value is empty
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Check for a valid number input
    String text = newValue.text.replaceAll(separator, '');
    double? value = double.tryParse(text);

    if (value == null) {
      return oldValue;
    }

    // Format the number while keeping the decimal part if necessary
    String newText;
    if (newValue.text.contains(_formatter.symbols.DECIMAL_SEP)) {
      final parts = text.split(_formatter.symbols.DECIMAL_SEP);
      final formattedIntPart = _formatter.format(int.parse(parts[0]));
      newText = '$formattedIntPart${_formatter.symbols.DECIMAL_SEP}${parts[1]}';
    } else {
      // Format the input
      newText = _formatter.format(value);
    }

    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: newText.length)
    );
  }
}