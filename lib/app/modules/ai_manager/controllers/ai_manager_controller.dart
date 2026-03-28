import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';

class AiChatMessage {
  final String text;
  final bool fromAssistant;
  final String role;
  final String time;

  const AiChatMessage({
    required this.text,
    required this.fromAssistant,
    required this.role,
    required this.time,
  });
}

class AiManagerController extends BaseController {
  final messages = <AiChatMessage>[
    const AiChatMessage(
      fromAssistant: true,
      role: 'AI Assistant',
      time: '09:41 AM',
      text:
          "Hello Julian! I've analyzed your recent guest messages for \"The Glass House\". Would you like me to draft a response to the inquiry about late check-in?",
    ),
    const AiChatMessage(
      fromAssistant: false,
      role: 'Host',
      time: '09:42 AM',
      text:
          "Yes, please. Can you also summarize the last few reviews for that property first? I want to make sure we're addressing any recent concerns.",
    ),
    const AiChatMessage(
      fromAssistant: true,
      role: 'AI Assistant',
      time: '09:43 AM',
      text:
          "Review Summary (Last 5):\n\nConsistent 5-star rating for cleanliness.\n\nGuests mentioned the smart lock can be tricky.\n\nHigh praise for the kitchen amenities.\n\nI'm ready to draft that late check-in reply now. Should I mention the updated smart lock instructions?",
    ),
  ].obs;

  final quickActions = const <String>[
    'Draft reply to guest',
    'Summarize reviews',
    'Check tone',
  ];

  final messageInput = ''.obs;
  final inputController = TextEditingController();
  final messageController = TextEditingController();

  void setInput(String value) => messageInput.value = value;

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }

  void send() {
    final text = inputController.text.trim();
    if (text.isEmpty) return;
    messages.add(
      AiChatMessage(
        text: text,
        fromAssistant: false,
        role: 'Host',
        time: 'Now',
      ),
    );
    messageInput.value = '';
    inputController.clear();
    messageController.clear();
  }

  void tapQuickAction(String action) {
    messageInput.value = action;
    inputController.text = action;
    inputController.selection = TextSelection.collapsed(offset: action.length);
    messageController.text = action;
    messageController.selection = TextSelection.collapsed(offset: action.length);
  }
}
