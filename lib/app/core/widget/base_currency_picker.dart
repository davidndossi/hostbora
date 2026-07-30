import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_theme_tokens.dart';
import '../../data/local/service/currency_service.dart';

/// Dropdown to choose app base currency (static list; FX fetch optional for conversion).
class BaseCurrencyPicker extends StatelessWidget {
  const BaseCurrencyPicker({
    super.key,
    this.title,
    this.onChanged,
    this.forDarkBackground = false,
  });

  final String? title;
  final ValueChanged<String>? onChanged;
  final bool forDarkBackground;

  @override
  Widget build(BuildContext context) {
    final svc = Get.find<CurrencyService>();
    final muted = forDarkBackground
        ? Colors.white70
        : context.tokens.textMuted;
    final borderColor = forDarkBackground
        ? Colors.white24
        : Theme.of(context).dividerColor;
    final fieldBg = forDarkBackground
        ? Colors.white.withValues(alpha: 0.08)
        : null;
    final valueColor = forDarkBackground ? Colors.white : null;

    return Obx(() {
      final codes = svc.pickerCurrencyCodes;
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
                fontSize: forDarkBackground ? 13 : 12,
                fontWeight: FontWeight.w700,
                color: muted,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: fieldBg,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                dropdownColor: forDarkBackground
                    ? const Color(0xFF1A2744)
                    : null,
                value: selected,
                style: valueColor != null
                    ? TextStyle(color: valueColor, fontSize: 15)
                    : null,
                iconEnabledColor: valueColor ?? Theme.of(context).iconTheme.color,
                items: codes
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(_labelFor(c)),
                      ),
                    )
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

  static String _labelFor(String code) {
    switch (code) {
      case 'TZS':
        return 'TZS — Tanzanian Shilling';
      case 'USD':
        return 'USD — US Dollar';
      case 'EUR':
        return 'EUR — Euro';
      case 'GBP':
        return 'GBP — British Pound';
      case 'KES':
        return 'KES — Kenyan Shilling';
      case 'UGX':
        return 'UGX — Ugandan Shilling';
      case 'RWF':
        return 'RWF — Rwandan Franc';
      case 'ZAR':
        return 'ZAR — South African Rand';
      case 'CNY':
        return 'CNY — Chinese Yuan';
      case 'INR':
        return 'INR — Indian Rupee';
      case 'AED':
        return 'AED — UAE Dirham';
      case 'CAD':
        return 'CAD — Canadian Dollar';
      case 'AUD':
        return 'AUD — Australian Dollar';
      default:
        return code;
    }
  }
}
