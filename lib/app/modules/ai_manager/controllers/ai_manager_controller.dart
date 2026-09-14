import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/db/inventory_item_local_data_source.dart';
import '../../../data/local/db/inventory_movement_local_data_source.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/service/ai_bnb_guest_flow.dart';
import '../../../data/local/service/ai_finance_flow.dart';
import '../../../data/local/service/ai_maintenance_flow.dart';
import '../../../data/local/service/ai_property_flow.dart';
import '../../../data/local/service/ai_tenant_flow.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../data/local/service/inventory_nlp_parser.dart';
import '../../../data/local/service/portfolio_ai_hybrid_service.dart';

class AiChatMessage {
  const AiChatMessage({
    required this.text,
    required this.fromAssistant,
    required this.role,
    required this.time,
    this.isTyping = false,
  });

  final String text;
  final bool fromAssistant;
  final String role;
  final String time;
  final bool isTyping;
}

class AiManagerController extends BaseController {
  late final PortfolioAiHybridService _hybrid;

  final messages = <AiChatMessage>[].obs;
  final isBootstrapping = true.obs;
  final bootstrapFailed = false.obs;
  final isReplying = false.obs;
  final messageInput = ''.obs;
  final inputController = TextEditingController();
  final scrollController = ScrollController();

  // Active multi-turn finance flow (expense or income recording)
  AiFinanceFlow? _activeFlow;

  // Active multi-turn property/unit creation flow
  AiPropertyFlow? _activePropertyFlow;

  // Active multi-turn tenant management flow
  AiTenantFlow? _activeTenantFlow;

  // Active multi-turn BnB guest check-in/check-out flow
  AiBnbGuestFlow? _activeBnbGuestFlow;

  // Active multi-turn maintenance / task flow
  AiMaintenanceFlow? _activeMaintenanceFlow;

  static final _timeFmt = DateFormat('h:mm a');

  bool get _isSw => Get.locale?.languageCode == 'sw';

  List<String> get quickActions {
    final source = _routeSource();
    if (source == 'inventory') {
      return _isSw
          ? const [
              'Orodhesha vifaa vyote',
              'Nimetumia taulo 2',
              'Nimejaza sabuni 5',
              'Bidhaa zenye idadi ya chini',
            ]
          : const [
              'List all inventory',
              'Used 2 towels',
              'Restocked 5 soap',
              'Low stock items',
            ];
    }
    if (source == 'insights') {
      return _isSw
          ? const [
              'Bei bora kwa wikendi ijayo?',
              'Mapato ya mwezi huu',
              'Ukodishaji wa sasa?',
              'Muhtasari wa portfolio',
            ]
          : const [
              'Best pricing for next weekend?',
              'Monthly income this month',
              "What's my occupancy rate?",
              'Portfolio summary',
            ];
    }
    if (source == 'automations') {
      return _isSw
          ? const [
              'Vikumbusho vya malipo vilivyopangwa?',
              'Wapangaji wenye deni?',
              'Mikataba inayoisha hivi karibuni?',
              'Muhtasari wa portfolio',
            ]
          : const [
              'What payment reminders are scheduled?',
              'Any tenants in arrears?',
              'Leases expiring soon',
              'Portfolio summary',
            ];
    }
    return _isSw
        ? const [
            'Panga matengenezo',
            'Ongeza kazi',
            'Ongeza mpangaji',
            'Pokesha mgeni wa BnB',
            'Ongeza gharama',
            'Ongeza mali mpya',
          ]
        : const [
            'Schedule maintenance',
            'Add a task',
            'Add a tenant',
            'Check in BnB guest',
            'Add expense',
            'Add a new property',
          ];
  }

  String? _routeSource() {
    final args = Get.arguments;
    if (args is Map) {
      return args['source']?.toString();
    }
    return null;
  }

