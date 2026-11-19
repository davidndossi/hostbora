import 'package:flutter/material.dart';

/// One row in [StaffOptionSheetField].
class StaffSheetOption {
  const StaffSheetOption({required this.value, required this.label});

  final String value;
  final String label;
}

/// Role / pay-type picker that does not use [DropdownButtonFormField].
///
/// The material dropdown pushes a route and requests focus. On the staff
/// registry that scrolls the page away from the form (down to the staff list)
/// before the member is saved. A sheet keeps the form where the user left it.
class StaffOptionSheetField extends StatelessWidget {
  const StaffOptionSheetField({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.decoration,
    this.hint,
    this.sheetTitle,
    this.validator,
    this.autovalidateMode,
    this.style,
  });

  final String? value;
  final List<StaffSheetOption> options;
  final ValueChanged<String> onChanged;
  final InputDecoration decoration;
  final String? hint;
  final String? sheetTitle;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
  final TextStyle? style;

  StaffSheetOption? _optionFor(String? raw) {
    final key = raw?.trim() ?? '';
    if (key.isEmpty) return null;
    for (final option in options) {
      if (option.value == key) return option;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _optionFor(value);
    return FormField<String>(
      initialValue: selected?.value,
      validator: validator,
      autovalidateMode: autovalidateMode,
      builder: (state) {
        final shown = _optionFor(state.value);
        final label = shown?.label;
        final hintStyle = Theme.of(context).inputDecorationTheme.hintStyle ??
            TextStyle(color: Theme.of(context).hintColor);
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openSheet(context, state),
          child: InputDecorator(
            decoration: decoration.copyWith(errorText: state.errorText),
            isEmpty: label == null || label.isEmpty,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    (label == null || label.isEmpty) ? (hint ?? '') : label,
                    style: (label == null || label.isEmpty)
                        ? hintStyle
                        : (style ??
                            TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            )),
                  ),
                ),
                Icon(
                  Icons.expand_more_outlined,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSheet(BuildContext context, FormFieldState<String> state) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final onSurface = Theme.of(sheetContext).colorScheme.onSurface;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              if (sheetTitle != null && sheetTitle!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    sheetTitle!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                ),
              for (final option in options)
                ListTile(
                  title: Text(option.label),
                  trailing: option.value == state.value
                      ? Icon(
                          Icons.check_outlined,
                          color: Theme.of(sheetContext).colorScheme.primary,
                        )
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(option.value),
                ),
            ],
          ),
        );
      },
    );
    if (picked == null || picked.isEmpty) return;
    state.didChange(picked);
    onChanged(picked);
  }
}
