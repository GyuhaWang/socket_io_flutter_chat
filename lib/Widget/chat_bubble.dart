import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socketchat/models/events.dart';

enum BubbleType { sendBubble, receiverBubble }

class TextBubble extends StatelessWidget {
  final Message message;
  final BubbleType type;
  final BorderRadiusGeometry? borderRadius;

  const TextBubble({
    Key? key,
    required this.message,
    required this.type,
    this.borderRadius,
  }) : super(key: key);

  Color get _messageColor {
    return type == BubbleType.sendBubble
        ? Colors.transparent
        : Colors.transparent;
  }

  ui.TextDirection get _messageDirection {
    return type == BubbleType.sendBubble
        ? ui.TextDirection.rtl
        : ui.TextDirection.ltr;
  }

  @override
  Widget build(BuildContext context) {
    final _size = MediaQuery.of(context).size;
    return Row(
      textDirection: _messageDirection,
      children: [
        InkWell(
          onLongPress: () {
            Clipboard.setData(
                ClipboardData(text: message.messageContent.trim()));
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text("Copied to Clipboard")));
          },
          child: Container(
            constraints:
                BoxConstraints(maxWidth: _size.width * 0.6, minWidth: 0),
            margin: EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(15),
              border: Border.all(color: Colors.black12),
              color: _messageColor,
            ),
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text(
                  textAlign: TextAlign.end,
                  message.messageContent.trim(),
                )),
          ),
        ),
      ],
    );
  }
}

class UserTypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          constraints:
              const BoxConstraints(maxWidth: 50, minWidth: 0, maxHeight: 40),
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.green,
          ),
          child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: CircularProgressIndicator(
                color: Colors.black,
              )),
        ),
      ],
    );
  }
}
