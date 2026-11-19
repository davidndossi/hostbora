import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../data/help/help_center_models.dart';
import '../controllers/help_center_controller.dart';

class HelpCenterView extends BaseView<HelpCenterController> {
  HelpCenterView({super.key});

  Color _accent(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return c.isDark
        ? Theme.of(context).colorScheme.primary
        : AppColors.colorPrimary;
  }

  String _t(String en, String sw) => controller.isSw ? sw : en;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => CustomAppBar(
        appBarTitleText: _t('Help center', 'Kituo cha msaada'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      );

  @override
  Color pageBackgroundColor(BuildContext context) =>
      FormSurfaceColors.of(context).scaffold;

  @override
  Widget body(BuildContext context) {
    final accent = _accent(context);
    final u = FormSurfaceColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('Learn HostBora', 'Jifunze HostBora'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: u.headline,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _t(
                  'Guides, feature shortcuts, and interactive tours — updated for the current app.',
                  'Miongozo, njia za haraka, na ziara — zimesasishwa kwa programu ya sasa.',
                ),
                style: TextStyle(fontSize: 13, height: 1.35, color: u.secondary),
              ),
              const SizedBox(height: 14),
              Obx(
                () => TextField(
                  controller: controller.searchController,
                  onChanged: controller.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: _t(
                      'Search guides & features',
                      'Tafuta miongozo na vipengele',
                    ),
                    prefixIcon: const Icon(Icons.search_outlined),
                    suffixIcon: controller.searchQuery.value.isEmpty
                        ? null
                        : IconButton(
                            tooltip: _t('Clear', 'Futa'),
                            icon: const Icon(Icons.clear_outlined),
                            onPressed: controller.clearSearch,
                          ),
                    filled: true,
                    fillColor: u.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: u.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: u.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Obx(() => _workspaceChips(context, accent)),
              const SizedBox(height: 12),
              Obx(() => _segmentedTabs(context, accent, u)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Obx(() {
            switch (controller.selectedTab.value) {
              case 1:
                return _featuresList(context, accent, u);
              case 2:
                return _toursList(context, accent, u);
              case 0:
              default:
                return _guidesList(context, accent, u);
            }
          }),
        ),
      ],
    );
  }

  Widget _workspaceChips(BuildContext context, Color accent) {
    Widget chip(String label, HelpWorkspace ws) {
      final selected = controller.workspaceFilter.value == ws;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => controller.setWorkspaceFilter(ws),
          selectedColor: accent.withValues(alpha: 0.16),
          labelStyle: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? accent : Theme.of(context).hintColor,
            fontSize: 12,
          ),
          side: BorderSide(
            color: selected ? accent.withValues(alpha: 0.45) : Colors.transparent,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(_t('All', 'Zote'), HelpWorkspace.both),
          chip('BnB', HelpWorkspace.bnb),
          chip(_t('Rent', 'Kodi'), HelpWorkspace.rent),
        ],
      ),
    );
  }

  Widget _segmentedTabs(
    BuildContext context,
    Color accent,
    FormSurfaceColors u,
  ) {
    final labels = [
      _t('Guides', 'Miongozo'),
      _t('Features', 'Vipengele'),
      _t('Tours', 'Ziara'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: u.border),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final selected = controller.selectedTab.value == i;
          return Expanded(
            child: Material(
              color: selected ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => controller.setTab(i),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: selected ? Colors.white : u.secondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _guidesList(
    BuildContext context,
    Color accent,
    FormSurfaceColors u,
  ) {
    final guides = controller.guides;
    if (guides.isEmpty) {
      return _empty(u, _t('No guides found', 'Hakuna miongozo'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      itemCount: guides.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final g = guides[i];
        return _HelpCard(
          icon: g.icon,
          accent: accent,
          surface: u,
          title: g.title(controller.isSw),
          subtitle: g.summary(controller.isSw),
          meta:
              '${g.category(controller.isSw)} · ${g.estimatedMinutes} min · ${g.steps.length} ${_t('steps', 'hatua')}',
          badge: _workspaceBadge(g.workspace),
          onTap: () => controller.openGuide(g.id),
        );
      },
    );
  }

  Widget _featuresList(
    BuildContext context,
    Color accent,
    FormSurfaceColors u,
  ) {
    final grouped = controller.featuresByCategory;
    if (grouped.isEmpty) {
      return _empty(u, _t('No features found', 'Hakuna vipengele'));
    }
    final categories = grouped.keys.toList()..sort();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      itemCount: categories.length,
      itemBuilder: (context, ci) {
        final cat = categories[ci];
        final items = grouped[cat]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cat.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: u.secondary,
                ),
              ),
              const SizedBox(height: 8),
              ...items.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _HelpCard(
                    icon: f.icon,
                    accent: accent,
                    surface: u,
                    title: f.title(controller.isSw),
                    subtitle: f.description(controller.isSw),
                    meta: f.requiresContext == HelpNavContext.none
                        ? _t('Open', 'Fungua')
                        : f.requiresContext == HelpNavContext.tenant
                            ? _t('Select tenant first', 'Chagua mpangaji kwanza')
                            : _t(
                                'Select property first',
                                'Chagua mali kwanza',
                              ),
                    badge: _workspaceBadge(f.workspace),
                    trailing: Icon(
                      f.requiresContext == HelpNavContext.none
                          ? Icons.arrow_forward_ios_outlined
                          : Icons.tune_outlined,
                      size: 16,
                      color: u.secondary,
                    ),
                    onTap: () => controller.openFeature(f),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _toursList(
    BuildContext context,
    Color accent,
    FormSurfaceColors u,
  ) {
    final tours = controller.tourGuides;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
          ),
          child: Text(
            _t(
              'Tours walk you through each screen. If a step needs a property or tenant, you will pick one first.',
              'Ziara zinaelekeza kwenye kila skrini. Ikiwa hatua inahitaji mali au mpangaji, utachagua kwanza.',
            ),
            style: TextStyle(fontSize: 13, height: 1.4, color: u.headline),
          ),
        ),
        const SizedBox(height: 14),
        if (tours.isEmpty)
          _empty(u, _t('No tours found', 'Hakuna ziara'))
        else
          ...tours.map(
            (g) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HelpCard(
                icon: Icons.play_circle_outline,
                accent: accent,
                surface: u,
                title: g.title(controller.isSw),
                subtitle: g.summary(controller.isSw),
                meta: '${g.steps.length} ${_t('steps', 'hatua')}',
                badge: _workspaceBadge(g.workspace),
                trailing: FilledButton(
                  onPressed: () => controller.startTour(g.id),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(_t('Start', 'Anza')),
                ),
                onTap: () => controller.startTour(g.id),
              ),
            ),
          ),
      ],
    );
  }

  String _workspaceBadge(HelpWorkspace ws) {
    switch (ws) {
      case HelpWorkspace.bnb:
        return 'BnB';
      case HelpWorkspace.rent:
        return _t('Rent', 'Kodi');
      case HelpWorkspace.both:
        return _t('All', 'Zote');
    }
  }

  Widget _empty(FormSurfaceColors u, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(message, style: TextStyle(color: u.secondary)),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({
    required this.icon,
    required this.accent,
    required this.surface,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.badge,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color accent;
  final FormSurfaceColors surface;
  final String title;
  final String subtitle;
  final String meta;
  final String badge;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: surface.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: surface.headline,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: surface.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      meta,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: surface.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
