import 'package:flutter/material.dart';

class Popup extends StatelessWidget {
  final Message message;
  final bool expand;
  final Tween<double> fadeInFadeOut;
  final VoidCallback onEnter;
  final VoidCallback onExit;
  final ValueSetter<BuildContext> dismiss;

  const Popup({
    Key? key,
    required this.message,
    required this.onEnter,
    required this.onExit,
    required this.dismiss,
    required this.fadeInFadeOut,
    this.expand = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: TweenAnimationBuilder<double>(
        tween: fadeInFadeOut,
        duration: const Duration(milliseconds: 200),
        builder: (context, value, child) =>
            Opacity(opacity: value, child: child!),
        child: Card(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 300, end: 0),
              duration: const Duration(seconds: 5),
              builder: (context, value, child) {
                final Widget headerWidget = ListTile(
                  subtitle: (expand || !message.expandable) &&
                      message.description?.isNotEmpty == true
                      ? Text(message.description!)
                      : null,
                  key: ValueKey('key_first${message.key}'),
                  horizontalTitleGap: 0,
                  leading: Icon(
                      message.icon ?? message.status.icon,
                      color:
                      message.color ?? message.status.color),
                  title:
                  Text(message.title ?? message.status.title),
                  trailing: IconButton(
                      onPressed: () => dismiss(context),
                      icon: const Icon(Icons.close_rounded)),
                );
                return MouseRegion(
                  onEnter: !message.expandable
                      ? null
                      : (_) => onEnter, //(_) => Obx(() => expand = true),
                  onExit: !message.expandable
                      ? null
                      : (_) => onExit, //(_) => Obx(() => expand = false),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!message.pinned)
                        Container(
                          color: message.color ??
                              message.status.color,
                          width: value,
                          height: 3,
                        ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: (!expand && message.expandable)
                            ? headerWidget
                            : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          key:
                          ValueKey('key_second${message.key}'),
                          children: [
                            headerWidget,
                            if (message.actionLabel != null ||
                                message.onActionPressed != null)
                              Row(
                                children: [
                                  const SizedBox(width: 50),
                                  Padding(
                                    padding:
                                    const EdgeInsets.only(bottom: 16),
                                    child: InkWell(
                                      borderRadius:
                                      BorderRadius.circular(3),
                                      onTap: () {
                                        if (message
                                            .onActionPressed !=
                                            null) {
                                          message.onActionPressed!();
                                        }
                                        dismiss(context);
                                      },
                                      child: Padding(
                                        padding:
                                        const EdgeInsets.all(2.0),
                                        child: Text(
                                          message.actionLabel ??
                                              'Action',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.apply(
                                              fontSizeDelta: 2,
                                              fontWeightDelta: 4,
                                              color: message
                                                  .onActionPressed == null
                                                  ? Theme.of(context)
                                                  .disabledColor
                                                  : message.color ??
                                                  message.status.color),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              }),
        ),
      ),
    );
  }
}

/// [status] is just for preferred color, text, icon, etc.
enum FlashStatus { error, tips, successful, warning, custom }

extension _FlashStatusExt on FlashStatus {
  String get title {
    switch (this) {
      case FlashStatus.error:
        return "Erorr";
      case FlashStatus.successful:
        return "Successful";
      case FlashStatus.tips:
        return "Tips";
      case FlashStatus.warning:
        return "Warning";
      case FlashStatus.custom:
        return "New Message";
    }
  }

  MaterialColor get color {
    switch (this) {
      case FlashStatus.tips:
        return Colors.blue;
      case FlashStatus.successful:
        return Colors.green;
      case FlashStatus.error:
        return Colors.red;
      case FlashStatus.warning:
        return Colors.amber;
      case FlashStatus.custom:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case FlashStatus.tips:
        return Icons.tips_and_updates_rounded;
      case FlashStatus.successful:
        return Icons.check_rounded;
      case FlashStatus.error:
        return Icons.clear;
      case FlashStatus.warning:
        return Icons.warning_rounded;
      case FlashStatus.custom:
        return Icons.circle;
    }
  }
}

class Message {
  /// [Message] contains all information that is needed to display a popup message.
  Message({
    this.title,
    this.expandable = true,
    this.description,
    required this.status,
    this.actionLabel,
    this.onActionPressed,
    this.pinned = false,
    this.key,
    this.color,
    this.icon,
    this.displayDuration = const Duration(seconds: 10)
  }) {
    key ??= UniqueKey();
  }

  late Key? key;

  /// [status] is just for preferred color, text, icon, etc.
  final FlashStatus status;
  final String? title;
  final String? description;

  final Color? color;
  final IconData? icon;

  /// [displayDuration] is the duration that the message will be displayed.
  final Duration displayDuration;
  final String? actionLabel;
  final void Function()? onActionPressed;

  /// When [expandable] is true, flash just show the title and when you hover on it more details are shown with animation.
  /// pinned messages are infinitely displayed.
  final bool pinned, expandable;
}