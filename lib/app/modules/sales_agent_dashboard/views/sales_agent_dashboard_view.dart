import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../data/model/sales_agent_models.dart';
import '../controllers/sales_agent_dashboard_controller.dart';

class _P {
  const _P({
    required this.surface,
    required this.canvas,
    required this.ink,
    required this.sub,
    required this.line,
    required this.teal,
    required this.tint,
    required this.night,
  });

  final Color surface;
  final Color canvas;
  final Color ink;
  final Color sub;
  final Color line;
  final Color teal;
  final Color tint;
  final bool night;

  static _P of(BuildContext context) {
    final night = Theme.of(context).brightness == Brightness.dark;
    if (night) {
      return const _P(
        surface: Color(0xFF192C27),
        canvas: Color(0xFF10211D),
        ink: Color(0xFFE2EEE8),
        sub: Color(0xFF9CAFA6),
        line: Color(0xFF2D4239),
        teal: Color(0xFF72BBAA),
        tint: Color(0xFF233D33),
        night: true,
      );
    }
    return const _P(
      surface: Color(0xFFFFFFFF),
      canvas: Color(0xFFF7F9F8),
      ink: Color(0xFF233D38),
      sub: Color(0xFF7B8985),
      line: Color(0xFFE8EEEB),
      teal: Color(0xFF207568),
      tint: Color(0xFFEDF5F1),
      night: false,
    );
  }
}

class SalesAgentDashboardView extends BaseView<SalesAgentDashboardController> {
  SalesAgentDashboardView({super.key});

  String _t(String en, String sw) =>
      Get.locale?.languageCode == 'sw' ? sw : en;

