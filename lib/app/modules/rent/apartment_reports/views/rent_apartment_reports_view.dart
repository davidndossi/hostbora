import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../../../core/widget/skeleton_presets.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_apartment_reports_controller.dart';
import '../utils/apartment_report_pdf.dart';

class _ReportUi {
  _ReportUi(this.context);

  final BuildContext context;

  bool get dark => Theme.of(context).brightness == Brightness.dark;

  static const Color teal = Color(0xFF0E6666);
  static const Color forest = Color(0xFF004D40);

  Color get onSurface => dark ? const Color(0xFFF2F2F7) : const Color(0xFF101828);
  Color get muted => dark ? const Color(0xFFAEAEB2) : const Color(0xFF6B7280);
  Color get card => dark ? Theme.of(context).cardColor : Colors.white;
  Color get border => dark ? Colors.white12 : const Color(0xFFE5E7EB);
}

class RentApartmentReportsView extends RentBaseView<RentApartmentReportsController> {
  RentApartmentReportsView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar(
        _isSw ? 'Ripoti za Vyumba' : 'Apartment Reports',
      );

  @override
  Widget body(BuildContext context) {
    final u = _ReportUi(context);
    return Obx(() {
      if (controller.loading.value) {
        return const DefaultScreenSkeleton();
      }
      return Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  controller.propertyTitle.value.isEmpty
                      ? (_isSw ? 'Mali' : 'Property')
                      : controller.propertyTitle.value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: u.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isSw
                      ? 'Tengeneza ripoti ya PDF kwa chumba (kodi pekee)'
                      : 'Generate PDF reports per apartment (rent units)',
                  style: TextStyle(fontSize: 13, color: u.muted),
                ),
                const SizedBox(height: 16),
                _unitPicker(u),
                const SizedBox(height: 14),
                _tabs(u),
                const SizedBox(height: 16),
                if (controller.selectedTab.value == ApartmentReportTab.rent)
                  _rentPreview(u)
                else
                  _servicePreview(u),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: controller.exporting.value
                      ? null
                      : controller.generatePdf,
                  icon: controller.exporting.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(
                    controller.selectedTab.value == ApartmentReportTab.rent
                        ? (_isSw
                            ? 'Tengeneza PDF ya kodi'
                            : 'Generate rent PDF')
                        : (_isSw
                            ? 'Tengeneza PDF ya tozo ya huduma'
                            : 'Generate service charge PDF'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _ReportUi.forest,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _unitPicker(_ReportUi u) {
    return rentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'Chagua chumba' : 'Select apartment / unit',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: u.muted,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: controller.selectedUnitKey.value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: controller.unitOptions
                .map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) controller.selectUnit(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _tabs(_ReportUi u) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: u.dark ? Colors.white10 : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabChip(
              u,
              label: _isSw ? 'Ripoti ya kodi' : 'Rent report',
              selected: controller.selectedTab.value == ApartmentReportTab.rent,
              onTap: () => controller.selectTab(ApartmentReportTab.rent),
            ),
          ),
          Expanded(
            child: _tabChip(
              u,
              label: _isSw ? 'Tozo ya huduma' : 'Service charge',
              selected:
                  controller.selectedTab.value == ApartmentReportTab.serviceCharge,
              onTap: () =>
                  controller.selectTab(ApartmentReportTab.serviceCharge),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(
    _ReportUi u, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? _ReportUi.teal : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : u.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _rentPreview(_ReportUi u) {
    final rows = controller.rentRows;
    if (rows.isEmpty) {
      return Text(
        _isSw
            ? 'Hakuna wapangaji kwa chumba kilichochaguliwa.'
            : 'No tenants for the selected apartment.',
        style: TextStyle(color: u.muted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSw ? 'Muhtasari (${rows.length})' : 'Preview (${rows.length})',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: u.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        ...rows.map((r) => _rentCard(u, r)),
      ],
    );
  }

  Widget _rentCard(_ReportUi u, ApartmentRentReportRow r) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: u.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: u.onSurface,
                  ),
                ),
              ),
              _statusChip(r.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_isSw ? 'Chumba' : 'Apt'} ${r.aptNo} · ${_isSw ? 'Kodi' : 'Rent'} ${r.rentPerMonth}/mo',
            style: TextStyle(color: u.muted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          _kv(u, _isSw ? 'Kipindi' : 'Period', '${r.rentPeriod} mo'),
          _kv(u, _isSw ? 'Mwanzo – Mwisho' : 'Start – Expiry',
              '${r.startDate} – ${r.expiryDate}'),
          _kv(u, _isSw ? 'Imelipwa' : 'Amt paid', r.amtPaid),
          _kv(u, _isSw ? 'Salio' : 'Balance', r.balance),
          _kv(u, _isSw ? 'Mpokeaji' : 'Recipient', r.recipient),
          _kv(u, _isSw ? 'Maelezo' : 'Remarks', r.contractRemarks),
        ],
      ),
    );
  }

  Widget _servicePreview(_ReportUi u) {
    final rows = controller.serviceChargeRows;
    if (rows.isEmpty) {
      return Text(
        _isSw
            ? 'Hakuna malipo ya tozo ya huduma.'
            : 'No service charge payments yet.',
        style: TextStyle(color: u.muted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSw ? 'Muhtasari (${rows.length})' : 'Preview (${rows.length})',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: u.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        ...rows.map(
          (r) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: u.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: u.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: u.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                _kv(u, _isSw ? 'Mwezi' : 'Month', r.month),
                _kv(u, _isSw ? 'Kiasi' : 'Amount', r.amount),
                _kv(u, _isSw ? 'Chumba' : 'Apt no', r.aptNo),
                _kv(u, _isSw ? 'Tarehe ya malipo' : 'Date paid', r.datePaid),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _kv(_ReportUi u, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k, style: TextStyle(fontSize: 12, color: u.muted)),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: u.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bg;
    Color fg;
    switch (status.toUpperCase()) {
      case 'PAID':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        break;
      case 'PARTIAL':
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFEF6C00);
        break;
      default:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
