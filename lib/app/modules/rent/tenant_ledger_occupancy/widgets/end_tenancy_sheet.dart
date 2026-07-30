import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/haptic_feedback_util.dart';
import '../../../../data/local/db/client_event_local_data_source.dart';
import '../../../../data/local/db/income_local_data_source.dart';
import '../../../../data/local/db/tenant_local_data_source.dart';
import '../../../../data/local/db/tenant_rating_local_data_source.dart';
import '../../../../data/local/service/currency_service.dart';

// ---------------------------------------------------------------------------
// Result returned after sheet completes
// ---------------------------------------------------------------------------
class EndTenancyResult {
  const EndTenancyResult({
    required this.endedAtIso,
    required this.balanceHandling,
    required this.ratingId,
    required this.shareConsent,
  });

  final String endedAtIso;
  final String balanceHandling; // 'cleared' | 'written_off' | 'partial'
  final int? ratingId;
  final bool shareConsent;
}

// ---------------------------------------------------------------------------
// Internal state — plain dart class (not GetX) to keep the sheet self-contained
// ---------------------------------------------------------------------------
class _SheetState extends ChangeNotifier {
  int step = 0; // 0-confirm, 1-balance, 2-rate, 3-consent

  // Step 0
  DateTime endDate = DateTime.now();

  // Step 1
  String balanceHandling = 'cleared';
  final partialAmountCtrl = TextEditingController();

  // Step 2 — ratings
  int overallStars = 0;
  int paymentStars = 0;
  int propertyCareStars = 0;
  int communicationStars = 0;
  String rentAgain = 'yes';
  final commentCtrl = TextEditingController();

  // Step 3
  bool shareConsent = false;

  bool get ratingComplete => overallStars > 0 && paymentStars > 0;

  void next() {
    step = (step + 1).clamp(0, 3);
    notifyListeners();
  }

  void back() {
    step = (step - 1).clamp(0, 3);
    notifyListeners();
  }

  void setEndDate(DateTime d) {
    endDate = d;
    notifyListeners();
  }

  void setBalanceHandling(String v) {
    balanceHandling = v;
    notifyListeners();
  }

  void setRentAgain(String v) {
    rentAgain = v;
    notifyListeners();
  }

  void setShareConsent(bool v) {
    shareConsent = v;
    notifyListeners();
  }

