import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_theme_tokens.dart';
import '../../data/local/service/currency_service.dart';

/// Dropdown to choose app base currency from cached FX rates.
class BaseCurrencyPicker extends StatelessWidget {
  const BaseCurrencyPicker({
    super.key,
    this.title,
    this.onChanged,
  });

  final String? title;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final svc = Get.find<CurrencyService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = context.tokens.textMuted;

    return Obx(() {
      if (svc.loadingRates.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      final codes = svc.currencyCodes;
      final selected = codes.contains(svc.baseCurrency.value)
          ? svc.baseCurrency.value
          : CurrencyService.defaultBaseCurrency;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: muted,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selected,
                items: codes
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) async {
                  if (v == null) return;
                  await svc.setBaseCurrency(v);
                  onChanged?.call(v);
                },
              ),
            ),
          ),
        ],
      );
    });
  }
}
