import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/locale/app_locale_controller.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../data/model/sales_agent_models.dart';
import '../../../data/repository/app_repository.dart';
import '../../../network/exceptions/api_exception.dart';
import '../../../routes/app_pages.dart';
import '/app/core/base/base_controller.dart';

class SalesAgentDashboardController extends BaseController {
  static const planPricesTzs = <String, int>{
    'starter': 19000,
    'pro': 49000,
    'ultra': 99000,
  };

  final AppRepository _repository = Get.find(tag: (AppRepository).toString());
  final PreferenceManager _preferenceManager = Get.find(
    tag: (PreferenceManager).toString(),
  );

  final dashboard = Rxn<SalesAgentDashboard>();
  final isLoading = false.obs;
  final isInviting = false.obs;
  final selectedTab = 0.obs;
  final actingCustomerId = ''.obs;
  final userQuery = ''.obs;
  final planFilter = 'all'.obs;
  final selectedCustomer = Rxn<ReferredCustomerRow>();
  final profileSection = 'Overview'.obs;
  final sessionName = ''.obs;
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _hydrateSessionName();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> _hydrateSessionName() async {
    try {
      final user = await _preferenceManager.getUser();
      final name = user.fullName?.trim() ?? '';
      if (name.isNotEmpty && sessionName.value.isEmpty) {
        sessionName.value = name;
      }
    } catch (_) {}
  }

  String _t(String en, String sw) => Get.locale?.languageCode == 'sw' ? sw : en;

