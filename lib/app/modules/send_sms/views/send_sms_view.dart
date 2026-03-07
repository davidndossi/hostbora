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

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(appBarTitleText: 'Send SMS/Whatsapp');
  }

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      if (controller.isCheckingAccess.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!controller.isAccessAllowed.value) {
        return const Center(child: Text('Access denied'));
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
                    inactiveBgColor: Colors.grey,
                    inactiveFgColor: Colors.grey[900],
                    totalSwitches: 2,
                    labels: const ['SMS', 'Whatsapp'],
                    onToggle: (index) {
                      controller.isFirstView.toggle();
                    },
                  ),
                ),
                const SizedBox(height: AppValues.spacing_20),
                Obx(() => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: controller.isFirstView.value
                      ? Column(
                    children: [
                      TextFormField(
                        controller: controller.phoneNumbersController,
                        keyboardType: TextInputType.multiline,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Phone numbers',
                          hintText: 'One per line or comma separated\ne.g. 0612345678, 0712345678',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                          alignLabelWithHint: true,
                        ),
                        validator: controller.phoneNumbersValidator,
                      ),
                      const SizedBox(height: AppValues.spacing_20),
                      TextFormField(
                        controller: controller.messageController,
                        keyboardType: TextInputType.multiline,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          hintText: 'Enter your message...',
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
                            onPressed: controller.isLoading.value ? null : controller.sendSms,
                            child: controller.isLoading.value
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 1.5,
                              ),
                            )
                                : const Text(
                              'Send SMS',
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
                        labelColor: Colors.black87,
                        unselectedLabelColor: Colors.grey,
                        tabs: [Tab(text: 'Chat'), Tab(text: 'Group')],
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
                                  controller: controller.phoneNumbersController,
                                  keyboardType: TextInputType.multiline,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone numbers',
                                    hintText: 'One per line or comma separated\ne.g. 0612345678, 0712345678',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.phone),
                                    alignLabelWithHint: true,
                                  ),
                                  validator: controller.phoneNumbersValidator,
                                ),
                                const SizedBox(height: AppValues.spacing_20),
                                const Text(
                                  'Generate multimedia message (AI)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: AppValues.spacing_10),
                                TextFormField(
                                  controller: controller.promptController,
                                  keyboardType: TextInputType.multiline,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Prompt',
                                    hintText: 'Describe the message (e.g. announcement with image, voice note, document)...',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.auto_awesome),
                                    alignLabelWithHint: true,
                                  ),
                                ),
                                const SizedBox(height: AppValues.spacing_10),
                                const Text(
                                  'Include media:',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 6),
                                Obx(() => Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    FilterChip(
                                      label: const Text('Image'),
                                      selected: controller.includeImage.value,
                                      onSelected: (v) => controller.includeImage(v),
                                    ),
                                    FilterChip(
                                      label: const Text('Audio'),
                                      selected: controller.includeAudio.value,
                                      onSelected: (v) => controller.includeAudio(v),
                                    ),
                                    FilterChip(
                                      label: const Text('File'),
                                      selected: controller.includeFile.value,
                                      onSelected: (v) => controller.includeFile(v),
                                    ),
                                  ],
                                )),
                                const SizedBox(height: AppValues.spacing_10),
                                Obx(() => OutlinedButton.icon(
                                  onPressed: controller.isGenerating.value
                                      ? null
                                      : controller.generateMultimediaMessage,
                                  icon: controller.isGenerating.value
                                      ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                      : const Icon(Icons.auto_awesome, size: 20),
                                  label: Text(
                                    controller.isGenerating.value ? 'Generating...' : 'Generate message',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(44),
                                  ),
                                )),
                                const SizedBox(height: AppValues.spacing_10),
                                ElevatedButton.icon(
                                  onPressed: controller.isLoading.value ? null : controller.sendViaWhatsApp,
                                  icon: SvgPicture.asset(
                                      'images/ic_whatsapp.svg',
                                      colorFilter: const ColorFilter.mode(
                                        Colors.white,
                                        BlendMode.srcIn,
                                      ),
                                      height: 24
                                  ),
                                  label: const Text(
                                    'Send via WhatsApp',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text(
                                  'WhatsApp group',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: AppValues.spacing_10),
                                TextFormField(
                                  controller: controller.groupLinkController,
                                  keyboardType: TextInputType.url,
                                  decoration: InputDecoration(
                                    labelText: 'Group invite link',
                                    hintText: 'https://chat.whatsapp.com/... or paste invite code',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.group),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.save_outlined),
                                      onPressed: controller.saveCurrentGroupLink,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppValues.spacing_10),
                                const Text(
                                  'Saved groups',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Obx(() {
                                  if (controller.savedGroups.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(
                                        'No saved groups. Paste a link and tap "Save link for future".',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
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
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          leading: const Icon(Icons.link),
                                          title: Text(g.name),
                                          subtitle: Text(
                                            g.link.length > 40 ? '${g.link.substring(0, 40)}...' : g.link,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextButton(
                                                onPressed: () => controller.useSavedGroup(g),
                                                child: const Text('Use'),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                                onPressed: () => controller.removeSavedGroupAt(i),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                }),
                                const SizedBox(height: AppValues.spacing_10),
                                const Text(
                                  'Generate multimedia message (AI)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: AppValues.spacing_10),
                                TextFormField(
                                  controller: controller.promptController,
                                  keyboardType: TextInputType.multiline,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Prompt',
                                    hintText: 'Describe the message (e.g. announcement with image, voice note, document)...',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.auto_awesome),
                                    alignLabelWithHint: true,
                                  ),
                                ),
                                const SizedBox(height: AppValues.spacing_10),
                                const Text(
                                  'Include media:',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 6),
                                Obx(() => Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    FilterChip(
                                      label: const Text('Image'),
                                      selected: controller.includeImage.value,
                                      onSelected: (v) => controller.includeImage(v),
                                    ),
                                    FilterChip(
                                      label: const Text('Audio'),
                                      selected: controller.includeAudio.value,
                                      onSelected: (v) => controller.includeAudio(v),
                                    ),
                                    FilterChip(
                                      label: const Text('File'),
                                      selected: controller.includeFile.value,
                                      onSelected: (v) => controller.includeFile(v),
                                    ),
                                  ],
                                )),
                                const SizedBox(height: AppValues.spacing_10),
                                Obx(() => OutlinedButton.icon(
                                  onPressed: controller.isGenerating.value
                                      ? null
                                      : controller.generateMultimediaMessage,
                                  icon: controller.isGenerating.value
                                      ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                      : const Icon(Icons.auto_awesome, size: 20),
                                  label: Text(
                                    controller.isGenerating.value ? 'Generating...' : 'Generate message',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(44),
                                  ),
                                )),
                                const SizedBox(height: AppValues.spacing_10),
                                ElevatedButton.icon(
                                  onPressed: controller.isLoading.value ? null : controller.sendToWhatsAppGroup,
                                  icon: const Icon(Icons.group_add, size: 20),
                                  label: const Text(
                                    'Open group & copy message',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                ),
                              ],
                            )
                          ]
                        )
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        )
      );
    });
  }
}