  bool _looksSwahili(String text) {
    final q = text.toLowerCase();
    return [
      'mapato',
      'matumizi',
      'mpangaji',
      'wapangaji',
      'deni',
      'malipo',
      'kodi',
      'mkataba',
      'nyumba',
      'chumba',
      'umeme',
      'maji',
      // inventory
      'nimetumia',
      'nilitumia',
      'nimejaza',
      'nilijaza',
      'nimeongeza',
      'imeharibiwa',
      'imeharibika',
      'bidhaa',
      'vifaa',
      // finance
      'gharama',
      'matumizi',
      'mapato',
      'ongeza gharama',
      'rekodi mapato',
      // property
      'mali mpya',
      'ongeza mali',
      'ongeza unit',
      'nyumba mpya',
      // tenant / guest
      'mpangaji',
      'mgeni',
      'ongeza mpangaji',
      'maliza kukaa',
      'pokesha',
      'shusha mgeni',
      'anaondoka',
      // maintenance / tasks
      'matengenezo',
      'panga matengenezo',
      'marekebisho',
      'ongeza kazi',
    ].any(q.contains);
  }

  String? _routeInitialQuestion() {
    final args = Get.arguments;
    if (args is Map) {
      final q = args['initialQuestion']?.toString().trim();
      if (q != null && q.isNotEmpty) return q;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    isBootstrapping.value = true;
    bootstrapFailed.value = false;
    try {
      await _ensureDependencies();
      await _loadWelcome();
      await _maybeAskInitialQuestion();
    } catch (e, st) {
      logger.e('AiManager bootstrap failed: $e $st');
      bootstrapFailed.value = true;
      messages.assignAll([
        AiChatMessage(
          fromAssistant: true,
          role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
          time: _nowLabel(),
          text: _isSw
              ? 'Imeshindwa kupakia data ya portfolio. Bado unaweza kuuliza maswali — jaribu "Muhtasari wa portfolio".'
              : 'Could not load portfolio data. You can still ask questions — try "Portfolio summary".',
        ),
      ]);
    } finally {
      isBootstrapping.value = false;
    }
  }

  Future<void> _ensureDependencies() async {
    if (!Get.isRegistered<CurrencyService>()) {
      await Get.putAsync<CurrencyService>(() => CurrencyService().init());
    }
    if (!Get.isRegistered<PortfolioAiHybridService>()) {
      throw StateError('PortfolioAiHybridService is not registered');
    }
    _hybrid = Get.find<PortfolioAiHybridService>();
  }

  Future<void> _maybeAskInitialQuestion() async {
    final q = _routeInitialQuestion();
    if (q == null || isReplying.value) return;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await sendQuickAction(q);
  }

  @override
  void onClose() {
    _activeFlow            = null;
    _activePropertyFlow    = null;
    _activeTenantFlow      = null;
    _activeBnbGuestFlow    = null;
    _activeMaintenanceFlow = null;
    inputController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void setInput(String value) => messageInput.value = value;

  Future<void> _loadWelcome() async {
    isReplying.value = true;
    try {
      final text = await _hybrid.welcomeMessage(isSw: _isSw);
      messages.assignAll([
        AiChatMessage(
          fromAssistant: true,
          role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
          time: _nowLabel(),
          text: text,
        ),
      ]);
      _scrollToEnd();
    } catch (e, st) {
      logger.e('AiManager welcome failed: $e $st');
      messages.assignAll([
        AiChatMessage(
          fromAssistant: true,
          role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
          time: _nowLabel(),
          text: _isSw
              ? 'Karibu! Uliza kuhusu ukodishaji, mapato, deni, au mikataba yako.'
              : 'Welcome! Ask about occupancy, income, arrears, or your leases.',
        ),
      ]);
    } finally {
      isReplying.value = false;
    }
  }

  Future<void> send() async {
    final text = inputController.text.trim();
    if (text.isEmpty || isReplying.value) return;
    await _submitQuestion(text);
  }

  Future<void> sendQuickAction(String action) async {
    if (isReplying.value) return;
    inputController.text = action;
    messageInput.value = action;
    await _submitQuestion(action);
  }

  // ── Finance intent detection ───────────────────────────────────────────────

  static final _expenseIntentRe = RegExp(
    r'\b(?:add|record|log|save|ongeza|rekodi|hifadhi|weka)\b.{0,30}'
    r'\b(?:expense|gharama|matumizi|cost|charge|bill|malipo ya nje)\b'
    r'|\b(?:expense|gharama|matumizi)\b.{0,20}'
    r'\b(?:add|record|log|save|ongeza|rekodi|hifadhi|weka)\b',
    caseSensitive: false,
  );

  static final _incomeIntentRe = RegExp(
    r'\b(?:add|record|log|save|ongeza|rekodi|hifadhi|weka)\b.{0,30}'
    r'\b(?:income|payment|revenue|mapato|malipo|kodi iliyolipwa|pato)\b'
    r'|\b(?:income|payment|revenue|mapato|malipo|kodi iliyolipwa)\b.{0,20}'
    r'\b(?:add|record|log|save|ongeza|rekodi|hifadhi|weka)\b',
    caseSensitive: false,
  );

  static final _tenantIntentRe = RegExp(
    r'\b(?:add|new|ongeza|mpya)\b.{0,20}\b(?:tenant|mpangaji|renter|lodger)\b'
    r'|\b(?:tenant|mpangaji)\b.{0,20}\b(?:add|new|ongeza|mpya)\b'
    r'|\b(?:end|remove|ondoa|maliza|kumaliza|acha)\b.{0,20}'
    r'\b(?:tenancy|tenants?|mpangaji|kukaa|lease)\b'
    r'|\b(?:tenant|mpangaji)\b.{0,20}'
    r'\b(?:leaving|vacating|anaondoka|kuondoka|not\s+renewing)\b',
    caseSensitive: false,
  );

  static final _bnbGuestIntentRe = RegExp(
    r'\bcheck.?in\b'
    r'|\bcheck.?out\b'
    r'|\b(?:pokesha|shusha)\s+mgeni\b'
    r'|\b(?:new|arrival|arriving|arriving)\b.{0,20}\b(?:guest|visitor|mgeni)\b'
    r'|\b(?:guest|mgeni)\b.{0,20}\b(?:arriving|leaving|checking|check)\b'
    r'|\b(?:mgeni\s+(?:mpya|anaondoka|amefika|anafika))\b',
    caseSensitive: false,
  );

  static final _maintenanceIntentRe = RegExp(
    r'\b(?:schedule|panga|plan|add)\b.{0,25}'
    r'\b(?:maintenance|matengenezo|repair|marekebisho|service|fix|plumb|electric)\b'
    r'|\b(?:maintenance|matengenezo|repair)\b.{0,20}'
    r'\b(?:schedule|panga|add|ongeza)\b'
    r'|\badd\s+(?:a\s+)?task\b'
    r'|\bongeza\s+kazi\b'
    r'|\bnew\s+task\b'
    r'|\btodo\b|\bto-do\b'
    r'|\b(?:kazi\s+mpya)\b',
    caseSensitive: false,
  );

  static final _propertyIntentRe = RegExp(
    r'\b(?:add|new|create|ongeza|mpya|weka)\b.{0,30}'
    r'\b(?:property|listing|mali|nyumba|apartment|house)\b'
    r'|\b(?:property|listing|mali|nyumba)\b.{0,20}'
    r'\b(?:add|new|create|ongeza|mpya)\b'
    r'|\badd\s+(?:a\s+)?unit\b'
    r'|\bongeza\s+unit\b'
    r'|\bnew\s+unit\b',
    caseSensitive: false,
  );

  Future<void> _submitQuestion(String text) async {
    messages.add(
      AiChatMessage(
        text: text,
        fromAssistant: false,
        role: _isSw ? 'Mwenye nyumba' : 'Host',
        time: _nowLabel(),
      ),
    );
    inputController.clear();
    messageInput.value = '';
    _scrollToEnd();

    isReplying.value = true;

    // ── If a multi-turn maintenance/task flow is active, route to it ─────
    if (_activeMaintenanceFlow != null) {
      final flow = _activeMaintenanceFlow!;
      try {
        final reply = await flow.handleTurn(text);
        if (flow.isComplete) _activeMaintenanceFlow = null;
        messages.add(AiChatMessage(
          fromAssistant: true,
          role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
          time: _nowLabel(),
          text: reply,
        ));
      } catch (e) {
        _activeMaintenanceFlow = null;
        messages.add(AiChatMessage(
          fromAssistant: true,
          role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
          time: _nowLabel(),
          text: _isSw ? '❌ Hitilafu imetokea: $e' : '❌ Something went wrong: $e',
        ));
      } finally {
        isReplying.value = false;
        _scrollToEnd();
      }
      return;
    }

    // ── If a multi-turn tenant flow is active, route to it ───────────────
    if (_activeTenantFlow != null) {
      final flow = _activeTenantFlow!;
      try {
        final reply = await flow.handleTurn(text);
        if (flow.isComplete) _activeTenantFlow = null;
        messages.add(AiChatMessage(
          fromAssistant: true,
          role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
          time: _nowLabel(),
          text: reply,
        ));
      } catch (e) {
        _activeTenantFlow = null;
        messages.add(AiChatMessage(
          fromAssistant: true,
          role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
          time: _nowLabel(),
          text: _isSw ? '❌ Hitilafu imetokea: $e' : '❌ Something went wrong: $e',
        ));
      } finally {
        isReplying.value = false;
        _scrollToEnd();
      }
      return;
    }

    // ── If a multi-turn BnB guest flow is active, route to it ────────────
    if (_activeBnbGuestFlow != null) {
      final flow = _activeBnbGuestFlow!;
      try {
        final reply = await flow.handleTurn(text);
        if (flow.isComplete) _activeBnbGuestFlow = null;
        messages.add(AiChatMessage(
          fromAssistant: true,
          role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
          time: _nowLabel(),
          text: reply,
        ));
      } catch (e) {
        _activeBnbGuestFlow = null;
        messages.add(AiChatMessage(
          fromAssistant: true,
          role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
          time: _nowLabel(),
          text: _isSw ? '❌ Hitilafu imetokea: $e' : '❌ Something went wrong: $e',
        ));
      } finally {
        isReplying.value = false;
        _scrollToEnd();
      }
      return;
    }

    // ── If a multi-turn property flow is active, route to it ─────────────
    if (_activePropertyFlow != null) {
      final flow = _activePropertyFlow!;
      try {
        final reply = await flow.handleTurn(text);
        if (flow.isComplete) _activePropertyFlow = null;
        messages.add(AiChatMessage(
          fromAssistant: true,
          role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
          time: _nowLabel(),
          text: reply,
        ));
      } catch (e) {
        _activePropertyFlow = null;
        messages.add(AiChatMessage(
          fromAssistant: true,
          role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
          time: _nowLabel(),
          text: _isSw
              ? '❌ Hitilafu imetokea: $e'
              : '❌ Something went wrong: $e',
        ));
      } finally {
        isReplying.value = false;
        _scrollToEnd();
      }
      return;
    }

    // ── If a multi-turn finance flow is active, route to it ───────────────
    if (_activeFlow != null) {
      final flow = _activeFlow!;
      try {
        final reply = await flow.handleTurn(text);
        if (flow.isComplete) _activeFlow = null;
        messages.add(AiChatMessage(
          fromAssistant: true,
          role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
          time: _nowLabel(),
          text: reply,
        ));
      } catch (e) {
        _activeFlow = null;
        messages.add(AiChatMessage(
          fromAssistant: true,
          role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
          time: _nowLabel(),
          text: _isSw
              ? '❌ Hitilafu imetokea: $e'
              : '❌ Something went wrong: $e',
        ));
      } finally {
        isReplying.value = false;
        _scrollToEnd();
      }
      return;
    }

    messages.add(
      AiChatMessage(
        text: _isSw ? 'Inachambua data yako...' : 'Analyzing your portfolio...',
        fromAssistant: true,
        role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
        time: _nowLabel(),
        isTyping: true,
      ),
    );
    _scrollToEnd();

    try {
      // ── Property / unit creation flow ─────────────────────────────────
      if (_propertyIntentRe.hasMatch(text)) {
        final reply = await _startPropertyFlow();
        messages.removeLast();
        messages.add(AiChatMessage(
          fromAssistant: true,
          role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
          time: _nowLabel(),
          text: reply,
        ));
        return;
      }

      // ── Maintenance / task flow ───────────────────────────────────────
      if (_maintenanceIntentRe.hasMatch(text)) {
        final reply = await _startMaintenanceFlow();
        messages.removeLast();
        messages.add(AiChatMessage(
          fromAssistant: true,
          role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
          time: _nowLabel(),
          text: reply,
        ));
        return;
      }

      // ── Tenant management flow ────────────────────────────────────────
      if (_tenantIntentRe.hasMatch(text)) {
        final reply = await _startTenantFlow();
        messages.removeLast();
        messages.add(AiChatMessage(
          fromAssistant: true,
          role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
          time: _nowLabel(),
          text: reply,
        ));
        return;
      }

      // ── BnB guest check-in / check-out flow ───────────────────────────
      if (_bnbGuestIntentRe.hasMatch(text)) {
        final reply = await _startBnbGuestFlow();
        messages.removeLast();
        messages.add(AiChatMessage(
          fromAssistant: true,
          role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
          time: _nowLabel(),
          text: reply,
        ));
        return;
      }

      // ── Finance flow: add expense ─────────────────────────────────────
      if (_expenseIntentRe.hasMatch(text)) {
        final reply = await _startFinanceFlow('expense');
        messages.removeLast();
        messages.add(AiChatMessage(
          fromAssistant: true,
          role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
          time: _nowLabel(),
          text: reply,
        ));
        return;
      }

      // ── Finance flow: record income ───────────────────────────────────
      if (_incomeIntentRe.hasMatch(text)) {
        final reply = await _startFinanceFlow('income');
        messages.removeLast();
        messages.add(AiChatMessage(
          fromAssistant: true,
          role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
          time: _nowLabel(),
          text: reply,
        ));
        return;
      }

      // ── Inventory query: "list all", "low stock" ──────────────────────
      final inventoryListReply = await _tryInventoryQuery(text);
      if (inventoryListReply != null) {
        messages.removeLast();
        messages.add(AiChatMessage(
          fromAssistant: true,
          role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
          time: _nowLabel(),
          text: inventoryListReply,
        ));
        return;
      }

      // ── Inventory stock adjustment via NLP ────────────────────────────
      if (InventoryNlpParser.looksLikeInventoryCommand(text)) {
        final commands = InventoryNlpParser.parse(text);
        if (commands.isNotEmpty) {
          final reply = await _applyInventoryCommands(commands);
          messages.removeLast();
          messages.add(AiChatMessage(
            fromAssistant: true,
            role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
            time: _nowLabel(),
            text: reply,
          ));
          return;
        }
      }

      // ── General AI answer ─────────────────────────────────────────────
      final history = messages
          .where((m) => !m.isTyping)
          .map((m) => {
                'role': m.fromAssistant ? 'assistant' : 'user',
                'text': m.text,
              })
          .toList();

      final reply = await _hybrid.answer(
        question: text,
        isSw: _isSw || _looksSwahili(text),
        conversation: history,
      );

      messages.removeLast();
      messages.add(
        AiChatMessage(
          fromAssistant: true,
          role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
          time: _nowLabel(),
          text: reply,
        ),
      );
    } catch (e) {
      messages.removeLast();
      messages.add(
        AiChatMessage(
          fromAssistant: true,
          role: _isSw ? 'Msaidizi wa AI' : 'AI Assistant',
          time: _nowLabel(),
          text: _isSw
              ? 'Hitilafu imetokea. Jaribu tena au uliza swali la moja kwa moja kama "Muhtasari wa portfolio".'
              : 'Something went wrong. Try again or ask a direct question like "Portfolio summary".',
        ),
      );
    } finally {
      isReplying.value = false;
      _scrollToEnd();
    }
  }

  // ── Finance flow starter ──────────────────────────────────────────────────

  Future<String> _startFinanceFlow(String type) async {
    final isSw = _isSw;
    List<PropertyRecord> props = [];
    try {
      if (Get.isRegistered<PropertyLocalDataSource>()) {
        final src = Get.find<PropertyLocalDataSource>();
        props = await src.getAllNewestFirst();
      }
    } catch (_) {}

    if (props.isEmpty) {
      return isSw
          ? 'Samahani, hakuna mali iliyorekodiwa kwenye akaunti yako. '
            'Ongeza mali kwanza kupitia "My Properties".'
          : 'Sorry, no properties found on your account. '
            'Please add a property via "My Properties" first.';
    }

    final flow = AiFinanceFlow(type: type, isSw: isSw, properties: props);
    final opening = flow.openingPrompt;
    if (!flow.isComplete) {
      _activeFlow = flow;
    }
    return opening;
  }

  // ── Property / unit creation flow starter ────────────────────────────────

  Future<String> _startPropertyFlow() async {
    final isSw = _isSw;
    List<PropertyRecord> props = [];
    try {
      if (Get.isRegistered<PropertyLocalDataSource>()) {
        props = await Get.find<PropertyLocalDataSource>().getAllNewestFirst();
      }
    } catch (_) {}

    final flow = AiPropertyFlow(isSw: isSw, existingProperties: props);
    final opening = flow.openingPrompt;
    if (!flow.isComplete) {
      _activePropertyFlow = flow;
    }
    return opening;
  }

  // ── Maintenance / task flow starter ──────────────────────────────────────

  Future<String> _startMaintenanceFlow() async {
    final isSw = _isSw;
    List<PropertyRecord> props = [];
    try {
      if (Get.isRegistered<PropertyLocalDataSource>()) {
        props = await Get.find<PropertyLocalDataSource>().getAllNewestFirst();
      }
    } catch (_) {}
    final flow = AiMaintenanceFlow(isSw: isSw, properties: props);
    final opening = flow.openingPrompt;
    if (!flow.isComplete) _activeMaintenanceFlow = flow;
    return opening;
  }

  // ── Tenant flow starter ───────────────────────────────────────────────────

  Future<String> _startTenantFlow() async {
    final isSw = _isSw;
    List<PropertyRecord> props = [];
    try {
      if (Get.isRegistered<PropertyLocalDataSource>()) {
        props = await Get.find<PropertyLocalDataSource>().getAllNewestFirst();
      }
    } catch (_) {}

    if (props.isEmpty) {
      return isSw
          ? 'Samahani, hakuna mali iliyorekodiwa. Ongeza mali kwanza.'
          : 'Sorry, no properties found. Please add a property first.';
    }

    final flow = AiTenantFlow(isSw: isSw, properties: props);
    final opening = flow.openingPrompt;
    if (!flow.isComplete) _activeTenantFlow = flow;
    return opening;
  }

  // ── BnB guest flow starter ────────────────────────────────────────────────

  Future<String> _startBnbGuestFlow() async {
    final isSw = _isSw;
    List<PropertyRecord> bnbProps = [];
    try {
      if (Get.isRegistered<PropertyLocalDataSource>()) {
        final all = await Get.find<PropertyLocalDataSource>().getAllNewestFirst();
        // Include properties that are BnB or support both modes
        bnbProps = all.where((p) {
          final ws = p.workspaceType.trim().toLowerCase();
          return ws == 'bnb' || ws == 'both';
        }).toList();
      }
    } catch (_) {}

    if (bnbProps.isEmpty) {
      return isSw
          ? 'Samahani, hakuna mali ya BnB iliyopatikana. Ongeza mali ya BnB kwanza.'
          : 'Sorry, no BnB properties found. Please add a BnB property first.';
    }

    final flow = AiBnbGuestFlow(isSw: isSw, bnbProperties: bnbProps);
    final opening = flow.openingPrompt;
    if (!flow.isComplete) _activeBnbGuestFlow = flow;
    return opening;
  }

  // ── Inventory list / query helper ─────────────────────────────────────────

  static final _listAllRe = RegExp(
    r'\b(?:list|show|orodha|onyesha)\b.*\b(?:inventory|vifaa|items?|stock)\b'
    r'|\b(?:inventory|vifaa)\b.*\b(?:list|orodha)\b',
    caseSensitive: false,
  );
  static final _lowStockRe = RegExp(
    r'\b(?:low\s*stock|bidhaa\s*chini|vifaa\s*vichache|out\s*of\s*stock)\b',
    caseSensitive: false,
  );

  Future<String?> _tryInventoryQuery(String text) async {
    final isSw = _isSw || _looksSwahili(text);
    if (!Get.isRegistered<InventoryItemLocalDataSource>()) return null;

    final src = Get.find<InventoryItemLocalDataSource>();

    if (_lowStockRe.hasMatch(text)) {
      final db = await src.database;
      const t = 'inventory_item';
      final rows = await db.rawQuery(
        "SELECT name, quantity, reorder_level, property_label, apartment_unit_name "
        "FROM $t WHERE reorder_level > 0 AND quantity <= reorder_level "
        "ORDER BY quantity ASC LIMIT 20",
      );
      if (rows.isEmpty) {
        return isSw
            ? '✅ Hakuna bidhaa zenye idadi ya chini kwa sasa.'
            : '✅ No low-stock items at the moment — all levels look good.';
      }
      final lines = rows.map((r) {
        final name    = r['name'] as String? ?? '';
        final qty     = r['quantity'] as int? ?? 0;
        final reorder = r['reorder_level'] as int? ?? 0;
        final prop    = r['property_label'] as String? ?? '';
        final unit    = r['apartment_unit_name'] as String? ?? '';
        final where   = [prop, unit].where((s) => s.isNotEmpty).join(' · ');
        return '• $name — qty $qty / reorder $reorder'
            '${where.isNotEmpty ? '  ($where)' : ''}';
      });
      final header = isSw
          ? '⚠️ Bidhaa zenye idadi ya chini (${rows.length}):\n'
          : '⚠️ Low-stock items (${rows.length}):\n';
      return header + lines.join('\n');
    }

    if (_listAllRe.hasMatch(text)) {
      final db = await src.database;
      const t = 'inventory_item';
      final rows = await db.rawQuery(
        "SELECT name, quantity, reorder_level, property_label, apartment_unit_name "
        "FROM $t ORDER BY property_label, name LIMIT 50",
      );
      if (rows.isEmpty) {
        return isSw
            ? 'Bado hakuna vifaa vilivyorekodiwa.'
            : 'No inventory items recorded yet.';
      }
      final lines = rows.map((r) {
        final name  = r['name'] as String? ?? '';
        final qty   = r['quantity'] as int? ?? 0;
        final reorder = r['reorder_level'] as int? ?? 0;
        final low   = reorder > 0 && qty <= reorder;
        final flag  = low ? ' ⚠️' : '';
        final prop  = r['property_label'] as String? ?? '';
        final unit  = r['apartment_unit_name'] as String? ?? '';
        final where = [prop, unit].where((s) => s.isNotEmpty).join(' · ');
        return '• $name — $qty${where.isNotEmpty ? '  ($where)' : ''}$flag';
      });
      final header = isSw
          ? '📦 Orodha ya vifaa (${rows.length}):\n'
          : '📦 Inventory list (${rows.length} items):\n';
      final footer = rows.length == 50
          ? (isSw ? '\n_(inaonyesha 50 za kwanza)_' : '\n_(showing first 50)_')
          : '';
      return header + lines.join('\n') + footer;
    }

    return null;
  }

  // ── Inventory NLP command executor ────────────────────────────────────────

  Future<String> _applyInventoryCommands(
      List<InventoryCommand> commands) async {
    final isSw = _isSw;
    if (!Get.isRegistered<InventoryItemLocalDataSource>()) {
      return isSw
          ? 'Samahani, moduli ya vifaa haijapakiwa bado.'
          : 'Sorry, the inventory module is not loaded yet.';
    }

    final itemSrc     = Get.find<InventoryItemLocalDataSource>();
    final movementSrc = Get.find<InventoryMovementLocalDataSource>();

    // Load all items once
    final db = await itemSrc.database;
    const t = 'inventory_item';
    final allRows = await db.rawQuery(
      "SELECT id, name, quantity, reorder_level, property_label, "
      "apartment_unit_name, backend_item_id FROM $t",
    );

    final allItems = allRows
        .map((r) => _SimpleItem(
              id: r['id'] as int,
              name: r['name'] as String? ?? '',
              quantity: (r['quantity'] as num?)?.toInt() ?? 0,
              reorderLevel: (r['reorder_level'] as num?)?.toInt() ?? 0,
              propertyLabel: r['property_label'] as String? ?? '',
              unitName: r['apartment_unit_name'] as String? ?? '',
            ))
        .toList();

    final applied  = <String>[];
    final notFound = <String>[];

    for (final cmd in commands) {
      final matches = InventoryNlpParser.fuzzyMatch<_SimpleItem>(
        items: allItems,
        nameOf: (i) => i.name,
        hint: cmd.itemHint,
      );

      if (matches.isEmpty) {
        notFound.add(cmd.itemHint);
        continue;
      }

      // Apply to every matching item (usually 1; multiple if e.g. "towels" matches
      // "bathroom towels" and "pool towels")
      for (final item in matches) {
        final delta  = (cmd.movementType == 'use' || cmd.movementType == 'damage')
            ? -cmd.quantity
            : cmd.quantity;
        final newQty = (item.quantity + delta).clamp(0, 999999);

        await itemSrc.updateQuantity(item.id, newQty);
        final clientId =
            'ai_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}';
        await movementSrc.insert(
          itemLocalId: item.id,
          clientMovementId: clientId,
          movementType: cmd.movementType,
          quantityDelta: delta,
          notes: isSw ? 'Kutoka AI Manager' : 'From AI Manager',
        );

        final where = [item.propertyLabel, item.unitName]
            .where((s) => s.isNotEmpty)
            .join(' · ');
        final low = item.reorderLevel > 0 && newQty <= item.reorderLevel;
        final lowFlag = low ? (isSw ? ' ⚠️ Bidhaa idadi ya chini!' : ' ⚠️ low stock!') : '';
        applied.add(
          isSw
              ? '• ${_swActionLabel(cmd.movementType)} ×${cmd.quantity} '
                  '"${item.name}" → idadi mpya: $newQty'
                  '${where.isNotEmpty ? '  ($where)' : ''}$lowFlag'
              : '• ${_enActionLabel(cmd.movementType)} ×${cmd.quantity} '
                  '"${item.name}" → new qty: $newQty'
                  '${where.isNotEmpty ? '  ($where)' : ''}$lowFlag',
        );
      }
    }

    final buf = StringBuffer();
    if (applied.isNotEmpty) {
      buf.writeln(isSw ? '✅ Bidhaa imesasishwa:\n' : '✅ Stock updated:\n');
      buf.writeln(applied.join('\n'));
    }
    if (notFound.isNotEmpty) {
      buf.writeln(
        isSw
            ? '\n❓ Sikupata vifaa hivi: ${notFound.map((s) => '"$s"').join(', ')}.\n'
              'Angalia tahajia au uongeze kipengele kwenye Ufuatiliaji wa Vifaa kwanza.'
            : '\n❓ Could not find: ${notFound.map((s) => '"$s"').join(', ')}.\n'
              'Check the spelling or add the item in Inventory Tracking first.',
      );
    }
    if (applied.isEmpty && notFound.isEmpty) {
      return isSw
          ? 'Samahani, sikuweza kuelewa amri hiyo ya bidhaa.'
          : 'Sorry, I couldn\'t understand that stock command.';
    }
    return buf.toString().trim();
  }

  static String _enActionLabel(String type) {
    switch (type) {
      case 'use':     return 'Used';
      case 'add':     return 'Added';
      case 'restock': return 'Restocked';
      case 'damage':  return 'Damaged';
      default:        return 'Adjusted';
    }
  }

  static String _swActionLabel(String type) {
    switch (type) {
      case 'use':     return 'Imetumika';
      case 'add':     return 'Imeongezwa';
      case 'restock': return 'Imejazwa';
      case 'damage':  return 'Imeharibiwa';
      default:        return 'Imerekebishwa';
    }
  }

  String _nowLabel() => _timeFmt.format(DateTime.now());

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }
}

// ── Lightweight item model for AI command execution ──────────────────────────

class _SimpleItem {
  const _SimpleItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.reorderLevel,
    required this.propertyLabel,
    required this.unitName,
  });

  final int id;
  final String name;
  final int quantity;
  final int reorderLevel;
  final String propertyLabel;
  final String unitName;
}
