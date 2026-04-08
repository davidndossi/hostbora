import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_schedule_maintenance_form_controller.dart';

/// Concierge **Request Maintenance** — property, category, date, priority, description.
class RentScheduleMaintenanceFormView extends BaseView<RentScheduleMaintenanceFormController> {
  RentScheduleMaintenanceFormView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  static const _teal = RentTheme.conciergeTeal;
  static const _fill = Color(0xFFF1F1F1);

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.canvas;

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Panga Matengenezo' : 'Schedule maintenance');

  @override
  Widget body(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _capsLabel('SELECT PROPERTY'),
            const SizedBox(height: 8),
            Obx(
              () => DropdownButtonFormField<String>(
                initialValue: controller.propertyOptions.contains(controller.selectedProperty.value)
                    ? controller.selectedProperty.value
                    : controller.propertyOptions.first,
                decoration: _dropdownDecoration(),
                icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF3D3D3D)),
                items: controller.propertyOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: controller.updateProperty,
                validator: (v) => v == null || v.isEmpty ? (_isSw ? 'Chagua mali' : 'Select a property') : null,
              ),
            ),
            const SizedBox(height: 16),
            _capsLabel('CATEGORY'),
            const SizedBox(height: 8),
            Obx(
              () => DropdownButtonFormField<String>(
                initialValue: controller.categoryOptions.contains(controller.selectedCategory.value)
                    ? controller.selectedCategory.value
                    : controller.categoryOptions.first,
                decoration: _dropdownDecoration(),
                icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF3D3D3D)),
                items: controller.categoryOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: controller.updateCategory,
                validator: (v) => v == null || v.isEmpty ? (_isSw ? 'Chagua kategoria' : 'Select a category') : null,
              ),
            ),
            const SizedBox(height: 16),
            _capsLabel('SCHEDULE DATE'),
            const SizedBox(height: 8),
            TextFormField(
              readOnly: true,
              controller: controller.scheduleDateFieldController,
              onTap: () => controller.pickScheduleDate(context),
              decoration: InputDecoration(
                filled: true,
                fillColor: _fill,
                hintText: _isSw ? 'dd/mm/yyyy' : 'mm/dd/yyyy',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                suffixIcon: Icon(Icons.calendar_today_outlined, color: _teal.withValues(alpha: 0.85), size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              ),
              validator: (_) => controller.scheduleDate.value == null ? (_isSw ? 'Chagua tarehe' : 'Pick a date') : null,
            ),
            const SizedBox(height: 16),
            _capsLabel('PRIORITY LEVEL'),
            const SizedBox(height: 10),
            Obx(() => _priorityRow()),
            const SizedBox(height: 16),
            _capsLabel('ISSUE DESCRIPTION'),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.descriptionController,
              minLines: 4,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                filled: true,
                fillColor: _fill,
                hintText: _isSw ? 'Elezea kwa ufupi matengenezo yanayohitajika...' : 'Briefly describe the maintenance required...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return _isSw ? 'Elezea tatizo' : 'Describe the issue';
                return null;
              },
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: controller.scheduleTask,
                icon: const Icon(Icons.event_available_rounded, size: 22),
                label: Text(
                  _isSw ? 'Panga Kazi' : 'Schedule Task',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.3),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 28),
            _premiumSupportCard(),
          ],
        ),
      ),
    );
  }

  Widget _priorityRow() {
    final p = controller.priority.value;
    Widget seg(String key, String label) {
      final sel = p == key;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: sel ? _teal : _fill,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => controller.setPriority(key),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: sel ? Colors.white : const Color(0xFF374151),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        seg('low', _isSw ? 'Chini' : 'Low'),
        seg('medium', _isSw ? 'Wastani' : 'Medium'),
        seg('high', _isSw ? 'Juu' : 'High'),
      ],
    );
  }

  Widget _premiumSupportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _teal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: Colors.white.withValues(alpha: 0.95), size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSw ? 'Msaada wa Kipaumbele' : 'Premium Support',
                  style: TextStyle(
                    
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSw
                      ? 'Kazi za kipaumbele cha juu zinaelekezwa kwa timu yetu ya mwitikio wa haraka mara tu zinapopangwa.'
                      : 'High priority tasks are routed to our rapid response team immediately upon scheduling.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _capsLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        letterSpacing: 1.15,
        fontWeight: FontWeight.w800,
        color: Colors.grey.shade700,
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: _fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }
}
