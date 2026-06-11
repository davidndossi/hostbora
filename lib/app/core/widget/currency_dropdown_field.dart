import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/local/service/currency_service.dart';

/// Currency picker bound to [CurrencyService]; defaults to base currency.
///
/// When [showRateHint] is true (default) and the selected currency differs from
/// the base currency, a compact rate hint (e.g. "1 USD ≈ TZS 2,650") is shown
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
            padding: const EdgeInsets.only(top: 5),
            child: GestureDetector(
              onLongPress: () => _showRatePopup(context, fullLabel, hintColor, isDark),
              child: Row(
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 12, color: hintColor),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      fullLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: hintColor,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
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

  static void _showRatePopup(
    BuildContext context,
    String label,
    Color hintColor,
    bool isDark,
  ) {
    final overlay = Overlay.of(context);
    // Find the vertical position of this widget on screen so the popup
    // appears close to it, but anchor horizontally to the screen edges so
    // it is never clipped by a narrow parent.
    final renderBox = context.findRenderObject() as RenderBox?;
    final origin = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final widgetHeight = renderBox?.size.height ?? 0;
    final screenSize = MediaQuery.of(context).size;

    // Clamp vertical position so the popup never goes off the bottom.
    const popupHeight = 44.0;
    const margin = 16.0;
    double top = origin.dy + widgetHeight + 6;
    if (top + popupHeight > screenSize.height - margin) {
      // Not enough space below — show above the widget instead.
      top = origin.dy - popupHeight - 6;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => entry.remove(),
        child: Stack(
          children: [
            Positioned(
              // Full-width popup anchored to screen edges, independent of parent.
              left: margin,
              right: margin,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E3A3A) : const Color(0xFFE0F4F4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: hintColor.withValues(alpha: 0.45)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 16, color: hintColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: hintColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }
}
