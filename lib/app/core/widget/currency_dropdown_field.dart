import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/local/service/currency_service.dart';

/// Currency picker bound to [CurrencyService]; defaults to base currency.
///
/// When [showRateHint] is true (default) and the selected currency differs from
/// the base currency, a full-width rate hint (e.g. "1 USD ≈ TZS 2,650") is shown
/// below the dropdown so users know the conversion at a glance.
class CurrencyDropdownField extends StatelessWidget {
  const CurrencyDropdownField({
    super.key,
    required this.selectedCurrency,
    this.onChanged,
    this.label,
    this.compact = false,
    this.showRateHint = true,
  });

  final RxString selectedCurrency;
  final ValueChanged<String?>? onChanged;
  final String? label;
  final bool compact;

  /// Show the "1 X ≈ BASE rate" hint below when selected ≠ base currency.
  final bool showRateHint;

  static final _rateFmt = NumberFormat('#,###', 'en_US');

  @override
  Widget build(BuildContext context) {
    final currencyService = Get.find<CurrencyService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final codes = currencyService.currencyCodes;
      final base = currencyService.baseCurrency.value;
      final value = codes.contains(selectedCurrency.value)
          ? selectedCurrency.value
          : base;

      final dropdown = DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          items: codes
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            selectedCurrency.value = v;
            onChanged?.call(v);
          },
        ),
      );

      final dropdownBox = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: dropdown,
      );

      if (compact) {
        return dropdownBox;
      }

      // Build the rate hint when selected currency ≠ base currency.
      Widget? rateHint;
      if (showRateHint && value != base) {
        final rate = currencyService.sellingRateFor(value);
        if (rate != null && rate > 0) {
          final rateLabel = rate >= 1
              ? _rateFmt.format(rate.round())
              : rate.toStringAsFixed(4);
          final hintColor = isDark
              ? const Color(0xFF80CBC4)
              : const Color(0xFF0E6666);
          final fullLabel = '1 $value ≈ $base $rateLabel';
          rateHint = Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.swap_horiz_rounded, size: 16, color: hintColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fullLabel,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: hintColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          dropdownBox,
          ?rateHint,
        ],
      );
    });
  }
}
