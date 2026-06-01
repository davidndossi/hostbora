import 'package:flutter/material.dart';
import 'package:host_bora/app/core/widget/skeleton_presets.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/values/app_decorations.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/staff_detail_controller.dart';

class StaffDetailView extends BaseView<StaffDetailController> {
  StaffDetailView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    final code =
        Get.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return code == 'sw' ? sw : en;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.staffDetail,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      if (controller.loading.value) {
        return const DefaultScreenSkeleton();
      }
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          child: Column(
            children: [
              _buildProfileSection(context),
              const SizedBox(height: 24),
              _buildStatsRow(context),
              if (controller.hasPayInfo) ...[
                const SizedBox(height: 16),
                _buildPayRow(context),
              ],
              if (controller.hasEmail || controller.hasPhone) ...[
                const SizedBox(height: 24),
                _buildSectionTitle(
                  context,
                  _t(
                    context,
                    en: 'Contact Information',
                    sw: 'Taarifa za Mawasiliano',
                  ),
                ),
                const SizedBox(height: 12),
                if (controller.hasEmail)
                  _buildContactRow(
                    context,
                    Icons.email_outlined,
                    _t(context, en: 'Email Address', sw: 'Barua Pepe'),
                    controller.email.value,
                    controller.openEmail,
                  ),
                if (controller.hasEmail && controller.hasPhone)
                  const SizedBox(height: 8),
                if (controller.hasPhone)
                  _buildContactRow(
                    context,
                    Icons.phone_outlined,
                    _t(context, en: 'Phone Number', sw: 'Namba ya Simu'),
                    controller.phone.value,
                    controller.openPhone,
                  ),
              ],
              const SizedBox(height: 24),
              _buildAssignedProperties(context),
              const SizedBox(height: 24),
              _buildSectionTitle(
                context,
                _t(context, en: 'Recent Tasks', sw: 'Kazi za Hivi Karibuni'),
              ),
              const SizedBox(height: 12),
              _buildRecentTasks(context),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.assignNewTask,
                  icon: const Icon(Icons.add, size: 20, color: Colors.white),
                  label: Text(
                    _t(context, en: 'Assign New Task', sw: 'Pangia Kazi Mpya'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.colorPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppValues.radius_6),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: controller.removeFromTeam,
                child: Text(
                  _t(context, en: 'Remove from Team', sw: 'Ondoa Kwenye Timu'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.paaYanguAlert,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildProfileSection(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.lightGreyColor,
          backgroundImage: controller.member.avatarUrl.isNotEmpty
              ? NetworkImage(controller.member.avatarUrl)
              : null,
          child: controller.member.avatarUrl.isEmpty
              ? Text(
                  controller.displayName.value.isNotEmpty
                      ? controller.displayName.value[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColorSecondary,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          controller.displayName.value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textColorPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (controller.role.value.trim().isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.colorPrimaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              controller.role.value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.colorPrimary,
                letterSpacing: 0.3,
              ),
            ),
          ),
        if (controller.joinedLabel.value.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${_t(context, en: 'Joined', sw: 'Amejiunga')} ${controller.joinedLabel.value}',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textColorSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPayRow(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card,
      child: Row(
        children: [
          Icon(Icons.payments_outlined, color: AppColors.colorPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appLocalization.staffDetailPayLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textColorSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  controller.payLine.value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColorPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDecorations.card,
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 28,
                  color: AppColors.colorPrimary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t(context, en: 'TOTAL TASKS', sw: 'JUMLA YA KAZI'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColorSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${controller.totalTasks.value}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textColorPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textColorPrimary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildContactRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppDecorations.card,
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.textColorSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textColorSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textColorPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textColorSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignedProperties(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(
              context,
              _t(context, en: 'Assigned Properties', sw: 'Mali Zilizopangiwa'),
            ),
            GestureDetector(
              onTap: controller.manageProperties,
              child: Text(
                _t(context, en: 'Manage', sw: 'Simamia'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.colorPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (controller.assignedProperties.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: AppDecorations.card,
            child: Text(
              appLocalization.staffDetailNoProperties,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textColorSecondary,
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.assignedProperties.length,
              separatorBuilder: (_, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final p = controller.assignedProperties[index];
                return SizedBox(
                  width: 160,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: AppDecorations.card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            color: AppColors.lightGreyColor.withValues(
                              alpha: 0.5,
                            ),
                            child: Icon(
                              Icons.home_work_outlined,
                              size: 32,
                              color: AppColors.designPlaceholder,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textColorPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.location,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textColorSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRecentTasks(BuildContext context) {
    if (controller.recentTasks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.card,
        child: Text(
          appLocalization.staffDetailNoTasks,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textColorSecondary,
          ),
        ),
      );
    }

    return Column(
      children: controller.recentTasks.map((t) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: AppDecorations.card,
          child: Row(
            children: [
              Icon(Icons.check_circle, size: 22, color: AppColors.colorPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColorPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.completedAt,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textColorSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
