import 'dart:convert';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../model/general_response.dart';
import '../../repository/app_repository.dart';
import 'currency_service.dart';
import 'portfolio_ai_context.dart';
import 'portfolio_ai_context_service.dart';
import 'portfolio_ai_local_resolver.dart';

class PortfolioAiHybridService extends GetxService {
  PortfolioAiHybridService({
    required PortfolioAiContextService contextService,
    required AppRepository repository,
    CurrencyService? currencyService,
  })  : _contextService = contextService,
        _repository = repository,
        _currencyOverride = currencyService;

  final PortfolioAiContextService _contextService;
  final AppRepository _repository;
  final CurrencyService? _currencyOverride;

  String formatMoney(num amount) {
    try {
      final fx = _currencyOverride ?? Get.find<CurrencyService>();
      return fx.formatBase(amount);
    } catch (_) {
      final sym = CurrencyService.symbolFor(CurrencyService.defaultBaseCurrency);
      return '$sym${NumberFormat('#,###', 'en_US').format(amount.round())}';
    }
  }

  Future<PortfolioAiContext> loadContext() async {
    try {
      return await _contextService.build();
    } catch (_) {
      return PortfolioAiContext.empty();
    }
  }

  /// Hybrid answer: local metrics when recognized, otherwise LLM with context JSON.
  Future<String> answer({
    required String question,
    required bool isSw,
    List<Map<String, String>> conversation = const [],
  }) async {
    final ctx = await loadContext();

    final local = PortfolioAiLocalResolver.resolve(
      question: question,
      ctx: ctx,
      formatMoney: formatMoney,
      isSw: isSw,
    );
    if (local.matched) return local.text;

    return _answerViaLlm(
      question: question,
      ctx: ctx,
      isSw: isSw,
      conversation: conversation,
    );
  }

  Future<String> welcomeMessage({required bool isSw}) async {
    try {
      final ctx = await loadContext();
      return ctx.welcomeSummary(formatMoney: formatMoney, isSw: isSw);
    } catch (_) {
      return isSw
          ? 'Nipo tayari kujibu maswali kuhusu mali zako. Uliza kuhusu ukodishaji, mapato, deni, au mikataba.'
          : 'I am ready to answer questions about your properties. Ask about occupancy, income, arrears, or leases.';
    }
  }

  Future<String> _answerViaLlm({
    required String question,
    required PortfolioAiContext ctx,
    required bool isSw,
    required List<Map<String, String>> conversation,
  }) async {
    final history = conversation
        .take(6)
        .map((m) => '${m['role'] ?? 'user'}: ${m['text'] ?? ''}')
        .join('\n');

    final lang = isSw ? 'Swahili' : 'English';
    final prompt = '''
You are the portfolio AI assistant inside a landlord app (${ctx.workspace} workspace).
Language rules:
- The user may ask in English, Swahili, or mixed Swahili-English.
- Reply in the same language as the user's question.
- If the app language is Swahili, prefer Swahili unless the user asks in English.
Domain vocabulary:
- mapato = income, revenue, rent collected
- matumizi / gharama = expenses, costs
- faida = profit
- mpangaji / wapangaji = tenant / tenants
- mgeni / wageni = guest / guests
- nyumba / chumba / unit = property / room / unit
- deni = arrears, unpaid balance
- malipo = payment
- kodi = rent
- mkataba = lease / contract
- umeme / LUKU = electricity
- maji = water
- matengenezo = maintenance
- kiwango cha ukodishaji = occupancy rate
Answer ONLY using the JSON context below. Do not invent numbers.
If the answer is not in the context, say you do not have that data yet and suggest what the user can record in the app.
Reply in $lang. Be concise (2-5 sentences). Use plain text, no markdown.

Portfolio context JSON:
${jsonEncode(ctx.toJson())}

Recent messages:
${history.isEmpty ? '(none)' : history}

User question: $question
''';

    try {
      final res = await _repository.sendAiRequest({
        'prompt': prompt,
        'type': 'portfolio_chat',
        'workspace': ctx.workspace,
      });
      final text = _extractReplyText(res);
      if (text.trim().isNotEmpty) return text.trim();
    } catch (_) {}

    return isSw
        ? 'Siwezi kupata jibu kutoka kwa AI kwa sasa. Jaribu swali kama "Kiwango cha ukodishaji?" au "Muhtasari wa portfolio".'
        : 'I could not reach the AI service right now. Try a direct question like '
            '"What\'s my occupancy rate?" or "Portfolio summary" for instant answers from your data.';
  }

  static String _extractReplyText(GeneralResponse res) {
    if (res.responseCode != null && res.responseCode != '0') {
      final msg = res.message?.trim() ?? '';
      if (msg.isNotEmpty) return msg;
    }
    final data = res.data;
    if (data is String) return data;
    if (data is Map) {
      for (final key in ['text', 'reply', 'answer', 'content', 'message']) {
        final v = data[key]?.toString().trim() ?? '';
        if (v.isNotEmpty) return v;
      }
    }
    return data?.toString() ?? '';
  }
}
