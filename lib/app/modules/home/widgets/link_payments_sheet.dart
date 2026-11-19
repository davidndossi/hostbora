import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/unlinked_payments.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/service/currency_service.dart';
import '../../rent/tenant_ledger_occupancy/controllers/rent_tenant_ledger_occupancy_controller.dart';
import '../../rent/tenant_residency_payment_tracker/controllers/rent_tenant_residency_payment_tracker_controller.dart';
import '../controllers/home_controller.dart';

/// Lets the host attach payments that were recorded without a tenant to the
/// tenant who paid, so they are counted against that tenant's rent months.
Future<void> showLinkPaymentsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => const _LinkPaymentsSheet(),
  );
}

class _LinkPaymentsSheet extends StatefulWidget {
  const _LinkPaymentsSheet();

  @override
  State<_LinkPaymentsSheet> createState() => _LinkPaymentsSheetState();
}

class _LinkPaymentsSheetState extends State<_LinkPaymentsSheet> {
  final _incomeLocal = Get.find<IncomeLocalDataSource>();
  final _tenantLocal = Get.find<TenantLocalDataSource>();

  bool _loading = true;
  bool _changed = false;
  List<TenantRecord> _tenants = const [];
  List<IncomeRecord> _payments = const [];
  final Map<int, int> _picked = {}; // income id -> tenant id
  final Set<int> _saving = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    if (_changed) _refreshAround();
    super.dispose();
  }

  /// Everything that totals rent from payments needs to re-read.
  Future<void> _refreshAround() async {
    await HomeController.refreshIfRegistered();
    await RentTenantResidencyPaymentTrackerController.refreshIfRegistered();
    await RentTenantLedgerOccupancyController.refreshIfRegistered();
  }

  Future<void> _load() async {
    try {
      final tenants = await _tenantLocal.getAllNewestFirst();
      final incomes = await _incomeLocal.getAllNewestFirst();
      final unlinked = await UnlinkedPayments.find(
        tenants: tenants,
        incomes: incomes,
      );
      tenants.sort(
        (a, b) =>
            a.tenantName.toLowerCase().compareTo(b.tenantName.toLowerCase()),
      );
      if (!mounted) return;
      setState(() {
        _tenants = tenants;
        _payments = unlinked;
        for (final p in unlinked) {
          final guess = _suggest(p, tenants);
          if (guess != null) _picked[p.id] = guess.id;
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Pre-select a tenant only when it is unambiguous.
  static TenantRecord? _suggest(IncomeRecord p, List<TenantRecord> tenants) {
    final name = p.tenantName.trim().toLowerCase();
    if (name.isNotEmpty) {
      final named = tenants
          .where((t) => t.tenantName.trim().toLowerCase() == name)
          .toList();
      if (named.length == 1) return named.first;
    }
    final ref = p.propertyRef.trim();
    if (ref.isNotEmpty) {
      final onProperty = tenants
          .where((t) => t.propertyRef.trim() == ref)
          .toList();
      if (onProperty.length == 1) return onProperty.first;
    }
    return null;
  }

  Future<void> _link(IncomeRecord payment) async {
    final tenantId = _picked[payment.id];
    final tenant = _tenants.where((t) => t.id == tenantId).firstOrNull;
    if (tenant == null || _saving.contains(payment.id)) return;
    setState(() => _saving.add(payment.id));
    try {
      await _incomeLocal.linkToTenant(
        incomeId: payment.id,
        tenantId: tenant.id,
        tenantName: tenant.tenantName,
        propertyRef: tenant.propertyRef,
        apartment: tenant.propertyLabel,
        apartmentUnit: tenant.unitLabel,
      );
      _changed = true;
      if (!mounted) return;
      setState(() {
        _payments = _payments.where((p) => p.id != payment.id).toList();
        _saving.remove(payment.id);
      });
      if (_payments.isEmpty && mounted) Navigator.of(context).maybePop();
    } catch (_) {
      if (mounted) setState(() => _saving.remove(payment.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = Localizations.localeOf(context).languageCode == 'sw';
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height * 0.85),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSw
                  ? 'Unganisha malipo na mpangaji'
                  : 'Link payments to a tenant',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSw
                  ? 'Malipo haya hayana mpangaji, kwa hiyo hayahesabiwi kwenye kodi. Chagua aliyelipa.'
                  : 'These payments have no tenant, so they are not counted toward rent. Pick who paid.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_payments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  isSw
                      ? 'Hakuna malipo yasiyounganishwa.'
                      : 'No unlinked payments.',
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _payments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) =>
                      _paymentCard(context, _payments[i], isSw),
                ),
              ),
            if (_tenants.isEmpty && !_loading) ...[
              const SizedBox(height: 12),
              Text(
                isSw
                    ? 'Ongeza mpangaji kwanza ili uweze kuunganisha malipo.'
                    : 'Add a tenant first so payments can be linked.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _paymentCard(BuildContext context, IncomeRecord p, bool isSw) {
    final theme = Theme.of(context);
    final cs = Get.find<CurrencyService>();
    final picked = _picked[p.id];
    final busy = _saving.contains(p.id);
    final place = [
      if (p.apartment.trim().isNotEmpty) p.apartment.trim(),
      if (p.apartmentUnit.trim().isNotEmpty) p.apartmentUnit.trim(),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${cs.baseCurrency.value} ${cs.formatNumber(p.amountValue)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                p.datePaidIso.length >= 10
                    ? p.datePaidIso.substring(0, 10)
                    : p.datePaidIso,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          if (p.category.trim().isNotEmpty || place.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              [
                if (p.category.trim().isNotEmpty) p.category.trim(),
                if (place.isNotEmpty) place,
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            initialValue: picked,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              hintText: isSw ? 'Chagua mpangaji' : 'Select tenant',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: [
              for (final t in _tenants)
                DropdownMenuItem<int>(
                  value: t.id,
                  child: Text(
                    [
                      t.tenantName.trim(),
                      if (t.unitLabel.trim().isNotEmpty) t.unitLabel.trim(),
                      if (t.propertyLabel.trim().isNotEmpty)
                        t.propertyLabel.trim(),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: busy
                ? null
                : (v) => setState(() {
                    if (v == null) {
                      _picked.remove(p.id);
                    } else {
                      _picked[p.id] = v;
                    }
                  }),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.colorPrimary,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: picked == null || busy ? null : () => _link(p),
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isSw ? 'Unganisha' : 'Link'),
            ),
          ),
        ],
      ),
    );
  }
}
