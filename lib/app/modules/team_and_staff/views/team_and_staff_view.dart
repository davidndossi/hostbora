import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../routes/app_pages.dart';
import '../controllers/team_and_staff_controller.dart';

class TeamAndStaffView extends BaseView<TeamAndStaffController> {
  TeamAndStaffView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

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
                  controller.staffList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = controller.filteredStaff;
              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
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
                        color: _isDark(context)
                            ? Colors.white70
                            : AppColors.textColorSecondary,
                      ),
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                itemCount: list.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _StaffCard(
                  member: list[index],
                  onTap: controller.openStaffDetail,
                  onMessage: controller.messageStaff,
                  onEdit: controller.editStaff,
                ),
              );
            }),
          ),
        ],
      ),
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
                  color: _isDark(context)
                      ? Colors.white70
                      : AppColors.designPlaceholder,
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: _isDark(context)
                      ? Colors.white70
                      : AppColors.designPlaceholder,
                  size: 22,
                ),
                filled: true,
                fillColor: _isDark(context)
                    ? const Color(0xFF1F1F1F)
                    : AppColors.colorWhite,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppValues.radius_6),
                  borderSide: BorderSide(
                    color: _isDark(context)
                        ? Colors.white.withValues(alpha: 0.18)
                        : AppColors.designInputBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppValues.radius_6),
                  borderSide: BorderSide(
                    color: _isDark(context)
                        ? Colors.white.withValues(alpha: 0.18)
                        : AppColors.designInputBorder,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(member),
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
            borderRadius: BorderRadius.circular(AppValues.radius_12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
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
                              color: isDark
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
                          color: isDark
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
                                : (isDark
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
                  color: isDark ? Colors.white70 : AppColors.textColorSecondary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              IconButton(
                onPressed: () => onEdit(member),
                icon: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: isDark ? Colors.white70 : AppColors.textColorSecondary,
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
