import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/send_sms_controller.dart';

class SendSmsView extends BaseView<SendSmsController> {
  SendSmsView({super.key});

  String _t(BuildContext context, String en, String sw) {
    return Localizations.localeOf(context).languageCode == 'sw' ? sw : en;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: _t(context, 'Send SMS/Whatsapp', 'Tuma SMS/WhatsApp'),
    );
  }

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      if (controller.isCheckingAccess.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!controller.isAccessAllowed.value) {
        return Center(
          child: Text(
            _t(context, 'Access denied', 'Ufikiaji umekataliwa'),
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        );
      }
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Form(
            key: controller.formKey,
            child: Column(
              // crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 200,
                  child: ToggleSwitch(
                    fontSize: 16.0,
                    minWidth: 100,
                    initialLabelIndex: 0,
                    activeBgColor: const [AppColors.colorPrimary],
                    activeFgColor: Colors.white,
                    inactiveBgColor: isDark
                        ? theme.colorScheme.surfaceContainerHighest
                        : Colors.grey.shade300,
                    inactiveFgColor: isDark
                        ? theme.colorScheme.onSurfaceVariant
                        : Colors.grey.shade900,
                    totalSwitches: 2,
                    labels: ['SMS', 'WhatsApp'],
                    onToggle: (index) {
                      controller.isFirstView.toggle();
                    },
                  ),
                ),
                const SizedBox(height: AppValues.spacing_20),
                Obx(
                  () => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                    child: controller.isFirstView.value
                        ? Column(
                            children: [
                              TextFormField(
                                controller: controller.phoneNumbersController,
                                keyboardType: TextInputType.multiline,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  labelText: _t(
                                    context,
                                    'Phone numbers',
                                    'Namba za simu',
                                  ),
                                  hintText: _t(
                                    context,
                                    'One per line or comma separated\ne.g. 0612345678, 0712345678',
                                    'Moja kwa kila mstari au tumia koma\nmf. 0612345678, 0712345678',
                                  ),
                                  border: OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.phone),
                                  alignLabelWithHint: true,
                                ),
                                validator: controller.phoneNumbersValidator,
                              ),
                              const SizedBox(height: AppValues.spacing_20),
                              TextFormField(
                                controller: controller.messageController,
                                keyboardType: TextInputType.multiline,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  labelText: _t(context, 'Message', 'Ujumbe'),
                                  hintText: _t(
                                    context,
                                    'Enter your message...',
                                    'Weka ujumbe wako...',
                                  ),
                                  border: OutlineInputBorder(),
                                  alignLabelWithHint: true,
                                ),
                                validator: controller.messageValidator,
                              ),
                              const SizedBox(height: AppValues.spacing_20),
                              Obx(
                                () => SizedBox(
                                  width: AppValues.formButtonWidth,
                                  height: AppValues.formButtonHeight,
                                  child: ElevatedButton(
                                    onPressed: controller.isLoading.value
                                        ? null
                                        : controller.sendSms,
                                    child: controller.isLoading.value
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 1.5,
                                            ),
                                          )
                                        : Text(
                                            _t(context, 'Send SMS', 'Tuma SMS'),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              TabBar(
                                controller: controller.tabController,
                                isScrollable: true,
                                labelColor: isDark
                                    ? theme.colorScheme.onSurface
                                    : Colors.black87,
                                unselectedLabelColor: isDark
                                    ? theme.colorScheme.onSurfaceVariant
                                    : Colors.grey,
                                tabs: [
                                  Tab(text: _t(context, 'Chat', 'Mazungumzo')),
                                  Tab(text: _t(context, 'Group', 'Kikundi')),
                                ],
                              ),
                              const SizedBox(height: AppValues.spacing_20),
                              SizedBox(
                                height: 500,
                                child: TabBarView(
                                  controller: controller.tabController,
                                  children: [
                                    Column(
                                      children: [
                                        TextFormField(
                                          controller:
                                              controller.phoneNumbersController,
                                          keyboardType: TextInputType.multiline,
                                          maxLines: 4,
                                          decoration: InputDecoration(
                                            labelText: _t(
                                              context,
                                              'Phone numbers',
                                              'Namba za simu',
                                            ),
                                            hintText: _t(
                                              context,
                                              'One per line or comma separated\ne.g. 0612345678, 0712345678',
                                              'Moja kwa kila mstari au tumia koma\nmf. 0612345678, 0712345678',
                                            ),
                                            border: OutlineInputBorder(),
                                            prefixIcon: const Icon(Icons.phone),
                                            alignLabelWithHint: true,
                                          ),
                                          validator:
                                              controller.phoneNumbersValidator,
                                        ),
                                        const SizedBox(
                                          height: AppValues.spacing_20,
                                        ),
                                        Text(
                                          _t(
                                            context,
                                            'Generate multimedia message (AI)',
                                            'Tengeneza ujumbe wa media (AI)',
                                          ),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        TextFormField(
                                          controller:
                                              controller.promptController,
                                          keyboardType: TextInputType.multiline,
                                          maxLines: 3,
                                          decoration: InputDecoration(
                                            labelText: _t(
                                              context,
                                              'Prompt',
                                              'Maelekezo',
                                            ),
                                            hintText: _t(
                                              context,
                                              'Describe the message (e.g. announcement with image, voice note, document)...',
                                              'Eleza ujumbe (mf. tangazo lenye picha, sauti, au faili)...',
                                            ),
                                            border: OutlineInputBorder(),
                                            prefixIcon: const Icon(
                                              Icons.auto_awesome,
                                            ),
                                            alignLabelWithHint: true,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        Text(
                                          _t(
                                            context,
                                            'Include media:',
                                            'Jumuisha media:',
                                          ),
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 6),
                                        Obx(
                                          () => Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: [
                                              FilterChip(
                                                label: Text(
                                                  _t(context, 'Image', 'Picha'),
                                                ),
                                                selected: controller
                                                    .includeImage
                                                    .value,
                                                onSelected: (v) =>
                                                    controller.includeImage(v),
                                              ),
                                              FilterChip(
                                                label: Text(
                                                  _t(context, 'Audio', 'Sauti'),
                                                ),
                                                selected: controller
                                                    .includeAudio
                                                    .value,
                                                onSelected: (v) =>
                                                    controller.includeAudio(v),
                                              ),
                                              FilterChip(
                                                label: Text(
                                                  _t(context, 'File', 'Faili'),
                                                ),
                                                selected: controller
                                                    .includeFile
                                                    .value,
                                                onSelected: (v) =>
                                                    controller.includeFile(v),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        Obx(
                                          () => OutlinedButton.icon(
                                            onPressed:
                                                controller.isGenerating.value
                                                ? null
                                                : controller
                                                      .generateMultimediaMessage,
                                            icon: controller.isGenerating.value
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.auto_awesome,
                                                    size: 20,
                                                  ),
                                            label: Text(
                                              controller.isGenerating.value
                                                  ? _t(
                                                      context,
                                                      'Generating...',
                                                      'Inatengeneza...',
                                                    )
                                                  : _t(
                                                      context,
                                                      'Generate message',
                                                      'Tengeneza ujumbe',
                                                    ),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              minimumSize:
                                                  const Size.fromHeight(44),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: controller.isLoading.value
                                              ? null
                                              : controller.sendViaWhatsApp,
                                          icon: SvgPicture.asset(
                                            'images/ic_whatsapp.svg',
                                            colorFilter: const ColorFilter.mode(
                                              Colors.white,
                                              BlendMode.srcIn,
                                            ),
                                            height: 24,
                                          ),
                                          label: Text(
                                            _t(
                                              context,
                                              'Send via WhatsApp',
                                              'Tuma kwa WhatsApp',
                                            ),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: const Size.fromHeight(
                                              48,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          _t(
                                            context,
                                            'WhatsApp group',
                                            'Kikundi cha WhatsApp',
                                          ),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        TextFormField(
                                          controller:
                                              controller.groupLinkController,
                                          keyboardType: TextInputType.url,
                                          decoration: InputDecoration(
                                            labelText: _t(
                                              context,
                                              'Group invite link',
                                              'Kiungo cha mwaliko wa kikundi',
                                            ),
                                            hintText: _t(
                                              context,
                                              'https://chat.whatsapp.com/... or paste invite code',
                                              'https://chat.whatsapp.com/... au bandika msimbo wa mwaliko',
                                            ),
                                            border: const OutlineInputBorder(),
                                            prefixIcon: const Icon(Icons.group),
                                            suffixIcon: IconButton(
                                              icon: const Icon(
                                                Icons.save_outlined,
                                              ),
                                              onPressed: controller
                                                  .saveCurrentGroupLink,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        Text(
                                          _t(
                                            context,
                                            'Saved groups',
                                            'Vikundi vilivyohifadhiwa',
                                          ),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Obx(() {
                                          if (controller.savedGroups.isEmpty) {
                                            return Padding(
                                              padding: EdgeInsets.only(top: 4),
                                              child: Text(
                                                _t(
                                                  context,
                                                  'No saved groups. Paste a link and tap "Save link for future".',
                                                  'Hakuna vikundi vilivyohifadhiwa. Bandika kiungo kisha gusa "Hifadhi kwa matumizi ya baadaye".',
                                                ),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            );
                                          }
                                          return Column(
                                            children: controller.savedGroups
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                                  final i = entry.key;
                                                  final g = entry.value;
                                                  return Card(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          bottom: 8,
                                                        ),
                                                    child: ListTile(
                                                      leading: const Icon(
                                                        Icons.link,
                                                      ),
                                                      title: Text(g.name),
                                                      subtitle: Text(
                                                        g.link.length > 40
                                                            ? '${g.link.substring(0, 40)}...'
                                                            : g.link,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      trailing: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                controller
                                                                    .useSavedGroup(
                                                                      g,
                                                                    ),
                                                            child: Text(
                                                              _t(
                                                                context,
                                                                'Use',
                                                                'Tumia',
                                                              ),
                                                            ),
                                                          ),
                                                          IconButton(
                                                            icon: Icon(
                                                              Icons
                                                                  .delete_outline,
                                                              color: theme
                                                                  .colorScheme
                                                                  .error,
                                                            ),
                                                            onPressed: () =>
                                                                controller
                                                                    .removeSavedGroupAt(
                                                                      i,
                                                                    ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                })
                                                .toList(),
                                          );
                                        }),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        Text(
                                          _t(
                                            context,
                                            'Generate multimedia message (AI)',
                                            'Tengeneza ujumbe wa media (AI)',
                                          ),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        TextFormField(
                                          controller:
                                              controller.promptController,
                                          keyboardType: TextInputType.multiline,
                                          maxLines: 3,
                                          decoration: InputDecoration(
                                            labelText: _t(
                                              context,
                                              'Prompt',
                                              'Maelekezo',
                                            ),
                                            hintText: _t(
                                              context,
                                              'Describe the message (e.g. announcement with image, voice note, document)...',
                                              'Eleza ujumbe (mf. tangazo lenye picha, sauti, au faili)...',
                                            ),
                                            border: OutlineInputBorder(),
                                            prefixIcon: const Icon(
                                              Icons.auto_awesome,
                                            ),
                                            alignLabelWithHint: true,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        Text(
                                          _t(
                                            context,
                                            'Include media:',
                                            'Jumuisha media:',
                                          ),
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 6),
                                        Obx(
                                          () => Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: [
                                              FilterChip(
                                                label: Text(
                                                  _t(context, 'Image', 'Picha'),
                                                ),
                                                selected: controller
                                                    .includeImage
                                                    .value,
                                                onSelected: (v) =>
                                                    controller.includeImage(v),
                                              ),
                                              FilterChip(
                                                label: Text(
                                                  _t(context, 'Audio', 'Sauti'),
                                                ),
                                                selected: controller
                                                    .includeAudio
                                                    .value,
                                                onSelected: (v) =>
                                                    controller.includeAudio(v),
                                              ),
                                              FilterChip(
                                                label: Text(
                                                  _t(context, 'File', 'Faili'),
                                                ),
                                                selected: controller
                                                    .includeFile
                                                    .value,
                                                onSelected: (v) =>
                                                    controller.includeFile(v),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        Obx(
                                          () => OutlinedButton.icon(
                                            onPressed:
                                                controller.isGenerating.value
                                                ? null
                                                : controller
                                                      .generateMultimediaMessage,
                                            icon: controller.isGenerating.value
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.auto_awesome,
                                                    size: 20,
                                                  ),
                                            label: Text(
                                              controller.isGenerating.value
                                                  ? _t(
                                                      context,
                                                      'Generating...',
                                                      'Inatengeneza...',
                                                    )
                                                  : _t(
                                                      context,
                                                      'Generate message',
                                                      'Tengeneza ujumbe',
                                                    ),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              minimumSize:
                                                  const Size.fromHeight(44),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: controller.isLoading.value
                                              ? null
                                              : controller.sendToWhatsAppGroup,
                                          icon: const Icon(
                                            Icons.group_add,
                                            size: 20,
                                          ),
                                          label: Text(
                                            _t(
                                              context,
                                              'Open group & copy message',
                                              'Fungua kikundi na nakili ujumbe',
                                            ),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: const Size.fromHeight(
                                              48,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
