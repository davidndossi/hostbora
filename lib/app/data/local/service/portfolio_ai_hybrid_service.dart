import 'dart:convert';

import 'package:get/get.dart';

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
        _currency = currencyService ?? Get.find<CurrencyService>();

  final PortfolioAiContextService _contextService;
  final AppRepository _repository;
  final CurrencyService _currency;

  Future<PortfolioAiContext> loadContext() => _contextService.build();

  /// Hybrid answer: local metrics when recognized, otherwise LLM with context JSON.
  Future<String> answer({
    required String question,
    required bool isSw,
    List<Map<String, String>> conversation = const [],
  }) async {
    final ctx = await _contextService.build();
    final formatMoney = (num n) => _currency.formatBase(n);

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
    final ctx = await _contextService.build();
    return ctx.welcomeSummary(
      formatMoney: (n) => _currency.formatBase(n),
      isSw: isSw,
    );
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
