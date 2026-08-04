import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../data/help/help_center_models.dart';
import '../controllers/help_center_controller.dart';

class HelpCenterView extends BaseView<HelpCenterController> {
  HelpCenterView({super.key});

  static const _teal = Color(0xFF005F5F);

  String _t(String en, String sw) => controller.isSw ? sw : en;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => CustomAppBar(
        appBarTitleText: _t('Help center', 'Kituo cha msaada'),
        isCentered: true,
      );

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    final headerBg = theme.scaffoldBackgroundColor;

    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Opaque pinned header so list content never paints underneath.
          Material(
            color: headerBg,
            elevation: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Obx(
                    () => TextField(
                      controller: controller.searchController,
                      onChanged: controller.onSearchChanged,
                      decoration: InputDecoration(
                        hintText: _t(
                          'Search guides & features',
                          'Tafuta miongozo na vipengele',
                        ),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: controller.searchQuery.value.isEmpty
                            ? null
                            : IconButton(
                                tooltip: _t('Clear', 'Futa'),
                                icon: const Icon(Icons.clear),
                                onPressed: controller.clearSearch,
                              ),
                        filled: true,
                        fillColor: theme.brightness == Brightness.dark
                            ? theme.colorScheme.surfaceContainerHighest
                            : theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Obx(() => _workspaceChips(context)),
                ),
                const SizedBox(height: 4),
                TabBar(
                  labelColor: _teal,
                  unselectedLabelColor: theme.hintColor,
                  indicatorColor: _teal,
                  dividerColor: theme.dividerColor,
                  tabs: [
                    Tab(text: _t('Guides', 'Miongozo')),
                    Tab(text: _t('Features', 'Vipengele')),
                    Tab(text: _t('Tours', 'Ziara')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              // Keep TabBarView stable — rebuild lists inside Obx only.
              // Recreating TabBarView on search caused content to draw under the header.
              clipBehavior: Clip.hardEdge,
              children: [
                Obx(() => _guidesList(context)),
                Obx(() => _featuresList(context)),
                Obx(() => _toursList(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _workspaceChips(BuildContext context) {
    Widget chip(String label, HelpWorkspace? ws) {
      final selected =
          controller.workspaceFilter.value == (ws ?? HelpWorkspace.both);
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => controller.setWorkspaceFilter(ws),
          selectedColor: _teal.withValues(alpha: 0.15),
          checkmarkColor: _teal,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(_t('All', 'Zote'), null),
          chip('BnB', HelpWorkspace.bnb),
          chip(_t('Rent', 'Kodi'), HelpWorkspace.rent),
        ],
      ),
    );
  }

  Widget _guidesList(BuildContext context) {
    final guides = controller.guides;
    if (guides.isEmpty) {
      return Center(child: Text(_t('No guides found', 'Hakuna miongozo')));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      clipBehavior: Clip.hardEdge,
      itemCount: guides.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final g = guides[i];
        return _GuideCard(
          icon: g.icon,
          title: g.title(controller.isSw),
          subtitle: g.summary(controller.isSw),
          meta: '${g.category(controller.isSw)} · ${g.estimatedMinutes} min',
          workspace: g.workspace,
          onTap: () => controller.openGuide(g.id),
        );
      },
    );
  }

  Widget _featuresList(BuildContext context) {
    final features = controller.features;
    if (features.isEmpty) {
      return Center(child: Text(_t('No features found', 'Hakuna vipengele')));
    }
    final border = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3A3A3C)
        : Colors.grey.shade300;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      clipBehavior: Clip.hardEdge,
      itemCount: features.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final f = features[i];
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: border),
          ),
          leading: Icon(f.icon, color: _teal),
          title: Text(
            f.title(controller.isSw),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(f.description(controller.isSw)),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => controller.openFeature(f),
        );
      },
    );
  }

  Widget _toursList(BuildContext context) {
    final tours = controller.tourGuides;
    final muted = Theme.of(context).hintColor;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      clipBehavior: Clip.hardEdge,
      children: [
        Text(
          _t(
            'Interactive tours navigate to each screen and explain what to do.',
            'Ziara shirikishi zinaelekeza kwenye kila skrini na kuelezea hatua.',
          ),
          style: TextStyle(fontSize: 13, color: muted, height: 1.4),
        ),
        const SizedBox(height: 16),
        ...tours.map(
          (g) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _GuideCard(
              icon: Icons.play_circle_outline,
              title: g.title(controller.isSw),
              subtitle: g.summary(controller.isSw),
              meta: '${g.steps.length} ${_t('steps', 'hatua')}',
              workspace: g.workspace,
              onTap: () => controller.startTour(g.id),
              trailing: FilledButton.icon(
                onPressed: () => controller.startTour(g.id),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: Text(_t('Start', 'Anza')),
                style: FilledButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.workspace,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String meta;
  final HelpWorkspace workspace;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).hintColor;
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: HelpCenterView._teal, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: muted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meta,
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
