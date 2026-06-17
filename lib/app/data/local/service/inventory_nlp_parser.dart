/// Natural-language parser for stock adjustment commands.
///
/// Understands both English and Swahili freeform sentences like:
///   "Used 2 towels, restocked 10 soap"
///   "Nimetumia taulo 2, nimejaza sabuni 10"
///   "Damaged 1 kettle"
///   "Added 5 bed sheets"
///
/// Each recognised verb+quantity+item triplet becomes an [InventoryCommand].
/// Caller is responsible for fuzzy-matching [InventoryCommand.itemHint] against
/// the actual inventory list.

class InventoryCommand {
  const InventoryCommand({
    required this.movementType,
    required this.quantity,
    required this.itemHint,
    required this.rawSegment,
  });

  /// One of: 'use', 'add', 'restock', 'damage', 'adjust'
  final String movementType;

  /// Always a positive integer; the caller must negate for 'use' / 'damage'.
  final int quantity;

  /// Item name as found in the original text — may be partial/misspelled.
  final String itemHint;

  /// The raw substring that produced this command (useful for debug / UI).
  final String rawSegment;

  @override
  String toString() =>
      'InventoryCommand($movementType ×$quantity "$itemHint")';
}

class InventoryNlpParser {
  InventoryNlpParser._();

  // ── English verb groups ────────────────────────────────────────────────

  static const _verbUse = r'(?:used?|consumed?|took|taken)';
  static const _verbAdd =
      r'(?:added?|add|put in|put back|placed?|received?|got)';
  static const _verbRestock =
      r'(?:restocked?|re-stocked?|refilled?|replenished?|topped? up|kujaza|jaza)';
  static const _verbDamage =
      r'(?:damaged?|broken?|broke|destroyed?|lost?|threw? away|discarded?)';

  // ── Swahili verb groups ────────────────────────────────────────────────

  static const _swVerbUse =
      r'(?:nimetumia|nilitumia|ametumia|tumia|imetumika|ilitumika|nilipotumia)';
  static const _swVerbAdd =
      r'(?:nimeongeza|niliongeza|nimeingiza|nimeweka|niliweka|nimerudisha|ongeza)';
  static const _swVerbRestock =
      r'(?:nimejaza|nilijaza|nimekujaza|imejazwa|imejaa|jaza)';
  static const _swVerbDamage =
      r'(?:imeharibiwa|imeharibika|imevunjika|imevunjwa|ilivunjika|iliharibika|nimepoteza|nilipoteza|inapotea)';

  // ── Number word → int ──────────────────────────────────────────────────

  static const _wordNums = {
    'one': 1,    'two': 2,    'three': 3,  'four': 4,  'five': 5,
    'six': 6,    'seven': 7,  'eight': 8,  'nine': 9,  'ten': 10,
    'eleven': 11,'twelve': 12,'fifteen': 15,'twenty': 20,'thirty': 30,
    'forty': 40, 'fifty': 50, 'hundred': 100,
    // Swahili
    'moja': 1,   'mbili': 2,  'tatu': 3,   'nne': 4,   'tano': 5,
    'sita': 6,   'saba': 7,   'nane': 8,   'tisa': 9,  'kumi': 10,
    'kumi na moja': 11, 'kumi na mbili': 12, 'ishirini': 20,
    'thelathini': 30,   'arobaini': 40, 'hamsini': 50,
  };

  // Item name: 1–6 word sequence of letters/hyphens (stops at punctuation)
  static const _itemPat = r'([\w][\w\s\-]{1,50}?)';

  // ── Segment splitter: comma, "and", "na" ──────────────────────────────

  static final _splitter = RegExp(r'[,;]|\band\b|\bna\b', caseSensitive: false);

  // ── Master regex list ─────────────────────────────────────────────────
  //
  // Each entry: (movementType, pattern)
  // Pattern must have named group (?<n>…) for quantity and (?<i>…) for item.
  // Quantity may come before or after the item name.
  //
  // Order matters: more specific verbs first.

