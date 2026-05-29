import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../../../core/theme/form_surface_colors.dart';
import '../../../../core/widget/loading_button.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_schedule_maintenance_form_controller.dart';

/// Concierge **Request Maintenance** — property, category, date, priority, description.
class RentScheduleMaintenanceFormView extends RentBaseView<RentScheduleMaintenanceFormController> {
  RentScheduleMaintenanceFormView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  static const _teal = RentTheme.conciergeTeal;

  @override
  Color pageBackgroundColor(BuildContext context) {
    return FormSurfaceColors.of(context).scaffold;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Panga Matengenezo' : 'Schedule maintenance');

  @override
  Widget body(BuildContext context) {
    final c = FormSurfaceColors.of(context);

    return Form(
      key: controller.formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              _isSw ? 'Hakikisha mali yako inasalia katika hali safi. Jaza mahitaji hapa chini' : 'Ensure your properties remain in pristine condition. Fill the requirements below',
              style: TextStyle(
                fontSize: 14,
                color: c.secondary,
              ),
            ),
            const SizedBox(height: 16),
            _capsLabel('Select property', colors: c),
            const SizedBox(height: 8),
            Obx(() {
              final hasProperties = controller.hasProperties;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                      '${controller.propertyOptions.length}:${controller.selectedProperty.value}',
                    ),
                    initialValue: controller.propertyOptions.contains(controller.selectedProperty.value)
                        ? controller.selectedProperty.value
                        : null,
                    isExpanded: true,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: c.headline,
                    ),
                    dropdownColor: c.dropdownBg,
                    decoration: _dropdownDecoration(c),
                    icon: Icon(Icons.expand_more_rounded, color: c.secondary),
                    items: controller.propertyOptions
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e, style: TextStyle(color: c.headline)),
                          ),
                        )
                        .toList(),
                    onChanged: hasProperties ? controller.updateProperty : null,
                    validator: controller.validateSelectedProperty,
                  ),
                  if (!hasProperties)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 2),
                      child: Text(
                        _isSw
                            ? 'Bado hakuna mjengo — ongeza mjengo kwanza.'
                            : 'No properties yet — add a property first.',
                        style: TextStyle(fontSize: 12, color: c.hint),
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(height: 16),
            _capsLabel('Category', colors: c),
            const SizedBox(height: 8),
            Obx(
              () => DropdownButtonFormField<String>(
                initialValue: controller.categoryOptions.contains(controller.selectedCategory.value)
                    ? controller.selectedCategory.value
                    : controller.categoryOptions.first,
                isExpanded: true,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: c.headline,
                ),
                dropdownColor: c.dropdownBg,
                decoration: _dropdownDecoration(c),
                icon: Icon(Icons.expand_more_rounded, color: c.secondary),
                items: controller.categoryOptions
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: TextStyle(color: c.headline)),
                      ),
                    )
                    .toList(),
                onChanged: controller.updateCategory,
                validator: (v) => v == null || v.isEmpty ? (_isSw ? 'Chagua kategoria' : 'Select a category') : null,
              ),
            ),
            const SizedBox(height: 16),
            _capsLabel('Schedule date', colors: c),
            const SizedBox(height: 8),
            TextFormField(
              readOnly: true,
              controller: controller.scheduleDateFieldController,
              style: TextStyle(color: c.headline),
              onTap: () => controller.pickScheduleDate(context),
              decoration: InputDecoration(
                filled: true,
                fillColor: c.fill,
                hintText: _isSw ? 'dd/MM/yyyy' : 'dd/MM/yyyy',
                hintStyle: TextStyle(color: c.hint),
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
            _capsLabel('Priority level', colors: c),
            const SizedBox(height: 10),
            Obx(() => _priorityRow(colors: c)),
            const SizedBox(height: 16),
            _capsLabel('Issue description', colors: c),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.descriptionController,
              minLines: 4,
              maxLines: 8,
              style: TextStyle(color: c.headline),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                filled: true,
                fillColor: c.fill,
                hintText: _isSw ? 'Elezea kwa ufupi matengenezo yanayohitajika...' : 'Briefly describe the maintenance required...',
                hintStyle: TextStyle(color: c.hint),
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
            Obx(
              () => LoadingButton(
                label: _isSw ? 'Panga kazi' : 'Schedule task',
                onPressed: controller.scheduleTask,
                isLoading: controller.saving.value,
                icon: Icons.event_available_rounded,
                minimumSize: const Size.fromHeight(54),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
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

  Widget _priorityRow({required FormSurfaceColors colors}) {
    final p = controller.priority.value;
    final priorityIdleBg = colors.isDark ? colors.fill : colors.chipUnselectedBg;
    final priorityIdleText = colors.headline;

    Widget seg(String key, String label) {
      final sel = p == key;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: sel ? _teal : priorityIdleBg,
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
                    color: sel ? Colors.white : priorityIdleText,
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

  Widget _capsLabel(String text, {required FormSurfaceColors colors}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        letterSpacing: 1.15,
        fontWeight: FontWeight.w800,
        color: colors.sectionLabel,
      ),
    );
  }

  InputDecoration _dropdownDecoration(FormSurfaceColors colors) {
    return InputDecoration(
      filled: true,
      fillColor: colors.fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }
}
