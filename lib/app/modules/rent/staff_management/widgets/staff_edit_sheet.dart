import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/values/app_colors.dart';
import '../controllers/rent_staff_management_controller.dart';
import '../utils/rent_staff_pay_format.dart';

/// Modal edit form for a staff member — always visible when Edit is tapped.
Future<bool?> showStaffEditSheet({
  required RentStaffManagementController controller,
  required RentStaffListItem member,
}) {
  final isSw = Get.locale?.languageCode == 'sw';
  return Get.bottomSheet<bool>(
    _StaffEditSheetBody(controller: controller, member: member, isSw: isSw),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    ignoreSafeArea: false,
  );
}

class _StaffEditSheetBody extends StatefulWidget {
  const _StaffEditSheetBody({
    required this.controller,
    required this.member,
    required this.isSw,
  });

  final RentStaffManagementController controller;
  final RentStaffListItem member;
  final bool isSw;

  @override
  State<_StaffEditSheetBody> createState() => _StaffEditSheetBodyState();
}

class _StaffEditSheetBodyState extends State<_StaffEditSheetBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _payDate;
  late String _paymentType;
  late String _role;
  var _saving = false;

  String _t(String en, String sw) => widget.isSw ? sw : en;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.member.name);
    _payDate = TextEditingController();
    _amount = TextEditingController(
      text: widget.member.amountValue > 0
          ? (widget.member.amountValue.truncateToDouble() ==
                    widget.member.amountValue
                ? widget.member.amountValue.toStringAsFixed(0)
                : widget.member.amountValue.toStringAsFixed(2))
          : '',
    );
    _paymentType =
        RentStaffPayFormat.paymentTypeLabels.containsKey(widget.member.paymentType)
            ? widget.member.paymentType
            : RentStaffPayFormat.monthly;
    _role = widget.member.jobTitle.trim();
    _hydrateFromLocal();
  }

  Future<void> _hydrateFromLocal() async {
    final id = int.tryParse(widget.member.id);
    if (id == null) return;
    final record = await widget.controller.peekStaffRecord(id);
    if (record == null || !mounted) return;
    setState(() {
      _name.text = record.name;
      _payDate.text = record.payDayLabel;
      _paymentType =
          RentStaffPayFormat.paymentTypeLabels.containsKey(record.paymentType)
              ? record.paymentType
              : RentStaffPayFormat.monthly;
      final role = record.jobTitle.trim();
      _role = role;
      if (record.amountValue > 0) {
        _amount.text = record.amountValue.truncateToDouble() == record.amountValue
            ? record.amountValue.toStringAsFixed(0)
            : record.amountValue.toStringAsFixed(2);
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _payDate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_role.trim().isEmpty) {
      Get.snackbar(
        'Error',
        _t('Select a primary role', 'Chagua jukumu la msingi'),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await widget.controller.saveStaffEdits(
      staffId: widget.member.id,
      name: _name.text.trim(),
      role: _role.trim(),
      paymentType: _paymentType,
      amountRaw: _amount.text,
      payDay: _payDate.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final roles = [
      ...RentStaffManagementController.primaryRoleOptions,
      if (_role.isNotEmpty &&
          !RentStaffManagementController.primaryRoleOptions.contains(_role))
        _role,
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _t('Edit staff member', 'Hariri mfanyakazi'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(result: false),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: _t('Full name', 'Jina kamili'),
                            border: const OutlineInputBorder(),
                          ),
                          validator: widget.controller.validateFullName,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _paymentType,
                          decoration: InputDecoration(
                            labelText: _t('Pay type', 'Aina ya malipo'),
                            border: const OutlineInputBorder(),
                          ),
                          items: RentStaffPayFormat.paymentTypeLabels.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _paymentType = v);
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _amount,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: _t('Amount', 'Kiasi'),
                            border: const OutlineInputBorder(),
                          ),
                          validator: widget.controller.validateAmount,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _payDate,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: _t('Pay day (1–31)', 'Siku ya malipo (1–31)'),
                            border: const OutlineInputBorder(),
                            errorMaxLines: 3,
                          ),
                          validator: widget.controller.validatePayDate,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _role.isEmpty ? null : _role,
                          decoration: InputDecoration(
                            labelText: _t('Primary role', 'Jukumu la msingi'),
                            border: const OutlineInputBorder(),
                          ),
                          items: roles
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _role = v);
                          },
                          validator: (v) => (v == null || v.isEmpty)
                              ? _t(
                                  'Select a primary role',
                                  'Chagua jukumu la msingi',
                                )
                              : null,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.colorPrimary,
                              foregroundColor: Colors.white,
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _t('Save changes', 'Hifadhi mabadiliko'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
