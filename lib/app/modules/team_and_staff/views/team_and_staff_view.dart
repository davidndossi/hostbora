import 'package:flutter/material.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/theme/form_surface_colors.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/skeleton_presets.dart';
import '../../../core/widget/staff_quick_actions_sheet.dart';
import '../controllers/team_and_staff_controller.dart';

class TeamAndStaffView extends BaseView<TeamAndStaffController> {
  TeamAndStaffView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.teamAndStaff,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildSearchBar(context),
          Expanded(
            child: Obx(() {
              if (controller.loadingStaff.value &&
                  controller.staffList.isEmpty &&
                  controller.managers.isEmpty) {
                return const DefaultScreenSkeleton();
              }
              final list = controller.filteredStaff;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                children: [
                  if (!controller.isPortfolioManagerSession.value) ...[
                    _buildManagersSection(context),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    _t(context, en: 'Staff', sw: 'Wafanyakazi'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        _t(
                          context,
                          en: 'No staff yet. Add people from Rent → Staff management.',
                          sw:
                              'Hakuna wafanyakazi bado. Ongeza kutoka Kodi → Usimamizi wa wafanyakazi.',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: context.tokens.textSecondary,
                        ),
                      ),
                    )
                  else
                    ...List.generate(list.length, (index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == list.length - 1 ? 0 : 12,
                        ),
                        child: _StaffCard(
                          member: list[index],
                          onTap: controller.openStaffDetail,
                          onMessage: controller.messageStaff,
                          onEdit: controller.editStaff,
                        ),
                      );
                    }),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildManagersSection(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                appLocalization.portfolioManagers,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _openInviteManagerSheet(context),
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: Text(appLocalization.inviteManager),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          appLocalization.managersFullAccessHint,
          style: TextStyle(
            fontSize: 13,
            color: context.tokens.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (controller.loadingManagers.value &&
              controller.managers.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(minHeight: 2),
            );
          }
          if (controller.managers.isEmpty) {
            return Text(
              appLocalization.noManagersInvited,
              style: TextStyle(
                fontSize: 14,
                color: context.tokens.textSecondary,
              ),
            );
          }
          return Column(
            children: controller.managers.map((m) {
              final title =
                  m.fullName.trim().isEmpty ? m.phone : m.fullName.trim();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: c.isDark
                      ? const Color(0xFF1F1F1F)
                      : AppColors.colorWhite,
                  borderRadius: BorderRadius.circular(AppValues.radius_6),
                  border: Border.all(color: c.inputBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (m.phone.isNotEmpty)
                            Text(
                              m.phone,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.tokens.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => controller.revokeManager(m),
                      child: Text(appLocalization.revokeManagerAccess),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  void _openInviteManagerSheet(BuildContext context) {
    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                appLocalization.inviteManager,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                appLocalization.managerInvitePhoneHint,
                style: TextStyle(
                  fontSize: 13,
                  color: context.tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.inviteNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: _t(context, en: 'Full name', sw: 'Jina kamili'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.invitePhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: _t(context, en: 'Phone number', sw: 'Namba ya simu'),
                  hintText: '07XXXXXXXX',
                ),
              ),
              const SizedBox(height: 20),
              Obx(() {
                final busy = controller.invitingManager.value;
                return ElevatedButton(
                  onPressed: busy ? null : controller.inviteManager,
                  child: busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(appLocalization.sendInvite),
                );
              }),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.searchController,
              onChanged: controller.onSearchChanged,
              decoration: InputDecoration(
                hintText: _t(
                  context,
                  en: 'Search staff members...',
                  sw: 'Tafuta wafanyakazi...',
                ),
                hintStyle: TextStyle(
                  color: FormSurfaceColors.of(context).isDark
                      ? Colors.white70
                      : AppColors.designPlaceholder,
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: FormSurfaceColors.of(context).isDark
                      ? Colors.white70
                      : AppColors.designPlaceholder,
                  size: 22,
                ),
                filled: true,
                fillColor: FormSurfaceColors.of(context).isDark
                    ? const Color(0xFF1F1F1F)
                    : AppColors.colorWhite,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppValues.radius_6),
                  borderSide: BorderSide(
                    color: FormSurfaceColors.of(context).inputBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppValues.radius_6),
                  borderSide: BorderSide(
                    color: FormSurfaceColors.of(context).inputBorder,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: AppColors.colorPrimary,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              onTap: controller.addStaff,
              borderRadius: BorderRadius.circular(28),
              child: const SizedBox(
                width: 56,
                height: 56,
                child: Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final StaffMember member;
  final ValueChanged<StaffMember> onTap;
  final ValueChanged<StaffMember> onMessage;
  final ValueChanged<StaffMember> onEdit;

  const _StaffCard({
    required this.member,
    required this.onTap,
    required this.onMessage,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(member),
        onLongPress: () => showStaffQuickActionsSheet(
          context: context,
          staffName: member.name,
          onEdit: () => onEdit(member),
          onRemove: () => onTap(member),
        ),
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
            borderRadius: BorderRadius.circular(AppValues.radius_12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: c.isDark ? 0.28 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.lightGreyColor,
                    backgroundImage: member.avatarUrl.isNotEmpty
                        ? NetworkImage(member.avatarUrl)
                        : null,
                    child: member.avatarUrl.isEmpty
                        ? Text(
                            member.name.isNotEmpty
                                ? member.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: c.isDark
                                  ? Colors.white70
                                  : AppColors.textColorSecondary,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: member.isOnDuty
                            ? AppColors.colorSuccessGreen
                            : AppColors.textColorSecondary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c.isDark
                              ? const Color(0xFF1F1F1F)
                              : AppColors.colorWhite,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.role,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.colorPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          member.isHighTaskCount
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline,
                          size: 16,
                          color: member.isHighTaskCount
                              ? AppColors.colorOrange
                              : AppColors.textColorSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${member.tasksToday} ${Get.locale?.languageCode == 'sw' ? 'Kazi Leo' : 'Tasks Today'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: member.isHighTaskCount
                                ? AppColors.colorOrange
                                : (c.isDark
                                      ? Colors.white70
                                      : AppColors.textColorSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              //   decoration: BoxDecoration(
              //     color: member.isOnDuty
              //         ? AppColors.colorPrimaryLight
              //         : AppColors.lightGreyColor.withOpacity(0.6),
              //     borderRadius: BorderRadius.circular(6),
              //   ),
              //   child: Text(
              //     member.isOnDuty ? 'ON DUTY' : 'OFF DUTY',
              //     style: TextStyle(
              //       fontSize: 10,
              //       fontWeight: FontWeight.w600,
              //       letterSpacing: 0.3,
              //       color: member.isOnDuty
              //           ? AppColors.colorSuccessGreen
              //           : AppColors.textColorSecondary,
              //     ),
              //   ),
              // ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => onMessage(member),
                icon: Icon(
                  Icons.chat_bubble_outline,
                  size: 20,
                  color: c.secondary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              IconButton(
                onPressed: () => onEdit(member),
                icon: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: c.secondary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
