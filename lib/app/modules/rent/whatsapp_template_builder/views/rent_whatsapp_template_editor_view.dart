import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme_tokens.dart';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../data/local/db/rent_whatsapp_template_local_data_source.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_whatsapp_template_builder_controller.dart';

/// Full-screen editor for a WhatsApp approved-template. Opened via `Get.to`
/// from the list view, not registered as a standalone route.
class RentWhatsappTemplateEditorView extends StatefulWidget {
  const RentWhatsappTemplateEditorView({super.key, this.existing});

  final RentWhatsappTemplateRecord? existing;

  @override
  State<RentWhatsappTemplateEditorView> createState() =>
      _RentWhatsappTemplateEditorViewState();
}

class _RentWhatsappTemplateEditorViewState
    extends State<RentWhatsappTemplateEditorView> {
  late final RentWhatsappTemplateBuilderController controller =
      Get.find<RentWhatsappTemplateBuilderController>();

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _headerCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();

  String _category = WaTemplateCategory.utility;
  String _language = 'en_US';
  String _headerType = WaTemplateHeaderType.none;
  final List<WaTemplateButton> _buttons = [];
  final List<TextEditingController> _sampleCtrls = [];

  int? _editingId;
  bool _saving = false;

  bool get _isSw => Get.locale?.languageCode == 'sw';
  bool get _isEditing => _editingId != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _editingId = e.id;
      _nameCtrl.text = e.name;
      _category = e.category;
      _language = e.language;
      _headerType = e.headerType;
      _headerCtrl.text = e.headerText;
      _bodyCtrl.text = e.bodyText;
      _footerCtrl.text = e.footerText;
      _buttons.addAll(e.buttons);
      for (final s in e.sampleVariables) {
        _sampleCtrls.add(TextEditingController(text: s));
      }
    }
    _bodyCtrl.addListener(_syncSampleSlots);
    _syncSampleSlots();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _headerCtrl.dispose();
    _bodyCtrl.removeListener(_syncSampleSlots);
    _bodyCtrl.dispose();
    _footerCtrl.dispose();
    for (final c in _sampleCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  /// Keep sample-variable controller list in sync with `{{n}}` tokens in body.
  void _syncSampleSlots() {
    final matches = RegExp(r'\{\{(\d+)\}\}').allMatches(_bodyCtrl.text);
    final uniq = matches.map((m) => int.parse(m.group(1)!)).toSet().toList()
      ..sort();
    final required = uniq.isEmpty ? 0 : uniq.last;
    setState(() {
      while (_sampleCtrls.length < required) {
        _sampleCtrls.add(TextEditingController());
      }
      while (_sampleCtrls.length > required) {
        _sampleCtrls.removeLast().dispose();
      }
    });
  }

  void _insertVariableToken() {
    final nextIndex = _sampleCtrls.length + 1;
    final sel = _bodyCtrl.selection;
    final text = _bodyCtrl.text;
    final token = '{{$nextIndex}}';
    final offset = sel.isValid ? sel.start : text.length;
    final newText = text.replaceRange(offset, offset, token);
    _bodyCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: offset + token.length),
    );
  }

  List<String> _currentSamples() =>
      _sampleCtrls.map((c) => c.text.trim()).toList();

  Future<void> _saveDraft() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final id = await controller.saveDraft(
        id: _editingId,
        name: _nameCtrl.text,
        category: _category,
        language: _language,
        headerType: _headerType,
        headerText: _headerCtrl.text,
        bodyText: _bodyCtrl.text,
        footerText: _footerCtrl.text,
        buttons: _buttons,
        sampleVariables: _currentSamples(),
      );
      if (id > 0) {
        setState(() => _editingId = id);
        if (mounted) Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      var id = _editingId;
      if (id == null) {
        id = await controller.saveDraft(
          name: _nameCtrl.text,
          category: _category,
          language: _language,
          headerType: _headerType,
          headerText: _headerCtrl.text,
          bodyText: _bodyCtrl.text,
          footerText: _footerCtrl.text,
          buttons: _buttons,
          sampleVariables: _currentSamples(),
        );
        if (id <= 0) return;
        _editingId = id;
      }
      final ok = await controller.submitForApproval(
        id: id,
        name: _nameCtrl.text,
        category: _category,
        language: _language,
        headerType: _headerType,
        headerText: _headerCtrl.text,
        bodyText: _bodyCtrl.text,
        footerText: _footerCtrl.text,
        buttons: _buttons,
        sampleVariables: _currentSamples(),
      );
      if (ok && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? Theme.of(context).scaffoldBackgroundColor : RentTheme.canvas,
      appBar: rentAppBar(
        _isEditing
            ? (_isSw ? 'Hariri kiolezo' : 'Edit template')
            : (_isSw ? 'Kiolezo kipya' : 'New template'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              _previewCard(context),
              const SizedBox(height: 16),
              _sectionTitle(_isSw ? 'Msingi' : 'Basics'),
              _card(child: _basicsSection(context)),
              const SizedBox(height: 14),
              _sectionTitle(_isSw ? 'Kichwa (hiari)' : 'Header (optional)'),
              _card(child: _headerSection(context)),
              const SizedBox(height: 14),
              _sectionTitle(_isSw ? 'Mwili' : 'Body'),
              _card(child: _bodySection(context)),
              const SizedBox(height: 14),
              _sectionTitle(_isSw ? 'Kijachini (hiari)' : 'Footer (optional)'),
              _card(child: _footerSection(context)),
              const SizedBox(height: 14),
              _sectionTitle(_isSw ? 'Vitufe (hiari)' : 'Buttons (optional)'),
              _card(child: _buttonsSection(context)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomBar(context),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: RentTheme.muted,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? context.tokens.cardBackground : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? context.tokens.elevatedSurface : RentTheme.border),
      ),
      child: child,
    );
  }

  Widget _basicsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(_isSw ? 'Jina la kiolezo' : 'Template name'),
        TextFormField(
          controller: _nameCtrl,
          decoration: _decoration(
            hint: 'rent_reminder_polite',
            prefixIcon: const Icon(Icons.tag_rounded, size: 18),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
          ],
          textCapitalization: TextCapitalization.none,
        ),
        const SizedBox(height: 4),
        Text(
          _isSw
              ? 'Herufi ndogo, nambari na _, 3-64 urefu.'
              : 'Lowercase, digits and _, 3-64 characters.',
          style: const TextStyle(fontSize: 11, color: RentTheme.muted),
        ),
        const SizedBox(height: 12),
        _fieldLabel(_isSw ? 'Aina' : 'Category'),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: _decoration(),
          items: [
            for (final c in WaTemplateCategory.values)
              DropdownMenuItem(
                value: c,
                child: Text(WaTemplateCategory.label(c)),
              ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _category = v);
          },
        ),
        const SizedBox(height: 12),
        _fieldLabel(_isSw ? 'Lugha' : 'Language'),
        DropdownButtonFormField<String>(
          initialValue: _language,
          decoration: _decoration(),
          items: const [
            DropdownMenuItem(value: 'en_US', child: Text('English (en_US)')),
            DropdownMenuItem(
                value: 'sw', child: Text('Swahili (sw)')),
            DropdownMenuItem(value: 'en', child: Text('English (en)')),
            DropdownMenuItem(value: 'fr', child: Text('French (fr)')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _language = v);
          },
        ),
      ],
    );
  }

  Widget _headerSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ChoiceChip(
              label: Text(_isSw ? 'Hakuna' : 'None'),
              selected: _headerType == WaTemplateHeaderType.none,
              onSelected: (_) =>
                  setState(() => _headerType = WaTemplateHeaderType.none),
              selectedColor: RentTheme.teal.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: _headerType == WaTemplateHeaderType.none
                    ? RentTheme.teal
                    : RentTheme.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(_isSw ? 'Maandishi' : 'Text'),
              selected: _headerType == WaTemplateHeaderType.text,
              onSelected: (_) =>
                  setState(() => _headerType = WaTemplateHeaderType.text),
              selectedColor: RentTheme.teal.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: _headerType == WaTemplateHeaderType.text
                    ? RentTheme.teal
                    : RentTheme.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (_headerType == WaTemplateHeaderType.text) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _headerCtrl,
            maxLength: 60,
            decoration: _decoration(
              hint: _isSw
                  ? 'Mf. Kumbuso la malipo'
                  : 'e.g. Payment reminder',
            ),
          ),
        ],
      ],
    );
  }

  Widget _bodySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _bodyCtrl,
          minLines: 4,
          maxLines: 8,
          maxLength: 1024,
          decoration: _decoration(
            hint: _isSw
                ? 'Habari {{1}}, salio lako la kodi ni TZS {{2}} linatarajiwa {{3}}. Asante.'
                : 'Hi {{1}}, your rent balance of TZS {{2}} is due on {{3}}. Thank you.',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            FilledButton.tonalIcon(
              icon: const Icon(Icons.data_object_rounded, size: 16),
              label: Text(
                _isSw
                    ? 'Ongeza {{${_sampleCtrls.length + 1}}}'
                    : 'Insert {{${_sampleCtrls.length + 1}}}',
              ),
              onPressed: _insertVariableToken,
              style: FilledButton.styleFrom(
                backgroundColor: RentTheme.teal.withValues(alpha: 0.12),
                foregroundColor: RentTheme.teal,
              ),
            ),
          ],
        ),
        if (_sampleCtrls.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            _isSw ? 'Mifano ya vigezo' : 'Sample values',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: RentTheme.muted,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _sampleCtrls.length; i++) ...[
            TextFormField(
              controller: _sampleCtrls[i],
              decoration: _decoration(
                hint: _isSw
                    ? 'Mfano wa {{${i + 1}}}'
                    : 'Sample for {{${i + 1}}}',
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '{{${i + 1}}}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: RentTheme.teal,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }

  Widget _footerSection(BuildContext context) {
    return TextFormField(
      controller: _footerCtrl,
      maxLength: 60,
      decoration: _decoration(
        hint: _isSw
            ? 'Mf. Piga simu kwa msaada'
            : 'e.g. Call us for help',
      ),
    );
  }

  Widget _buttonsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_buttons.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _isSw
                  ? 'Ongeza hadi vitufe 3 (quick reply / URL / simu).'
                  : 'Add up to 3 buttons (quick reply / URL / phone).',
              style: const TextStyle(fontSize: 12, color: RentTheme.muted),
            ),
          ),
        for (var i = 0; i < _buttons.length; i++) ...[
          _buttonRow(i),
          const SizedBox(height: 8),
        ],
        if (_buttons.length < 3)
          OutlinedButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            onPressed: _addButton,
            label: Text(_isSw ? 'Ongeza kitufe' : 'Add button'),
            style: OutlinedButton.styleFrom(
              foregroundColor: RentTheme.teal,
              side: const BorderSide(color: RentTheme.teal),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
      ],
    );
  }

  Widget _buttonRow(int index) {
    final b = _buttons[index];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: RentTheme.teal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: b.type,
                  decoration: _decoration(dense: true),
                  items: const [
                    DropdownMenuItem(
                        value: 'quick_reply', child: Text('Quick reply')),
                    DropdownMenuItem(value: 'url', child: Text('URL')),
                    DropdownMenuItem(
                        value: 'phone_number', child: Text('Phone number')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _buttons[index] = WaTemplateButton(
                            type: v,
                            label: b.label,
                            url: b.url,
                            phoneNumber: b.phoneNumber,
                          ));
                    }
                  },
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => _buttons.removeAt(index));
                },
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: b.label,
            maxLength: 25,
            decoration: _decoration(
              hint: _isSw ? 'Andika kwenye kitufe' : 'Button label',
              dense: true,
            ),
            onChanged: (v) => _buttons[index] = WaTemplateButton(
              type: b.type,
              label: v,
              url: _buttons[index].url,
              phoneNumber: _buttons[index].phoneNumber,
            ),
          ),
          if (b.type == 'url') ...[
            const SizedBox(height: 6),
            TextFormField(
              initialValue: b.url,
              decoration: _decoration(
                hint: 'https://example.com/bill',
                dense: true,
                prefixIcon: const Icon(Icons.link_rounded, size: 18),
              ),
              onChanged: (v) => _buttons[index] = WaTemplateButton(
                type: b.type,
                label: _buttons[index].label,
                url: v,
                phoneNumber: _buttons[index].phoneNumber,
              ),
            ),
          ],
          if (b.type == 'phone_number') ...[
            const SizedBox(height: 6),
            TextFormField(
              initialValue: b.phoneNumber,
              keyboardType: TextInputType.phone,
              decoration: _decoration(
                hint: '+255...',
                dense: true,
                prefixIcon: const Icon(Icons.phone_rounded, size: 18),
              ),
              onChanged: (v) => _buttons[index] = WaTemplateButton(
                type: b.type,
                label: _buttons[index].label,
                url: _buttons[index].url,
                phoneNumber: v,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _addButton() {
    setState(() {
      _buttons.add(const WaTemplateButton(
        type: 'quick_reply',
        label: 'Reply',
      ));
    });
  }

  Widget _previewCard(BuildContext context) {
    final samples = _currentSamples();
    final body = RentWhatsappTemplateBuilderController.renderPreview(
      _bodyCtrl.text.isEmpty
          ? (_isSw
              ? '(Mwili wa ujumbe utaonekana hapa)'
              : '(Your message body will appear here)')
          : _bodyCtrl.text,
      samples,
    );
    final header = _headerType == WaTemplateHeaderType.text &&
            _headerCtrl.text.trim().isNotEmpty
        ? _headerCtrl.text
        : null;
    final footer =
        _footerCtrl.text.trim().isEmpty ? null : _footerCtrl.text;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1EE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.phone_iphone_rounded,
                  size: 16, color: RentTheme.conciergeTeal),
              const SizedBox(width: 6),
              Text(
                _isSw ? 'MUHTASARI WA WHATSAPP' : 'WHATSAPP PREVIEW',
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: RentTheme.conciergeTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD5E3DE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (header != null) ...[
                  Text(
                    header,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1F2937),
                    height: 1.4,
                  ),
                ),
                if (footer != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    footer,
                    style: const TextStyle(
                      fontSize: 11,
                      color: RentTheme.muted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (_buttons.isNotEmpty) ...[
                  const Divider(height: 18),
                  for (final b in _buttons)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Center(
                        child: Text(
                          b.label.isEmpty ? '—' : b.label,
                          style: const TextStyle(
                            color: RentTheme.conciergeTeal,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: isDark ? context.tokens.scaffoldBackground : Colors.white,
          border: Border(
            top: BorderSide(
              color:
                  isDark ? context.tokens.elevatedSurface : RentTheme.border,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saving ? null : _saveDraft,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: Text(_isSw ? 'HIFADHI RASIMU' : 'SAVE DRAFT'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: RentTheme.teal,
                  side: const BorderSide(color: RentTheme.teal),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label:
                    Text(_isSw ? 'TUMA' : 'SUBMIT'),
                style: FilledButton.styleFrom(
                  backgroundColor: RentTheme.conciergeTeal,
                  foregroundColor: Colors.white,
                  // padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w800,
            color: RentTheme.muted,
          ),
        ),
      );

  InputDecoration _decoration(
      {String? hint, Widget? prefixIcon, bool dense = false}) {
    const radius = BorderRadius.all(Radius.circular(10));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark
            ? Colors.white.withValues(alpha: 0.36)
            : RentTheme.muted.withValues(alpha: 0.58),
      ),
      prefixIcon: prefixIcon,
      prefixIconConstraints:
          const BoxConstraints(minWidth: 36, minHeight: 36),
      isDense: dense,
      filled: true,
      fillColor:
          isDark
              ? context.tokens.scaffoldBackground
              : Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      counterText: '',
      border: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: RentTheme.border),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: RentTheme.border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: RentTheme.teal, width: 1.5),
      ),
    );
  }
}