  @override
  void onReady() {
    super.onReady();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    isLoading(true);
    try {
      final user = await _preferenceManager.getUser();
      final storedName = user.fullName?.trim() ?? '';
      if (storedName.isNotEmpty) sessionName.value = storedName;
      final userId = user.id ?? '';
      if (userId.isEmpty) {
        showErrorMessage(_t('User not found', 'Mtumiaji hajapatikana'));
        return;
      }
      final res = await _repository.getSalesAgentDashboard(userId);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        dashboard.value = SalesAgentDashboard.fromJson(data);
      } else {
        showErrorMessage(
          _t('Could not load dashboard', 'Imeshindikana kupakia dashibodi'),
        );
      }
    } catch (_) {
      showErrorMessage(
        _t('Could not load dashboard', 'Imeshindikana kupakia dashibodi'),
      );
    } finally {
      isLoading(false);
    }
  }

  String get referralCode => dashboard.value?.agent.agentCode ?? '';

  String get displayName {
    final fromDash = dashboard.value?.agent.fullName.trim() ?? '';
    if (fromDash.isNotEmpty) return fromDash;
    return sessionName.value.trim();
  }

  String get firstName {
    final name = displayName;
    if (name.isEmpty) return '';
    return name.split(RegExp(r'\s+')).first;
  }

  String get initials => initialsFor(displayName);

  String initialsFor(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  List<ReferredCustomerRow> get allCustomers =>
      dashboard.value?.customers ?? const <ReferredCustomerRow>[];

  int get activeUserCount => allCustomers.where(isUserActive).length;

  int get awaitingPaymentCount =>
      allCustomers.where((c) => !isUserActive(c)).length;

  bool isUserActive(ReferredCustomerRow c) {
    final s = c.subscriptionStatus.trim().toLowerCase();
    if (s == 'active') return true;
    if (s == 'pending' ||
        s == 'expired' ||
        s == 'cancelled' ||
        s == 'canceled' ||
        s == 'none') {
      return false;
    }
    return c.active;
  }

  List<ReferredCustomerRow> get visibleCustomers {
    var rows = allCustomers;
    final plan = planFilter.value;
    if (plan != 'all') {
      rows = rows.where((c) => c.plan.toLowerCase() == plan).toList();
    }
    final q = userQuery.value.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where(
          (c) =>
              c.displayName.toLowerCase().contains(q) ||
              c.customerPhone.toLowerCase().contains(q) ||
              c.customerUserId.toLowerCase().contains(q) ||
              c.customerEmail.toLowerCase().contains(q) ||
              c.plan.toLowerCase().contains(q),
        )
        .toList();
  }

  String userSubtitle(ReferredCustomerRow c) {
    final phone = c.customerPhone.trim();
    // final id = c.customerUserId.trim();
    // final short = id.isEmpty
    //     ? ''
    //     : (id.length <= 10 ? id : '…${id.substring(id.length - 6)}');
    // if (short.isNotEmpty && phone.isNotEmpty) return '$short · $phone';
    // if (phone.isNotEmpty)
      return phone;
    // return short.isEmpty ? '—' : short;
  }

  String joinedLabel(int ms) {
    if (ms <= 0) return '—';
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = d.day.toString().padLeft(2, '0');
    return '$day ${months[d.month - 1]} ${d.year}';
  }

  String paddedCount(int n) => n.toString().padLeft(2, '0');

  void openUser(ReferredCustomerRow customer) {
    selectedCustomer.value = customer;
    profileSection.value = 'Overview';
  }

  void closeUser() {
    selectedCustomer.value = null;
    profileSection.value = 'Overview';
  }

  String userRef(ReferredCustomerRow c) {
    final id = c.customerUserId.trim();
    if (id.isEmpty) return c.customerPhone.trim().isEmpty ? '—' : c.customerPhone;
    if (id.toUpperCase().startsWith('USR')) return id;
    if (id.length <= 12) return id;
    return 'USR-${id.substring(id.length - 3).toUpperCase()}';
  }

  int planPriceFor(String plan) =>
      planPricesTzs[plan.trim().toLowerCase()] ?? 0;

  String planTitle(String plan) {
    final p = plan.trim();
    if (p.isEmpty || p.toLowerCase() == 'none') return '—';
    return '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}';
  }

  String planBlurb(String plan) {
    switch (plan.trim().toLowerCase()) {
      case 'pro':
        return _t('More room to grow.', 'Nafasi zaidi ya kukua.');
      case 'ultra':
        return _t('All the possibilities.', 'Uwezekano wote.');
      default:
        return _t('A great place to start.', 'Mahali pazuri pa kuanza.');
    }
  }

  int completedPayments(ReferredCustomerRow c) {
    final price = planPriceFor(c.plan);
    if (price > 0 && c.amountPaidTzs >= price) {
      return c.amountPaidTzs ~/ price;
    }
    if (c.paidMonthsCount > 0) return c.paidMonthsCount;
    return c.amountPaidTzs > 0 ? 1 : 0;
  }

  Future<void> copyUserId(ReferredCustomerRow c) async {
    final ref = userRef(c);
    if (ref.isEmpty || ref == '—') return;
    await Clipboard.setData(ClipboardData(text: ref));
    showSuccessMessage(_t('Copied', 'Imenakiliwa'));
  }

  String periodLabel(String raw) {
    final t = raw.trim();
    if (t.length >= 7 && t[4] == '-') {
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      final year = t.substring(0, 4);
      final month = int.tryParse(t.substring(5, 7)) ?? 0;
      if (month >= 1 && month <= 12) {
        return Get.locale?.languageCode == 'sw'
            ? t
            : '${months[month - 1]} $year';
      }
    }
    return t;
  }

  String get inviteUrl {
    final dash = dashboard.value;
    if (dash == null) return '';
    if (dash.inviteUrl.isNotEmpty) return dash.inviteUrl;
    if (referralCode.isEmpty) return '';
    return 'https://hostbora.co.tz/r/$referralCode';
  }

  String inviteMessage() {
    return _t(
      'Join Host Bora with my invite link:\n$inviteUrl',
      'Jiunge Host Bora kwa kiungo changu cha mwaliko:\n$inviteUrl',
    );
  }

  Future<void> copyReferralCode() async {
    final code = referralCode;
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    showSuccessMessage(_t('Code copied', 'Msimbo umenakiliwa'));
  }

  Future<void> inviteOnWhatsApp() async {
    if (referralCode.isEmpty || isInviting.value) return;
    isInviting(true);
    try {
      final res = await _repository.recordSalesAgentInvite();
      final data = res.data;
      if (data is Map<String, dynamic>) {
        dashboard.value = SalesAgentDashboard.fromJson(data);
      }
    } catch (_) {
      // Sharing still proceeds even if the invite counter is temporarily unavailable.
    } finally {
      isInviting(false);
    }
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(inviteMessage())}',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      showErrorMessage(_t('Could not open WhatsApp', 'WhatsApp haikufunguka'));
    }
  }

  void showInviteQr() {
    final url = inviteUrl;
    final code = referralCode;
    if (url.isEmpty && code.isEmpty) return;
    Get.dialog(
      _AgentDialog(
        title: _t('Your personal agent QR', 'QR yako ya wakala'),
        description: _t(
          'Scan to join with this agent code.',
          'Skani ili ujiunge na msimbo huu wa wakala.',
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: QrImageView(
                data: url.isNotEmpty ? url : code,
                size: 192,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF1B7166),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF1B7166),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _codeRow(code),
            const SizedBox(height: 10),
            Text(
              dashboard.value?.agent.fullName ?? '',
              style: const TextStyle(color: Color(0xFF72847C), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _codeRow(String code) {
    return Container(
      margin: const EdgeInsets.all(0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF5F1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              code,
              style: const TextStyle(
                color: Color(0xFF24695A),
                fontSize: 14,
                letterSpacing: 0.994,
                height: 1.43,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          IconButton(
            tooltip: _t('Copy agent code', 'Nakili msimbo'),
            onPressed: copyReferralCode,
            icon: const Icon(Icons.copy_outlined, size: 14, color: Color(0xFF24695A)),
          ),
        ],
      ),
    );
  }

  Future<void> confirmPushPay(ReferredCustomerRow customer) async {
    var selectedPlan = (customer.plan.isEmpty || customer.plan == 'none')
        ? 'starter'
        : customer.plan.toLowerCase();
    if (!planPricesTzs.containsKey(selectedPlan)) selectedPlan = 'starter';
    var months = 1;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(_t('Push to pay', 'Tuma malipo')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customer.displayName),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedPlan,
              decoration: InputDecoration(
                labelText: _t('Plan', 'Kifurushi'),
              ),
              items: planPricesTzs.keys
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        '${p[0].toUpperCase()}${p.substring(1)} · ${formatTzs(planPricesTzs[p]!)}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) selectedPlan = v;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: months,
              decoration: InputDecoration(
                labelText: _t('Months', 'Miezi'),
              ),
              items: List.generate(
                12,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text('${i + 1}'),
                ),
              ),
              onChanged: (v) {
                if (v != null) months = v;
              },
            ),
            const SizedBox(height: 12),
            Text(
              _t(
                'An STK prompt will be sent to ${customer.customerPhone}.',
                'Ombi la STK litatumwa kwa ${customer.customerPhone}.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(_t('Cancel', 'Ghairi')),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text(_t('Send', 'Tuma')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _pushPay(customer, selectedPlan, months);
  }

  Future<void> _pushPay(
    ReferredCustomerRow customer,
    String plan,
    int months,
  ) async {
    if (actingCustomerId.isNotEmpty) return;
    actingCustomerId(customer.customerUserId);
    try {
      final res = await _repository.pushSalesAgentPay(
        customer.customerUserId,
        {'plan': plan, 'months': months},
      );
      final data = res.data;
      final status = data is Map ? data['status']?.toString() ?? '' : '';
      if (status.toLowerCase() == 'failed') {
        final reason = data is Map ? data['failureReason']?.toString() : null;
        showErrorMessage(
          reason?.isNotEmpty == true
              ? reason!
              : _t('Payment request failed', 'Ombi la malipo limeshindikana'),
        );
        return;
      }
      showSuccessMessage(
        _t(
          'Payment prompt sent to the customer',
          'Ombi la malipo limetumwa kwa mteja',
        ),
      );
      await loadDashboard();
    } catch (e) {
      showErrorMessage(_apiMessage(e) ??
          _t('Could not send payment', 'Imeshindikana kutuma malipo'));
    } finally {
      actingCustomerId('');
    }
  }

  Future<void> sendReceipt(
    ReferredCustomerRow customer, {
    required String channel,
  }) async {
    if (actingCustomerId.isNotEmpty) return;
    actingCustomerId(customer.customerUserId);
    try {
      final res = await _repository.sendSalesAgentReceipt(
        customer.customerUserId,
        {'channel': channel},
      );
      final data = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{};
      final sent = data['sent'] == true;
      final receiptText = data['receiptText']?.toString() ?? '';
      if (channel.toUpperCase() == 'WHATSAPP' && (!sent || receiptText.isNotEmpty)) {
        if (!sent) {
          final opened = await _openWhatsApp(
            customer.customerPhone,
            receiptText,
          );
          if (opened) {
            showSuccessMessage(
              _t('Receipt opened in WhatsApp', 'Risiti imefunguliwa WhatsApp'),
            );
            return;
          }
        }
      }
      if (sent) {
        final dest = channel.toUpperCase();
        showSuccessMessage(
          dest == 'EMAIL'
              ? _t('Receipt sent to email', 'Risiti imetumwa kwa barua pepe')
              : dest == 'APP'
                  ? _t('Receipt sent to the app inbox', 'Risiti imetumwa kwenye kikasha')
                  : _t('Receipt sent on WhatsApp', 'Risiti imetumwa WhatsApp'),
        );
      } else {
        showErrorMessage(
          data['error']?.toString().isNotEmpty == true
              ? data['error'].toString()
              : _t('Could not send receipt', 'Imeshindikana kutuma risiti'),
        );
      }
    } catch (e) {
      showErrorMessage(_apiMessage(e) ??
          _t('Could not send receipt', 'Imeshindikana kutuma risiti'));
    } finally {
      actingCustomerId('');
    }
  }

  Future<bool> _openWhatsApp(String phone, String text) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final international = digits.startsWith('0')
        ? '255${digits.substring(1)}'
        : digits;
    final uri = international.isEmpty
        ? Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}')
        : Uri.parse(
            'https://wa.me/$international?text=${Uri.encodeComponent(text)}',
          );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String? _apiMessage(Object e) {
    if (e is ApiException && e.message.isNotEmpty) return e.message;
    return null;
  }

  void confirmSignOut() {
    Get.dialog(
      AlertDialog(
        title: Text(_t('Logout', 'Ondoka')),
        content: Text(
          _t(
            'Are you sure you want to logout?',
            'Je, una uhakika unataka kutoka?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(_t('Cancel', 'Ghairi')),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await signOut();
            },
            child: Text(_t('Logout', 'Ondoka')),
          ),
        ],
      ),
    );
  }

  Future<void> signOut() async {
    await _preferenceManager.clearSession();
    Get.offAllNamed(AppPages.auth);
  }

  String formatTzs(int amount) => Get.find<CurrencyService>().formatBase(amount);

  String formatTzsExact(int amount) =>
      Get.find<CurrencyService>().formatBase(amount, decimalDigits: 2);

  String get currencySymbol =>
      Get.find<CurrencyService>().inputPrefix.trim();

  void showLanguagePicker() {
    final locale = Get.isRegistered<AppLocaleController>()
        ? Get.find<AppLocaleController>()
        : null;
    Get.dialog(
      _AgentDialog(
        title: _t('Language', 'Lugha'),
        description: _t(
          'Choose the language for your agent workspace.',
          'Chagua lugha ya dawati lako la wakala.',
        ),
        child: Column(
          children: [
            _languageOption('English', 'en', locale),
            const SizedBox(height: 8),
            _languageOption('Kiswahili', 'sw', locale),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(
    String label,
    String code,
    AppLocaleController? locale,
  ) {
    final selected = (locale?.code.value ?? Get.locale?.languageCode) == code;
    return InkWell(
      onTap: () async {
        if (locale != null) {
          await locale.setLanguage(code);
        }
        if (Get.isDialogOpen ?? false) Get.back();
      },
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE6EEEA)),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            if (selected)
              const Icon(Icons.check, size: 18, color: Color(0xFF207568)),
          ],
        ),
      ),
    );
  }

  void showInviteShare() {
    final code = referralCode;
    if (code.isEmpty) return;
    Get.dialog(
      _AgentDialog(
        title: _t('Good things are better shared', 'Mambo mazuri yanashirikiwa'),
        description: _t(
          'Share your agent code with someone you’d like to invite.',
          'Sambaza msimbo wako wa wakala kwa mtu ungependa kumwalika.',
        ),
        child: Column(
          children: [
            _codeRow(code),
            const SizedBox(height: 8),
            Text(dashboard.value?.agent.fullName ?? '', style: TextStyle(
              color: const Color(0xFF7B8985),
              fontSize: 11,
              fontWeight: FontWeight.w400,
              height: 1.43
            )),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Get.back();
                  inviteOnWhatsApp();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF207568),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.chat, size: 14),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                        _t('Open WhatsApp', 'Fungua WhatsApp'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.43
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.north_east, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String paymentModeLabel(String raw) {
    final v = raw.trim().toLowerCase();
    if (v.contains('cash')) return _t('Cash', 'Taslimu');
    if (v.contains('bank')) return _t('Bank', 'Benki');
    if (v.contains('mobile')) return _t('Mobile money', 'Pesa simu');
    return raw.isEmpty ? '—' : raw;
  }
}

class _AgentDialog extends StatelessWidget {
  const _AgentDialog({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF233D38),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              // textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF7B8985),
                height: 1.45
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