  @override
  Color pageBackgroundColor(BuildContext context) => _P.of(context).canvas;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  @override
  Widget? bottomNavigationBar() {
    return Obx(() {
      final context = Get.context;
      final p = context != null
          ? _P.of(context)
          : const _P(
              surface: Color(0xFFFFFFFF),
              canvas: Color(0xFFF7F9F8),
              ink: Color(0xFF233D38),
              sub: Color(0xFF7B8985),
              line: Color(0xFFE8EEEB),
              teal: Color(0xFF207568),
              tint: Color(0xFFEDF5F1),
              night: false,
            );
      final selected = controller.selectedTab.value;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(top: BorderSide(color: p.line)),
        ),
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(25, 11, 25, 15),
          child: Row(
            children: [
              Expanded(
                child: _navItem(
                  p,
                  icon: Icons.grid_view_rounded,
                  label: _t('Dashboard', 'Dashibodi'),
                  selected: selected == 0,
                  onTap: () {
                    controller.selectedTab.value = 0;
                    controller.closeUser();
                  },
                ),
              ),
              const SizedBox(width: 30),
              Expanded(
                child: _navItem(
                  p,
                  icon: Icons.people_outline,
                  label: _t('Users', 'Watumiaji'),
                  selected: selected == 1,
                  onTap: () => controller.selectedTab.value = 1,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _navItem(
    _P p, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? p.tint : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 21, color: selected ? p.teal : p.sub),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? p.teal : p.sub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    final p = _P.of(context);
    return ColoredBox(
      color: p.canvas,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(context, p),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.dashboard.value == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final dash = controller.dashboard.value;
                if (dash == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _t(
                              'No dashboard data',
                              'Hakuna data ya dashibodi',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: p.ink),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: controller.confirmSignOut,
                            child: Text(_t('Logout', 'Ondoka')),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: controller.loadDashboard,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 105),
                    children: [
                      if (controller.selectedTab.value == 1 &&
                          controller.selectedCustomer.value != null)
                        _memberProfile(
                          p,
                          dash,
                          controller.selectedCustomer.value!,
                        )
                      else ...[
                        _welcome(p),
                        const SizedBox(height: 22),
                        if (controller.selectedTab.value == 0) ...[
                          _identityCard(p, dash),
                          const SizedBox(height: 20),
                          _collections(p, dash),
                          const SizedBox(height: 20),
                          _plans(p, dash),
                          const SizedBox(height: 20),
                          _growthBanner(p),
                        ] else
                          _usersPanel(p, dash),
                        const SizedBox(height: 23),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user_outlined, size: 14, color: p.sub),
                            const SizedBox(width: 6),
                            Text(
                              controller.selectedTab.value == 1 &&
                                      dash.customers.isNotEmpty
                                  ? _t(
                                      'Every connection is a step forward.',
                                      'Kila muunganisho ni hatua mbele.',
                                    )
                                  : _t(
                                      'Your connections. Your growth.',
                                      'Miunganisho yako. Ukuaji wako.',
                                    ),
                              style: TextStyle(fontSize: 11, color: p.sub),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, _P p) {
    final themeController =
        Get.isRegistered<ThemeController>() ? Get.find<ThemeController>() : null;
    return Container(
      height: 73,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.line)),
      ),
      child: Row(
        children: [
          if (Navigator.of(context).canPop())
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back_ios_new, size: 16, color: p.ink),
            ),
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: const Color(0xFF207568),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.grid_view_rounded, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text(
            'Agent',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w600,
              letterSpacing: -1.2,
              color: p.ink,
            ),
          ),
          Text(
            '.',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w600,
              color: p.teal,
            ),
          ),
          const Spacer(),
          if (themeController != null)
            Obx(
              () => IconButton(
                tooltip: themeController.isDarkMode.value
                    ? _t('Use light theme', 'Tumia mandhari ya mwanga')
                    : _t('Use dark theme', 'Tumia mandhari ya giza'),
                onPressed: themeController.toggleTheme,
                icon: Icon(
                  themeController.isDarkMode.value
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  size: 20,
                  color: p.sub,
                ),
              ),
            ),
          IconButton(
            tooltip: _t('Language', 'Lugha'),
            onPressed: controller.showLanguagePicker,
            icon: Icon(Icons.language, size: 20, color: p.sub),
          ),
          IconButton(
            tooltip: _t('Logout', 'Ondoka'),
            onPressed: controller.confirmSignOut,
            icon: Icon(Icons.logout_outlined, size: 20, color: p.sub),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: controller.showInviteQr,
            customBorder: const CircleBorder(),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE6EFE8),
                shape: BoxShape.circle,
                border: Border.all(color: p.surface, width: 3),
                boxShadow: [
                  BoxShadow(color: p.line, spreadRadius: 1),
                ],
              ),
              child: Obx(
                () => Text(
                  controller.initials,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF38735B),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _welcome(_P p) {
    final isUsers = controller.selectedTab.value == 1;
    final name = controller.firstName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: p.teal, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(
              _t('YOUR AGENT WORKSPACE', 'DAWATI LA WAKALA'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.5,
                letterSpacing: 1.6,
                color: p.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          isUsers
              ? _t('Your growing community.', 'Jamii yako inayokua.')
              : name.isEmpty
                  ? _t('Looking good.', 'Unaonekana vizuri.')
                  : _t('Looking good, $name.', 'Unaonekana vizuri, $name.'),
          style: TextStyle(
            fontSize: 27,
            height: 1.3,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.9,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          isUsers
              ? _t(
                  'Every connection is the beginning of something great.',
                  'Kila muunganisho ni mwanzo wa kitu kikubwa.',
                )
              : _t(
                  'Small connections. Bigger possibilities. Here’s your overview.',
                  'Miunganisho midogo. Fursa kubwa. Hii ni muhtasari wako.',
                ),
          style: TextStyle(fontSize: 11, height: 1.7, color: p.sub),
        ),
      ],
    );
  }

  Widget _identityCard(_P p, SalesAgentDashboard dash) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 23, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D6C60),
        borderRadius: BorderRadius.circular(14),
        gradient: const RadialGradient(
          center: Alignment(0.4, 2.2),
          radius: 1.15,
          colors: [Color(0xFF388676), Color(0xFF1D6C60)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x10164F40), blurRadius: 20, offset: Offset(0, 7)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.19)),
                    ),
                    child: Text(
                      controller.initials,
                      style: const TextStyle(
                        color: Color(0xFFE1F1E7),
                        fontSize: 21,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: 1,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD5EACB),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF216F62), width: 3),
                      ),
                      child: const Icon(Icons.check, size: 9, color: Color(0xFF22694C)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR AGENT PROFILE',
                      style: TextStyle(
                        color: Color(0xFFB5D5CB),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            dash.agent.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                              letterSpacing: -0.224
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_outlined, size: 16, color: Color(0xFFB6D4C5)),
                      ],
                    ),
                    const SizedBox(height: 9),
                    GestureDetector(
                      onTap: controller.copyReferralCode,
                      child: Row(
                        children: [
                          Text(
                            dash.agent.agentCode,
                            style: const TextStyle(
                              color: Color(0xFFD6EAE3),
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.copy_outlined, size: 14, color: Color(0xFFA8CFC1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => FilledButton(
                    onPressed: controller.isInviting.value
                        ? null
                        : controller.showInviteShare,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF2F7EE),
                      foregroundColor: const Color(0xFF23634F),
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (controller.isInviting.value)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          const Icon(Icons.chat_outlined, size: 16),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _t('Invite on WhatsApp', 'Alika WhatsApp'),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, height: 1.5),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.north_east, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              FilledButton(
                onPressed: controller.showInviteQr,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.03),
                  foregroundColor: const Color(0xFFEDF5EF),
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_2, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _t('Show QR', 'Onyesha QR'),
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _panel(_P p, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: p.line),
      ),
      child: child,
    );
  }

  Widget _sectionHeading(
    _P p, {
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(fontSize: 10, color: p.sub)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _collections(_P p, SalesAgentDashboard dash) {
    final amount = controller.formatTzsExact(dash.amountCollectedTzs);
    return _panel(
      p,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            p,
            title: _t('Collections overview', 'Muhtasari wa makusanyo'),
            subtitle: _t('A little progress, every day.', 'Maendeleo kidogo, kila siku.'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: p.canvas,
                border: Border.all(color: p.line),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _t('THIS MONTH', 'MWEZI HUU'),
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: p.sub,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 19),
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            decoration: BoxDecoration(
              color: p.tint,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: p.line),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Total amount collected', 'Jumla iliyokusanywa'),
                      style: TextStyle(fontSize: 11, color: p.teal),
                    ),
                    const SizedBox(height: 11),
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: 36,
                        height: 1.15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -1.6,
                        color: p.teal,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      dash.amountCollectedTzs == 0
                          ? _t(
                              'Your next collection starts something great.',
                              'Ukusanyaji wako ujao unaanza kitu kikubwa.',
                            )
                          : _t(
                              'Keep going — your network is paying off.',
                              'Endelea — mtandao wako unazaa matunda.',
                            ),
                      style: TextStyle(fontSize: 10, color: p.sub),
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDFECE4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined, size: 21, color: Color(0xFF427D67)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 23, 20, 23),
            child: Row(
              children: [
                Expanded(
                  child: _commissionCell(
                    p,
                    icon: Icons.call_received,
                    label: _t('Monthly commission', 'Kamisheni ya mwezi'),
                    value: controller.formatTzsExact(dash.commissionThisMonthTzs),
                    caption: dash.periodMonth.isEmpty
                        ? _t('This period', 'Kipindi hiki')
                        : controller.periodLabel(dash.periodMonth),
                  ),
                ),
                Container(width: 1, height: 72, color: p.line),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: _commissionCell(
                      p,
                      icon: Icons.account_balance_wallet_outlined,
                      label: _t('Lifetime commission', 'Kamisheni yote'),
                      value: controller.formatTzsExact(dash.commissionApprovedTzs),
                      caption: _t(
                        'All your earnings, together',
                        'Mapato yako yote, pamoja',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _commissionCell(
    _P p, {
    required IconData icon,
    required String label,
    required String value,
    required String caption,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: const Color(0xFF83A093)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label, style: TextStyle(fontSize: 10, color: p.sub)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.6,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(caption, style: TextStyle(fontSize: 10, color: p.sub)),
      ],
    );
  }

  Widget _plans(_P p, SalesAgentDashboard dash) {
    final starter = dash.byTier['starter'] ?? 0;
    final pro = dash.byTier['pro'] ?? 0;
    final ultra = dash.byTier['ultra'] ?? 0;
    final total = dash.registered > 0 ? dash.registered : (starter + pro + ultra);
    return _panel(
      p,
      child: Column(
        children: [
          _sectionHeading(
            p,
            title: _t('Users by plan', 'Watumiaji kwa kifurushi'),
            subtitle: _t('Your community, at a glance.', 'Jamii yako, kwa mtazamo mmoja.'),
            trailing: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: p.tint, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.people_outline, size: 19, color: p.teal),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Row(
              children: [
                Text(
                  '${dash.registered}',
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                    color: p.ink,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 65,
                  child: Text(
                    _t('Total registered users', 'Waliojisajili kwa jumla'),
                    style: TextStyle(fontSize: 10, height: 1.5, color: p.sub),
                  ),
                ),
                const Spacer(),
                if (dash.registered == 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: p.canvas,
                      border: Border.all(color: p.line),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      _t('Just getting started', 'Unaanza tu'),
                      style: TextStyle(fontSize: 10, color: p.sub),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: p.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 0),
            child: Column(
              children: [
                _planRow(
                  p,
                  icon: Icons.eco_outlined,
                  iconBg: p.tint,
                  iconColor: const Color(0xFF6B8D77),
                  title: 'Starter',
                  caption: _t('A simple place to begin', 'Mahali rahisi pa kuanza'),
                  count: starter,
                  total: total,
                ),
                Divider(height: 1, color: p.line),
                _planRow(
                  p,
                  icon: Icons.bolt_outlined,
                  iconBg: const Color(0xFFECF3ED),
                  iconColor: const Color(0xFF4C8566),
                  title: 'Pro',
                  caption: _t('More room to grow', 'Nafasi zaidi ya kukua'),
                  count: pro,
                  total: total,
                ),
                Divider(height: 1, color: p.line),
                _planRow(
                  p,
                  icon: Icons.workspace_premium_outlined,
                  iconBg: const Color(0xFFF6F1E7),
                  iconColor: const Color(0xFFA48B5E),
                  title: 'Ultra',
                  caption: _t('The complete experience', 'Uzoefu kamili'),
                  count: ultra,
                  total: total,
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => controller.selectedTab.value = 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 17),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: p.line)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _t('View all users', 'Tazama watumiaji wote'),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.teal),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16, color: p.teal),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planRow(
    _P p, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String caption,
    required int count,
    required int total,
  }) {
    final pct = total <= 0 ? 0 : ((count / total) * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.ink)),
                const SizedBox(height: 3),
                Text(caption, style: TextStyle(fontSize: 10, color: p.sub)),
              ],
            ),
          ),
          Text('$count', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: p.ink)),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '$pct%',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 10, color: p.sub),
            ),
          ),
        ],
      ),
    );
  }

  Widget _growthBanner(_P p) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.night ? p.tint : const Color(0xFFEEF3E9),
        border: Border.all(color: p.night ? p.line : const Color(0xFFE6ECDE)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7EEDF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDCE6D0)),
                ),
                child: const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF658759)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(
                        'Big things start with one invitation.',
                        'Mambo makubwa yanaanza kwa mwaliko mmoja.',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        color: p.night ? p.ink : const Color(0xFF3E5D43),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _t(
                        'Share your agent code and help your first user get started.',
                        'Sambaza msimbo wako wa wakala na umsaidie mtumiaji wa kwanza kuanza.',
                      ),
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.6,
                        color: p.night ? p.sub : const Color(0xFF7F8F76),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          TextButton(
            onPressed: controller.showInviteShare,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _t('Invite your first user', 'Alika mtumiaji wa kwanza'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: p.night ? p.ink : const Color(0xFF3E5D43),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16, color: p.night ? p.ink : const Color(0xFF3E5D43)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _usersPanel(_P p, SalesAgentDashboard dash) {
    if (dash.customers.isEmpty) return _usersEmptyPanel(p);
    return _populatedUsers(p, dash);
  }

  Widget _usersEmptyPanel(_P p) {
    return _panel(
      p,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Registered users', 'Waliojisajili'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _t(
                    'People who have joined through your agent code.',
                    'Watu waliojiunga kwa msimbo wako wa wakala.',
                  ),
                  style: TextStyle(fontSize: 10, color: p.sub),
                ),
              ],
            ),
          ),
          _usersEmpty(p, query: false),
        ],
      ),
    );
  }

  Widget _populatedUsers(_P p, SalesAgentDashboard dash) {
    final rows = controller.visibleCustomers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('People behind the progress.', 'Watu nyuma ya maendeleo.'),
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _t(
                      'Get to know your users and follow their journey.',
                      'Wajue watumiaji wako na ufuatilie safari yao.',
                    ),
                    style: TextStyle(fontSize: 11, height: 1.5, color: p.sub),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: controller.showInviteShare,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF207568),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _t('Invite a user', 'Alika mtumiaji'),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.north_east, size: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _statTile(
                p,
                icon: Icons.people_outline,
                label: _t('Registered users', 'Waliojisajili'),
                value: controller.paddedCount(dash.registered),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statTile(
                p,
                icon: Icons.check_circle_outline,
                label: _t('Active accounts', 'Akaunti hai'),
                value: controller.paddedCount(controller.activeUserCount),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statTile(
                p,
                icon: Icons.schedule,
                label: _t('Awaiting payment', 'Inasubiri malipo'),
                value: controller.paddedCount(controller.awaitingPaymentCount),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _panel(
          p,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.searchController,
                        onChanged: controller.userQuery.call,
                        style: TextStyle(fontSize: 12, color: p.ink),
                        decoration: InputDecoration(
                          hintText: _t(
                            'Search name, ID or location…',
                            'Tafuta jina, kitambulisho au eneo…',
                          ),
                          hintStyle: TextStyle(fontSize: 12, color: p.sub),
                          prefixIcon: Icon(Icons.search, size: 18, color: p.sub),
                          filled: true,
                          fillColor: p.canvas,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _planFilter(p),
                  ],
                ),
              ),
              if (rows.isEmpty)
                _usersEmpty(p, query: true)
              else ...[
                ...rows.map((c) => _userRow(p, c)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  child: Row(
                    children: [
                      Text(
                        _t(
                          'Showing ${rows.length} of ${dash.customers.length} users',
                          'Inaonyesha ${rows.length} kati ya ${dash.customers.length} watumiaji',
                        ),
                        style: TextStyle(fontSize: 10, color: p.sub),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _statTile(
    _P p, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: p.tint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: p.teal),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 10, color: p.sub)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.8,
              color: p.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _planFilter(_P p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.planFilter.value,
          isDense: true,
          icon: Icon(Icons.expand_more, size: 18, color: p.sub),
          style: TextStyle(fontSize: 12, color: p.ink),
          dropdownColor: p.surface,
          items: [
            DropdownMenuItem(value: 'all', child: Text(_t('All plans', 'Vifurushi vyote'))),
            const DropdownMenuItem(value: 'starter', child: Text('Starter')),
            const DropdownMenuItem(value: 'pro', child: Text('Pro')),
            const DropdownMenuItem(value: 'ultra', child: Text('Ultra')),
          ],
          onChanged: (v) {
            if (v != null) controller.planFilter.value = v;
          },
        ),
      ),
    );
  }

  Widget _planChip(_P p, String plan) {
    final key = plan.trim().toLowerCase();
    final Color bg;
    final Color fg;
    final IconData icon;
    final String label;
    switch (key) {
      case 'pro':
        bg = const Color(0xFFE7F3EC);
        fg = const Color(0xFF4C8566);
        icon = Icons.bolt_outlined;
        label = 'Pro';
      case 'ultra':
        bg = const Color(0xFFF6F1E7);
        fg = const Color(0xFFA48B5E);
        icon = Icons.workspace_premium_outlined;
        label = 'Ultra';
      case 'starter':
        bg = const Color(0xFFEEF3ED);
        fg = const Color(0xFF6B8D77);
        icon = Icons.eco_outlined;
        label = 'Starter';
      default:
        bg = p.canvas;
        fg = p.sub;
        icon = Icons.circle_outlined;
        label = plan.trim().isEmpty ? '—' : plan;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }

  Widget _userRow(_P p, ReferredCustomerRow c) {
    final busy = controller.actingCustomerId.value == c.customerUserId;
    final active = controller.isUserActive(c);
    return InkWell(
      onTap: busy ? null : () => controller.openUser(c),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: p.line)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: p.tint,
              child: Text(
                controller.initialsFor(c.displayName),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: p.teal,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.userSubtitle(c),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: p.sub),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _planChip(p, c.plan),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF3D8B6E)
                                  : const Color(0xFFC9842A),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            active
                                ? _t('Active', 'Hai')
                                : _t('Pending', 'Inasubiri'),
                            style: TextStyle(
                              fontSize: 10,
                              color: active
                                  ? const Color(0xFF3D8B6E)
                                  : const Color(0xFFC9842A),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        controller.joinedLabel(c.registeredAtMs),
                        style: TextStyle(fontSize: 10, color: p.sub),
                      ),
                      Text(
                        controller.formatTzs(c.amountPaidTzs),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: p.ink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Icon(Icons.chevron_right, color: p.sub),
          ],
        ),
      ),
    );
  }

  Widget _memberProfile(
    _P p,
    SalesAgentDashboard dash,
    ReferredCustomerRow c,
  ) {
    final active = controller.isUserActive(c);
    final section = controller.profileSection.value;
    final payments = controller.completedPayments(c);
    final planPrice = controller.planPriceFor(c.plan);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: controller.closeUser,
          child: Row(
            children: [
              Icon(Icons.arrow_back, size: 15, color: p.sub),
              const SizedBox(width: 8),
              Text(_t('All users', 'Watumiaji wote'), style: TextStyle(fontSize: 11, color: p.sub)),
              Icon(Icons.chevron_right, size: 13, color: p.sub),
              Flexible(
                child: Text(
                  c.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: p.ink),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _panel(
          p,
          child: Column(
            children: [
              Container(height: 3, color: p.teal),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: p.tint,
                        shape: BoxShape.circle,
                        border: Border.all(color: p.surface, width: 4),
                        boxShadow: [BoxShadow(color: p.line, spreadRadius: 1)],
                      ),
                      child: Text(
                        controller.initialsFor(c.displayName),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: p.teal),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  c.displayName,
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.7,
                                    color: p.ink,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.verified_outlined, size: 18, color: p.teal),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => controller.copyUserId(c),
                            child: Row(
                              children: [
                                Text(
                                  controller.userRef(c),
                                  style: TextStyle(fontSize: 10, color: p.sub),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.copy_outlined, size: 13, color: p.sub),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: p.tint,
                        border: Border.all(color: p.line),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        active ? _t('Active', 'Hai') : _t('Pending', 'Inasubiri'),
                        style: TextStyle(
                          fontSize: 10,
                          color: active ? p.teal : const Color(0xFFA17C3C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: p.canvas,
                  border: Border(top: BorderSide(color: p.line)),
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone_outlined, size: 14, color: p.sub),
                        const SizedBox(width: 7),
                        Text(
                          c.customerPhone.trim().isEmpty
                              ? _t('Not provided', 'Haijatolewa')
                              : c.customerPhone,
                          style: TextStyle(fontSize: 10, color: p.sub),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 14, color: p.sub),
                        const SizedBox(width: 7),
                        Text(
                          '${_t('Joined', 'Alijiunga')} ${controller.joinedLabel(c.registeredAtMs)}',
                          style: TextStyle(fontSize: 10, color: p.sub),
                        ),
                      ],
                    ),
                    _planChip(p, c.plan),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: p.tint,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(Icons.smartphone, size: 19, color: p.teal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t('Payment actions', 'Vitendo vya malipo'),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.ink),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _t(
                            'Request a payment or access receipts.',
                            'Omba malipo au fungua risiti.',
                          ),
                          style: TextStyle(fontSize: 10, color: p.sub),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => controller.confirmPushPay(c),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF207568),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.smartphone, size: 16),
                      label: Text(
                        _t('Push-to-pay', 'Tuma malipo'),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showReceipts(p, c),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: p.ink,
                        side: BorderSide(color: p.line),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 16),
                          const SizedBox(width: 7),
                          Text(_t('Receipts', 'Risiti'), style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: p.tint,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$payments',
                              style: TextStyle(fontSize: 10, color: p.teal),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _profileTab(p, 'Overview', _t('Overview', 'Muhtasari')),
            const SizedBox(width: 18),
            _profileTab(
              p,
              'Payments',
              _t('Payments', 'Malipo'),
              badge: payments > 0 ? '$payments' : null,
            ),
            const SizedBox(width: 18),
            _profileTab(p, 'Activity', _t('Activity', 'Shughuli')),
          ],
        ),
        Divider(height: 1, color: p.line),
        const SizedBox(height: 18),
        if (section == 'Payments')
          _paymentsPanel(p, c, payments)
        else if (section == 'Activity')
          _activityPanel(p, dash, c, payments)
        else ...[
          _accountDetailsPanel(p, dash, c),
          const SizedBox(height: 18),
          _recentPaymentsPanel(p, c, payments),
          const SizedBox(height: 18),
          _currentPlanCard(p, c, active, planPrice),
          const SizedBox(height: 18),
          _totalCollectedCard(p, c, payments),
        ],
      ],
    );
  }

  Widget _profileTab(_P p, String key, String label, {String? badge}) {
    final selected = controller.profileSection.value == key;
    return GestureDetector(
      onTap: () => controller.profileSection.value = key,
      child: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? p.teal : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? p.teal : p.sub,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: p.tint,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(badge, style: TextStyle(fontSize: 10, color: p.teal)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _accountDetailsPanel(
    _P p,
    SalesAgentDashboard dash,
    ReferredCustomerRow c,
  ) {
    final first = c.displayName.split(RegExp(r'\s+')).first;
    return _panel(
      p,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('Account details', 'Maelezo ya akaunti'),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.ink),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _t('A little more about $first.', 'Kidogo zaidi kuhusu $first.'),
                        style: TextStyle(fontSize: 10, color: p.sub),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.people_outline, size: 18, color: p.sub),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Column(
              children: [
                _detailRow(
                  p,
                  Icons.mail_outline,
                  _t('Email address', 'Barua pepe'),
                  c.customerEmail.trim().isEmpty
                      ? _t('Not provided', 'Haijatolewa')
                      : c.customerEmail,
                ),
                _detailRow(
                  p,
                  Icons.phone_outlined,
                  _t('Phone number', 'Namba ya simu'),
                  c.customerPhone.trim().isEmpty
                      ? _t('Not provided', 'Haijatolewa')
                      : c.customerPhone,
                ),
                _detailRow(
                  p,
                  Icons.shield_outlined,
                  _t('Assigned agent', 'Wakala aliyepewa'),
                  dash.agent.fullName,
                  caption: dash.agent.agentCode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    _P p,
    IconData icon,
    String label,
    String value, {
    String? caption,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 17),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: p.line))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: p.sub),
          const SizedBox(width: 9),
          Expanded(child: Text(label, style: TextStyle(fontSize: 10, color: p.sub))),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 10, color: p.ink),
                ),
                if (caption != null) ...[
                  const SizedBox(height: 6),
                  Text(caption, style: TextStyle(fontSize: 10, color: p.sub)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentPaymentsPanel(_P p, ReferredCustomerRow c, int payments) {
    return _panel(
      p,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('Recent payments', 'Malipo ya hivi karibuni'),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.ink),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _t('A clear view of their contributions.', 'Muhtasari wa michango yao.'),
                        style: TextStyle(fontSize: 10, color: p.sub),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => controller.profileSection.value = 'Payments',
                  child: Text(_t('View all', 'Tazama yote'), style: TextStyle(fontSize: 11, color: p.teal)),
                ),
              ],
            ),
          ),
          _paymentRows(p, c, payments, limit: 2),
        ],
      ),
    );
  }

  Widget _paymentsPanel(_P p, ReferredCustomerRow c, int payments) {
    return _panel(
      p,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('Payment history', 'Historia ya malipo'),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.ink),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _t(
                      '$payments completed payments · ${controller.formatTzs(c.amountPaidTzs)} collected',
                      'Malipo $payments yaliyokamilika · ${controller.formatTzs(c.amountPaidTzs)} iliyokusanywa',
                    ),
                    style: TextStyle(fontSize: 10, color: p.sub),
                  ),
                ],
              ),
            ),
          ),
          _paymentRows(p, c, payments),
        ],
      ),
    );
  }

  Widget _paymentRows(_P p, ReferredCustomerRow c, int payments, {int? limit}) {
    if (payments <= 0 || c.amountPaidTzs <= 0) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 38, 20, 38),
        child: Column(
          children: [
            Icon(Icons.credit_card_outlined, size: 26, color: p.sub),
            const SizedBox(height: 12),
            Text(
              _t('No payments yet', 'Bado hakuna malipo'),
              style: TextStyle(fontSize: 15, color: p.ink),
            ),
            const SizedBox(height: 8),
            Text(
              _t(
                'The first payment will appear here once collected.',
                'Malipo ya kwanza yataonekana hapa baada ya kukusanywa.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: p.sub),
            ),
          ],
        ),
      );
    }
    final shown = limit == null ? 1 : (payments < limit ? payments : limit);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Column(
        children: List.generate(shown, (i) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: p.line))),
            child: Row(
              children: [
                Container(
                  width: 33,
                  height: 33,
                  decoration: BoxDecoration(color: p.tint, shape: BoxShape.circle),
                  child: Icon(Icons.north_east, size: 16, color: p.teal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('Plan payment', 'Malipo ya kifurushi'),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: p.ink),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${controller.joinedLabel(c.registeredAtMs)} · ${controller.paymentModeLabel(c.paymentMode)}',
                        style: TextStyle(fontSize: 10, color: p.sub),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      controller.formatTzs(c.amountPaidTzs),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: p.ink),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _t('Completed', 'Imekamilika'),
                      style: TextStyle(fontSize: 10, color: p.teal),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _currentPlanCard(_P p, ReferredCustomerRow c, bool active, int planPrice) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1D6C60),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _t('CURRENT PLAN', 'KIFURUSHI CHA SASA'),
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.3,
                  color: Color(0xFFC3DBCF),
                ),
              ),
              const Spacer(),
              _planChip(p, c.plan),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            controller.planBlurb(c.plan),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Color(0xFFEEF6F1),
            ),
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: planPrice > 0 ? controller.formatTzs(planPrice) : '—',
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: ' ${_t('/ month', '/ mwezi')}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFB4D4C6)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 17),
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 15, color: Color(0xFFD4E7DC)),
              const SizedBox(width: 8),
              Text(
                active
                    ? _t('Plan is active', 'Kifurushi kinaendelea')
                    : _t('Awaiting first payment', 'Inasubiri malipo ya kwanza'),
                style: const TextStyle(fontSize: 10, color: Color(0xFFD4E7DC)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalCollectedCard(_P p, ReferredCustomerRow c, int payments) {
    return _panel(
      p,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _t('Total collected', 'Jumla iliyokusanywa'),
                    style: TextStyle(fontSize: 11, color: p.sub),
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFECE4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF427D67)),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              controller.formatTzs(c.amountPaidTzs),
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.5,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _t(
                '$payments completed ${payments == 1 ? 'payment' : 'payments'}',
                'Malipo $payments yaliyokamilika',
              ),
              style: TextStyle(fontSize: 10, color: p.sub),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityPanel(
    _P p,
    SalesAgentDashboard dash,
    ReferredCustomerRow c,
    int payments,
  ) {
    return _panel(
      p,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('Account activity', 'Shughuli za akaunti'),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.ink),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _t(
                          'The important moments, all in one place.',
                          'Nyakati muhimu, mahali pamoja.',
                        ),
                        style: TextStyle(fontSize: 10, color: p.sub),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.schedule, size: 18, color: p.sub),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                if (c.amountPaidTzs > 0)
                  _timelineItem(
                    p,
                    Icons.credit_card_outlined,
                    _t('Payment completed', 'Malipo yamekamilika'),
                    _t(
                      '${controller.formatTzs(c.amountPaidTzs)} received for the ${controller.planTitle(c.plan)} plan',
                      '${controller.formatTzs(c.amountPaidTzs)} imepokelewa kwa kifurushi cha ${controller.planTitle(c.plan)}',
                    ),
                    controller.joinedLabel(c.registeredAtMs),
                  ),
                _timelineItem(
                  p,
                  Icons.people_outline,
                  _t('Joined your community', 'Amejiunga na jamii yako'),
                  _t(
                    'Registered with agent code ${dash.agent.agentCode}',
                    'Amesajiliwa kwa msimbo ${dash.agent.agentCode}',
                  ),
                  controller.joinedLabel(c.registeredAtMs),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineItem(
    _P p,
    IconData icon,
    String title,
    String body,
    String time,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: p.tint, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: p.teal),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 3),
                Text(title, style: TextStyle(fontSize: 12, color: p.ink)),
                const SizedBox(height: 6),
                Text(body, style: TextStyle(fontSize: 11, color: p.sub)),
                const SizedBox(height: 6),
                Text(time, style: TextStyle(fontSize: 10, color: p.sub)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReceipts(_P p, ReferredCustomerRow c) {
    Get.dialog(
      Dialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _t('Payment receipts', 'Risiti za malipo'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: p.ink),
              ),
              const SizedBox(height: 8),
              Text(
                _t(
                  'Send a receipt for ${c.displayName}.',
                  'Tuma risiti ya ${c.displayName}.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: p.sub),
              ),
              const SizedBox(height: 18),
              _receiptSend(p, _t('Send receipt to app', 'Tuma risiti kwenye app'), () {
                Get.back();
                controller.sendReceipt(c, channel: 'APP');
              }),
              _receiptSend(p, _t('Send PDF receipt to email', 'Tuma risiti PDF kwa barua pepe'), () {
                Get.back();
                controller.sendReceipt(c, channel: 'EMAIL');
              }),
              _receiptSend(p, _t('Send PDF receipt to WhatsApp', 'Tuma risiti PDF WhatsApp'), () {
                Get.back();
                controller.sendReceipt(c, channel: 'WHATSAPP');
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptSend(_P p, String label, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: TextStyle(fontSize: 14, color: p.ink)),
      trailing: Icon(Icons.chevron_right, color: p.sub),
      onTap: onTap,
    );
  }

  Widget _usersEmpty(_P p, {required bool query}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: p.tint, shape: BoxShape.circle),
            child: Icon(Icons.people_outline, size: 32, color: p.teal),
          ),
          const SizedBox(height: 16),
          Text(
            query
                ? _t('No matching users', 'Hakuna watumiaji wanaofanana')
                : _t('Your community starts here', 'Jamii yako inaanza hapa'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, height: 1.5, color: p.ink),
          ),
          const SizedBox(height: 8),
          Text(
            query
                ? _t(
                    'No users match “${controller.userQuery.value}”. Try a different search.',
                    'Hakuna anayefanana na “${controller.userQuery.value}”. Jaribu tena.',
                  )
                : _t(
                    'Invite your first user with your personal agent code.',
                    'Alika mtumiaji wako wa kwanza kwa msimbo wako wa wakala.',
                  ),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5, color: p.sub),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: query
                ? () {
                    controller.searchController.clear();
                    controller.userQuery.value = '';
                    controller.planFilter.value = 'all';
                  }
                : controller.showInviteShare,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF207568),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: const Offset(0, -2),
                  child: Text(
                    query
                        ? _t('Clear search', 'Futa utafutaji')
                        : _t('Invite your first user', 'Alika mtumiaji wa kwanza'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward,
                  size: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