  void setStars(String dimension, int stars) {
    switch (dimension) {
      case 'overall':
        overallStars = stars;
        break;
      case 'payment':
        paymentStars = stars;
        break;
      case 'care':
        propertyCareStars = stars;
        break;
      case 'communication':
        communicationStars = stars;
        break;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    partialAmountCtrl.dispose();
    commentCtrl.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// The main sheet widget
// ---------------------------------------------------------------------------
class EndTenancySheet extends StatefulWidget {
  const EndTenancySheet({
    super.key,
    required this.tenantRecord,
    required this.outstandingBalanceTsh,
    required this.workspace,
    required this.onCompleted,
  });

  final TenantRecord tenantRecord;
  final int outstandingBalanceTsh;
  final String workspace;
  final void Function(EndTenancyResult) onCompleted;

  static Future<void> show({
    required TenantRecord tenant,
    required int outstandingBalanceTsh,
    required String workspace,
    required void Function(EndTenancyResult) onCompleted,
  }) {
    return Get.bottomSheet(
      EndTenancySheet(
        tenantRecord: tenant,
        outstandingBalanceTsh: outstandingBalanceTsh,
        workspace: workspace,
        onCompleted: onCompleted,
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<EndTenancySheet> createState() => _EndTenancySheetState();
}

class _EndTenancySheetState extends State<EndTenancySheet> {
  late final _SheetState _state;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _state = _SheetState();
    _state.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  // ---- helpers ----
  ThemeData get _theme => Theme.of(context);
  bool get _dark => _theme.brightness == Brightness.dark;
  Color get _surface => _dark ? const Color(0xFF1E1E2E) : Colors.white;
  Color get _onSurface => _dark ? Colors.white : const Color(0xFF1A1A2E);
  Color get _muted => _dark ? Colors.white38 : Colors.black38;
  Color get _teal => const Color(0xFF0E6666);

  final _fmt = DateFormat('dd/MM/yyyy');
  CurrencyService get _currency => Get.find<CurrencyService>();

  // ---- submit ----
  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final tenantLocal = Get.find<TenantLocalDataSource>();
      final clientEventLocal = Get.find<ClientEventLocalDataSource>();
      final ratingLocal = Get.find<TenantRatingLocalDataSource>();
      final incomeLocal = Get.find<IncomeLocalDataSource>();

      final endedAtIso = _state.endDate.toIso8601String().split('T').first;
      final endedAtMs = _state.endDate.millisecondsSinceEpoch;

      // 1. End tenancy in local DB
      await tenantLocal.endTenancy(
        id: widget.tenantRecord.id,
        endedAtIso: endedAtIso,
        endedAtMs: endedAtMs,
      );

      // 2. Settle balance if partial payment specified
      if (_state.balanceHandling == 'partial') {
        final partial = int.tryParse(_state.partialAmountCtrl.text.trim()) ?? 0;
        if (partial > 0) {
          await incomeLocal.insert(
            tenantName: widget.tenantRecord.tenantName,
            amountValue: partial.toDouble(),
            datePaidIso: endedAtIso,
            category: 'rent',
            notes: 'End-of-tenancy partial settlement',
            apartment: widget.tenantRecord.propertyLabel,
            apartmentUnit: widget.tenantRecord.unitLabel,
            propertyRef: widget.tenantRecord.propertyRef,
            workspaceType: widget.workspace,
          );
        }
      }

      // 3. Write lease_ended event
      final leaseStart = DateTime.tryParse(widget.tenantRecord.leaseStartIso);
      final days = leaseStart != null
          ? _state.endDate.difference(leaseStart).inDays.abs()
          : 0;
      await clientEventLocal.insert(
        tenantLocalId: widget.tenantRecord.id,
        phoneNumber: widget.tenantRecord.phoneNumber,
        clientName: widget.tenantRecord.tenantName,
        propertyRef: widget.tenantRecord.propertyRef,
        propertyLabel: widget.tenantRecord.propertyLabel,
        unitLabel: widget.tenantRecord.unitLabel,
        workspace: widget.workspace,
        eventType: ClientEventType.leaseEnded,
        metadata: {
          'balanceHandling': _state.balanceHandling,
          'durationDays': days,
        },
      );

      // 4. Save rating
      int? ratingId;
      if (_state.ratingComplete) {
        ratingId = await ratingLocal.insert(
          tenantLocalId: widget.tenantRecord.id,
          phoneNumber: widget.tenantRecord.phoneNumber,
          tenantName: widget.tenantRecord.tenantName,
          overallStars: _state.overallStars,
          paymentStars: _state.paymentStars,
          propertyCareStars: _state.propertyCareStars,
          communicationStars: _state.communicationStars,
          rentAgain: _state.rentAgain,
          comment: _state.commentCtrl.text.trim(),
          workspace: widget.workspace,
          shareConsent: _state.shareConsent,
          tenancyDurationDays: days,
        );
      }

      hapticPrimaryConfirm();
      Get.back();
      widget.onCompleted(
        EndTenancyResult(
          endedAtIso: endedAtIso,
          balanceHandling: _state.balanceHandling,
          ratingId: ratingId,
          shareConsent: _state.shareConsent,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---- page routing ----
  bool get _canProceed {
    switch (_state.step) {
      case 2:
        return _state.ratingComplete;
      default:
        return true;
    }
  }

  String get _nextLabel {
    switch (_state.step) {
      case 2:
        return 'Next';
      case 3:
        return 'Confirm & End Tenancy';
      default:
        return 'Next';
    }
  }

  // ---- build ----
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _muted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // step indicator
          _StepIndicator(current: _state.step, total: 4, teal: _teal),
          const SizedBox(height: 20),
          // page content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: ValueKey(_state.step),
              child: _buildStep(context),
            ),
          ),
          const SizedBox(height: 20),
          // nav buttons
          Row(
            children: [
              if (_state.step > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _state.back,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Back'),
                  ),
                ),
              if (_state.step > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: (_busy || !_canProceed)
                      ? null
                      : () {
                          if (_state.step < 3) {
                            _state.next();
                          } else {
                            _submit();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _state.step == 3
                        ? Colors.red.shade700
                        : _teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _nextLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (_state.step) {
      case 0:
        return _StepConfirm(
          state: _state,
          tenant: widget.tenantRecord,
          fmt: _fmt,
          onSurface: _onSurface,
          teal: _teal,
          context: context,
        );
      case 1:
        return _StepBalance(
          state: _state,
          outstandingTsh: widget.outstandingBalanceTsh,
          formatAmount: _currency.formatBase,
          onSurface: _onSurface,
          muted: _muted,
        );
      case 2:
        return _StepRate(state: _state, onSurface: _onSurface, muted: _muted);
      case 3:
        return _StepConsent(
          state: _state,
          tenant: widget.tenantRecord,
          onSurface: _onSurface,
          muted: _muted,
          teal: _teal,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ---------------------------------------------------------------------------
// Step widgets
// ---------------------------------------------------------------------------

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.current,
    required this.total,
    required this.teal,
  });

  final int current;
  final int total;
  final Color teal;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        final done = i < current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: (active || done) ? teal : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _StepConfirm extends StatelessWidget {
  const _StepConfirm({
    required this.state,
    required this.tenant,
    required this.fmt,
    required this.onSurface,
    required this.teal,
    required this.context,
  });

  final _SheetState state;
  final TenantRecord tenant;
  final DateFormat fmt;
  final Color onSurface;
  final Color teal;
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'End Tenancy',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${tenant.tenantName} · ${tenant.unitLabel}',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
        const SizedBox(height: 20),
        Text(
          'End date',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: onSurface,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        _DatePickerButton(
          date: state.endDate,
          fmt: fmt,
          teal: teal,
          onPick: (d) => state.setEndDate(d),
          context: context,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'The unit will be marked vacant and smart gap detection will activate.',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton({
    required this.date,
    required this.fmt,
    required this.teal,
    required this.onPick,
    required this.context,
  });

  final DateTime date;
  final DateFormat fmt;
  final Color teal;
  final void Function(DateTime) onPick;
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('en', 'GB'),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: teal.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: teal, size: 18),
            const SizedBox(width: 8),
            Text(
              fmt.format(date),
              style: TextStyle(color: teal, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBalance extends StatelessWidget {
  const _StepBalance({
    required this.state,
    required this.outstandingTsh,
    required this.formatAmount,
    required this.onSurface,
    required this.muted,
  });

  final _SheetState state;
  final int outstandingTsh;
  final String Function(num) formatAmount;
  final Color onSurface;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settle Outstanding Balance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          outstandingTsh > 0
              ? 'Outstanding: ${formatAmount(outstandingTsh)}'
              : 'No outstanding balance',
          style: TextStyle(color: muted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (outstandingTsh <= 0)
          _RadioOption(
            value: 'cleared',
            groupValue: state.balanceHandling,
            label: 'Fully paid — no outstanding balance',
            icon: Icons.check_circle_outline,
            color: Colors.green,
            onChanged: state.setBalanceHandling,
          )
        else ...[
          _RadioOption(
            value: 'cleared',
            groupValue: state.balanceHandling,
            label: 'Mark as cleared (tenant has paid in full)',
            icon: Icons.check_circle_outline,
            color: Colors.green,
            onChanged: state.setBalanceHandling,
          ),
          const SizedBox(height: 8),
          _RadioOption(
            value: 'partial',
            groupValue: state.balanceHandling,
            label: 'Record partial payment',
            icon: Icons.payments_outlined,
            color: Colors.amber.shade700,
            onChanged: state.setBalanceHandling,
          ),
          if (state.balanceHandling == 'partial') ...[
            const SizedBox(height: 8),
            TextField(
              controller: state.partialAmountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText:
                    'Amount paid (${Get.find<CurrencyService>().inputPrefix.trim()})',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          _RadioOption(
            value: 'written_off',
            groupValue: state.balanceHandling,
            label: 'Write off (bad debt)',
            icon: Icons.money_off_outlined,
            color: Colors.red.shade400,
            onChanged: state.setBalanceHandling,
          ),
        ],
      ],
    );
  }
}

class _RadioOption extends StatelessWidget {
  const _RadioOption({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.icon,
    required this.color,
    required this.onChanged,
  });

  final String value;
  final String groupValue;
  final String label;
  final IconData icon;
  final Color color;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? color
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.radio_button_checked, color: color, size: 18)
            else
              Icon(
                Icons.radio_button_off,
                color: Colors.grey.shade400,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

class _StepRate extends StatelessWidget {
  const _StepRate({
    required this.state,
    required this.onSurface,
    required this.muted,
  });

  final _SheetState state;
  final Color onSurface;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate This Tenant',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your rating helps other landlords on the platform.',
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _StarRow(
            label: 'Overall',
            required: true,
            value: state.overallStars,
            onChanged: (v) => state.setStars('overall', v),
          ),
          const SizedBox(height: 12),
          _StarRow(
            label: 'Payment Reliability',
            required: true,
            value: state.paymentStars,
            onChanged: (v) => state.setStars('payment', v),
          ),
          const SizedBox(height: 12),
          _StarRow(
            label: 'Property Care',
            required: false,
            value: state.propertyCareStars,
            onChanged: (v) => state.setStars('care', v),
          ),
          const SizedBox(height: 12),
          _StarRow(
            label: 'Communication',
            required: false,
            value: state.communicationStars,
            onChanged: (v) => state.setStars('communication', v),
          ),
          const SizedBox(height: 16),
          Text(
            'Would you rent to this tenant again?',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ChipChoice(
                label: 'Yes',
                selected: state.rentAgain == 'yes',
                color: Colors.green,
                onTap: () => state.setRentAgain('yes'),
              ),
              const SizedBox(width: 8),
              _ChipChoice(
                label: 'Maybe',
                selected: state.rentAgain == 'maybe',
                color: Colors.amber.shade700,
                onTap: () => state.setRentAgain('maybe'),
              ),
              const SizedBox(width: 8),
              _ChipChoice(
                label: 'No',
                selected: state.rentAgain == 'no',
                color: Colors.red.shade400,
                onTap: () => state.setRentAgain('no'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: state.commentCtrl,
            maxLength: 200,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Comment (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          if (!state.ratingComplete)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '* Overall and Payment Reliability ratings are required.',
                style: TextStyle(color: Colors.red.shade400, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({
    required this.label,
    required this.required,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool required;
  final int value;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            required ? '$label *' : label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
        Row(
          children: List.generate(5, (i) {
            final filled = i < value;
            return GestureDetector(
              onTap: () => onChanged(i + 1),
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: filled ? Colors.amber : Colors.grey.shade400,
                  size: 28,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ChipChoice extends StatelessWidget {
  const _ChipChoice({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : Colors.grey.shade500,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _StepConsent extends StatelessWidget {
  const _StepConsent({
    required this.state,
    required this.tenant,
    required this.onSurface,
    required this.muted,
    required this.teal,
  });

  final _SheetState state;
  final TenantRecord tenant;
  final Color onSurface;
  final Color muted;
  final Color teal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share Tenant Reputation?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Help other landlords on the platform by sharing an anonymous reputation score for ${tenant.tenantName}. '
          'Only aggregated data is shared — your identity and raw payment details remain private. '
          'The score is published 30 days after today.',
          style: TextStyle(color: muted, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: () => state.setShareConsent(!state.shareConsent),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: state.shareConsent
                  ? teal.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: state.shareConsent ? teal : Colors.grey.shade300,
                width: state.shareConsent ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  state.shareConsent
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: state.shareConsent ? teal : Colors.grey.shade400,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share anonymously',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: state.shareConsent ? teal : onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Published after 30-day cooling-off period',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'You can proceed without sharing. The rating is stored privately.',
          style: TextStyle(fontSize: 12, color: muted),
        ),
      ],
    );
  }
}
