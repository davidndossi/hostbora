import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/app/core/theme/app_theme_tokens.dart';
import '/app/data/local/service/currency_service.dart';

/// A working rent projection the host can use before creating an account.
///
/// Everything else before sign-up describes what Host Bora does. This does
/// something: two numbers in, a real figure back, no account and nothing
/// stored. It is the only place in the pre-auth flow where the app gives
/// before it asks, which is the whole point of it being here.
///
/// The arithmetic is deliberately plain — rent times units, times twelve — so
/// the output is something the host can check rather than trust.
class RentTryItCard extends StatefulWidget {
  const RentTryItCard({super.key});

  @override
  State<RentTryItCard> createState() => _RentTryItCardState();
}

class _RentTryItCardState extends State<RentTryItCard> {
  final _rentController = TextEditingController();
  final _unitsController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _rentController.addListener(_onChanged);
    _unitsController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _rentController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  double get _rent =>
      double.tryParse(_rentController.text.trim().replaceAll(',', '')) ?? 0;

  int get _units {
    final parsed = int.tryParse(_unitsController.text.trim()) ?? 0;
    return parsed < 1 ? 0 : parsed;
  }

  double get _monthly => _rent * _units;

  String _money(double amount) {
    if (Get.isRegistered<CurrencyService>()) {
      try {
        return Get.find<CurrencyService>().formatBase(amount);
      } catch (_) {}
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hasResult = _monthly > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'Jaribu sasa' : 'Try it now',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _isSw
                ? 'Hakuna akaunti inayohitajika. Hakuna kinachohifadhiwa.'
                : 'No account needed. Nothing is saved.',
            style: TextStyle(fontSize: 12, color: tokens.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _field(
                  tokens: tokens,
                  controller: _rentController,
                  label: _isSw ? 'Kodi kwa mwezi' : 'Rent per month',
                  hint: '400000',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _field(
                  tokens: tokens,
                  controller: _unitsController,
                  label: _isSw ? 'Vyumba' : 'Units',
                  hint: '1',
                ),
              ),
            ],
          ),
          if (hasResult) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: tokens.border),
            const SizedBox(height: 12),
            _resultRow(
              tokens: tokens,
              label: _isSw ? 'Kwa mwezi' : 'Per month',
              value: _money(_monthly),
              emphasise: true,
            ),
            const SizedBox(height: 8),
            _resultRow(
              tokens: tokens,
              label: _isSw ? 'Kwa mwaka' : 'Per year',
              value: _money(_monthly * 12),
            ),
            const SizedBox(height: 8),
            // The same arithmetic pointed at the risk. True for any rental,
            // and the reason tracking collection is worth doing at all.
            _resultRow(
              tokens: tokens,
              label: _isSw
                  ? 'Chumba kimoja wazi mwezi mmoja'
                  : 'One unit empty for a month',
              value: '-${_money(_rent)}',
              tone: tokens.warning,
            ),
          ],
        ],
      ),
    );
  }

  Widget _field({
    required AppThemeTokens tokens,
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: tokens.textSecondary),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(fontSize: 15, color: tokens.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(color: tokens.textMuted, fontSize: 15),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: tokens.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: tokens.accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultRow({
    required AppThemeTokens tokens,
    required String label,
    required String value,
    bool emphasise = false,
    Color? tone,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: tone ?? tokens.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasise ? 18 : 14,
            fontWeight: emphasise ? FontWeight.w700 : FontWeight.w600,
            color: tone ?? (emphasise ? tokens.accent : tokens.textPrimary),
          ),
        ),
      ],
    );
  }
}
