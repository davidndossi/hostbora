import 'package:get/get.dart';

import '../../data/local/preference/preference_manager.dart';

/// Remembers the value a host last chose for a repeated form field so the next
/// entry opens on it instead of blank.
///
/// Every operation is best-effort: an unregistered [PreferenceManager] or a
/// storage failure degrades to "no recall" rather than breaking the form.
class FormRecall {
  FormRecall._();

  static PreferenceManager? get _prefs {
    try {
      final tag = (PreferenceManager).toString();
      return Get.isRegistered<PreferenceManager>(tag: tag)
          ? Get.find<PreferenceManager>(tag: tag)
          : null;
    } catch (_) {
      return null;
    }
  }

  static Future<String> read(String key) async {
    try {
      final value = await _prefs?.getString(key);
      return value?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Blank values are not persisted, so clearing a field does not wipe the
  /// recall the host built up.
  static Future<void> write(String key, String? value) async {
    final next = value?.trim() ?? '';
    if (next.isEmpty) return;
    try {
      await _prefs?.setString(key, next);
    } catch (_) {}
  }

  /// Reads [key] and returns it only if it is still one of [options].
  ///
  /// Guards the case where the remembered property or category has since been
  /// renamed or deleted — a stale recall would otherwise select nothing while
  /// looking like a valid choice.
  static Future<String> readAmong(
    String key,
    Iterable<String> options,
  ) async {
    final value = await read(key);
    if (value.isEmpty) return '';
    return options.contains(value) ? value : '';
  }
}

/// Gives a controller the full "open on the host's last choice" behaviour in
/// one call, so a new form inherits it rather than re-deriving the order of
/// recall, single-option and fallback.
///
/// Mix in and call [recallChoice] while loading options:
/// ```dart
/// selectedProperty.value = await recallChoice(
///   key: UiPreferenceKeys.addTaskProperty,
///   options: options,
///   fallback: RecallFallback.firstOption,
/// );
/// ```
mixin FormRecallMixin {
  /// Resolves the value a picker should open on, in priority order: the
  /// remembered choice if it is still valid, then a lone option because there
  /// is no choice to make, then [fallback].
  ///
  /// Returns an empty string when nothing applies, which leaves the field
  /// blank — the right outcome for anything that moves money, where a wrong
  /// pre-selection costs more than a tap.
  Future<String> recallChoice({
    required String key,
    required Iterable<String> options,
    RecallFallback fallback = RecallFallback.leaveBlank,
  }) async {
    final list = options.toList(growable: false);
    if (list.isEmpty) return '';

    final recalled = await FormRecall.readAmong(key, list);
    if (recalled.isNotEmpty) return recalled;
    if (list.length == 1) return list.first;
    return fallback == RecallFallback.firstOption ? list.first : '';
  }

  /// Stores [value] against [key]. Fire-and-forget by design: a save must not
  /// wait on, or fail because of, a convenience write.
  void rememberChoice(String key, String? value) {
    FormRecall.write(key, value).ignore();
  }
}

/// What [FormRecallMixin.recallChoice] does when there is no recall and more
/// than one option.
enum RecallFallback {
  /// Leave the field blank. Correct wherever a wrong pick has a cost the host
  /// would have to undo — filing a payment against the wrong building.
  leaveBlank,

  /// Select the first option. Correct where the choice is cheap to change and
  /// carries no money, such as which property a task belongs to.
  firstOption,
}