  static final _rules = <(String, RegExp)>[
    // ── English ──────────────────────────────────────────────────────────
    // "used 2 towels"  /  "used towels 2"
    ('use',     _r(r'(?:' + _verbUse     + r')\s+' + _numItemOrItemNum)),
    ('add',     _r(r'(?:' + _verbAdd     + r')\s+' + _numItemOrItemNum)),
    ('restock', _r(r'(?:' + _verbRestock + r')\s+' + _numItemOrItemNum)),
    ('damage',  _r(r'(?:' + _verbDamage  + r')\s+' + _numItemOrItemNum)),
    // verb + item (no explicit quantity → assume 1)
    ('use',     _r(r'(?:' + _verbUse     + r')\s+(?<i>' + _itemPat + r')$', noNum: true)),
    ('add',     _r(r'(?:' + _verbAdd     + r')\s+(?<i>' + _itemPat + r')$', noNum: true)),
    ('restock', _r(r'(?:' + _verbRestock + r')\s+(?<i>' + _itemPat + r')$', noNum: true)),
    ('damage',  _r(r'(?:' + _verbDamage  + r')\s+(?<i>' + _itemPat + r')$', noNum: true)),
    // ── Swahili ───────────────────────────────────────────────────────────
    ('use',     _r(r'(?:' + _swVerbUse     + r')\s+' + _numItemOrItemNum)),
    ('add',     _r(r'(?:' + _swVerbAdd     + r')\s+' + _numItemOrItemNum)),
    ('restock', _r(r'(?:' + _swVerbRestock + r')\s+' + _numItemOrItemNum)),
    ('damage',  _r(r'(?:' + _swVerbDamage  + r')\s+' + _numItemOrItemNum)),
    ('use',     _r(r'(?:' + _swVerbUse     + r')\s+(?<i>' + _itemPat + r')$', noNum: true)),
    ('add',     _r(r'(?:' + _swVerbAdd     + r')\s+(?<i>' + _itemPat + r')$', noNum: true)),
    ('restock', _r(r'(?:' + _swVerbRestock + r')\s+(?<i>' + _itemPat + r')$', noNum: true)),
    ('damage',  _r(r'(?:' + _swVerbDamage  + r')\s+(?<i>' + _itemPat + r')$', noNum: true)),
  ];

  // Pattern with both qty and item (either order)
  static const _numItemOrItemNum =
      r'(?:(?<n>\d+|[a-zA-Z]+)\s+(?<i>[\w][\w\s\-]{1,50}?)'   // num first
      r'|(?<i2>[\w][\w\s\-]{1,50}?)\s+(?<n2>\d+|[a-zA-Z]+))'; // item first

  static RegExp _r(String pattern, {bool noNum = false}) =>
      RegExp(pattern, caseSensitive: false);

  // ── Public API ─────────────────────────────────────────────────────────

  /// Parse [text] and return every inventory command found.
  /// Returns an empty list when the text doesn't look like an inventory command.
  static List<InventoryCommand> parse(String text) {
    final results = <InventoryCommand>[];
    // Split on commas / "and" / "na" so each clause is analysed independently.
    final segments =
        text.split(_splitter).map((s) => s.trim()).where((s) => s.isNotEmpty);
    for (final seg in segments) {
      final cmd = _parseSegment(seg);
      if (cmd != null) results.add(cmd);
    }
    return results;
  }

  /// Returns true when [text] contains at least one inventory verb.
  static bool looksLikeInventoryCommand(String text) {
    final lower = text.toLowerCase();
    return _inventoryKeywords.any(lower.contains);
  }

  // Quick set for the pre-check; must be a subset of what the regex handles.
  static const _inventoryKeywords = {
    'used ', 'use ', 'used\n', 'restocked', 'restock', 'refill',
    'added ', 'add ', 'received ', 'put in', 'top up',
    'damaged ', 'damage ', 'broken', 'broke ',
    // Swahili
    'nimetumia', 'nilitumia', 'ametumia',
    'nimejaza',  'nilijaza',  'nimekujaza',
    'nimeongeza','niliongeza','nimeweka', 'niliweka',
    'imeharibiwa','imeharibika','imevunjika',
  };

  // ── Internal ───────────────────────────────────────────────────────────

  static InventoryCommand? _parseSegment(String seg) {
    for (final (type, re) in _rules) {
      final m = re.firstMatch(seg);
      if (m == null) continue;

      // Try named groups; patterns alternate between n/i and n2/i2
      final rawNum  = _tryGroup(m, 'n')  ?? _tryGroup(m, 'n2');
      final rawItem = _tryGroup(m, 'i')  ?? _tryGroup(m, 'i2');

      if (rawItem == null || rawItem.trim().isEmpty) continue;
      final item = rawItem.trim();

      // Parse quantity
      int qty = 1;
      if (rawNum != null) {
        final parsed = int.tryParse(rawNum.trim());
        if (parsed != null && parsed > 0) {
          qty = parsed;
        } else {
          final word = rawNum.trim().toLowerCase();
          final wordVal = _wordNums[word];
          if (wordVal != null) qty = wordVal;
        }
      }

      return InventoryCommand(
        movementType: type,
        quantity: qty,
        itemHint: item,
        rawSegment: seg,
      );
    }
    return null;
  }

  static String? _tryGroup(RegExpMatch m, String name) {
    try {
      return m.namedGroup(name);
    } catch (_) {
      return null;
    }
  }

  /// Fuzzy match: returns items whose name contains [hint] (case-insensitive)
  /// or whose hint contains the item name.
  static List<T> fuzzyMatch<T>({
    required List<T> items,
    required String Function(T) nameOf,
    required String hint,
  }) {
    final h = hint.toLowerCase().trim();
    if (h.isEmpty) return [];
    // Tokenise hint into words (≥3 chars) for partial matching
    final tokens = h
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 3)
        .toList();

    return items.where((item) {
      final n = nameOf(item).toLowerCase();
      // Exact contains check
      if (n.contains(h) || h.contains(n)) return true;
      // Token-based: any token appears in name
      return tokens.any(n.contains);
    }).toList();
  }
}
