import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
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
  AiManagerController()
      : _hybrid = Get.find<PortfolioAiHybridService>();

  final PortfolioAiHybridService _hybrid;

  final messages = <AiChatMessage>[].obs;
  final isReplying = false.obs;
  final messageInput = ''.obs;
  final inputController = TextEditingController();
  final scrollController = ScrollController();

  static final _timeFmt = DateFormat('h:mm a');

  bool get _isSw => Get.locale?.languageCode == 'sw';

  List<String> get quickActions {
    final source = _routeSource();
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
            'Kiwango cha ukodishaji?',
            'Mapato ya mwezi huu',
            'Wapangaji wenye deni?',
            'Mikataba inayoisha hivi karibuni',
            'Muhtasari wa portfolio',
          ]
        : const [
            "What's my occupancy rate?",
            'Monthly income this month',
            'Any tenants in arrears?',
            'Leases expiring soon',
            'Portfolio summary',
          ];
  }

  String? _routeSource() {
    final args = Get.arguments;
    if (args is Map) {
      return args['source']?.toString();
    }
    return null;
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
  void onReady() {
    super.onReady();
    _loadWelcome().then((_) => _maybeAskInitialQuestion());
  }

  Future<void> _maybeAskInitialQuestion() async {
    final q = _routeInitialQuestion();
    if (q == null || isReplying.value) return;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await sendQuickAction(q);
  }

  @override
  void onClose() {
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
      final history = messages
          .where((m) => !m.isTyping)
          .map(
            (m) => {
              'role': m.fromAssistant ? 'assistant' : 'user',
              'text': m.text,
            },
          )
          .toList();

      final reply = await _hybrid.answer(
        question: text,
        isSw: _isSw,
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
