import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_theme_tokens.dart';
import '../../data/local/service/currency_service.dart';

/// Currency picker bound to [CurrencyService]; defaults to base currency.
class CurrencyDropdownField extends StatelessWidget {
  const CurrencyDropdownField({
    super.key,
    required this.selectedCurrency,
    this.onChanged,
    this.label,
    this.compact = false,
  });

  final RxString selectedCurrency;
  final ValueChanged<String?>? onChanged;
  final String? label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
  final currencyService = Get.find<CurrencyService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = context.tokens.textMuted;

    return Obx(() {
      final codes = currencyService.currencyCodes;
      final value = codes.contains(selectedCurrency.value)
          ? selectedCurrency.value
          : currencyService.baseCurrency.value;

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

      if (compact) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: dropdown,
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // if (label != null) ...[
          //   Text(
          //     label!,
          //     style: TextStyle(
          //       fontSize: 10,
          //       letterSpacing: 1.1,
          //       fontWeight: FontWeight.w700,
          //       color: labelColor,
          //     ),
          //   ),
            const SizedBox(height: 3),
          // ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: dropdown,
          ),
        ],
      );
    });
  }
}
