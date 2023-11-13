import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_ui/common/enums/message_enums.dart';
import 'package:whatsapp_ui/common/providers/message_reply_provider.dart';
import 'package:whatsapp_ui/common/widgets/loader.dart';
import 'package:whatsapp_ui/features/chat/controller/chat_controller.dart';
import 'package:whatsapp_ui/features/chat/widgets/sender_message_card.dart';
import 'package:whatsapp_ui/models/message.dart';

import '../../../info.dart';
import 'my_message_card.dart';

class ChatList extends ConsumerStatefulWidget {
  final String recieverUserId;
  final bool isGroupChat;
  const ChatList(
      {Key? key, required this.recieverUserId, required this.isGroupChat})
      : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ChatListState();
}

class _ChatListState extends ConsumerState<ChatList> {
  final ScrollController messageContoller = ScrollController();

  @override
  void dispose() {
    super.dispose();
    messageContoller.dispose();
  }

  void onMessageSwipe(
    String message,
    bool isMe,
    MessageEnum messageEnum,
  ) {
    ref
        .read(messageReplyProvider.notifier)
        .update((state) => MessageReply(message, isMe, messageEnum));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Message>>(
        stream: widget.isGroupChat
            ? ref
                .read(chatControllerProvider)
                .groupChatStream(widget.recieverUserId)
            : ref
                .read(chatControllerProvider)
                .chatStream(widget.recieverUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loader();
          }
          SchedulerBinding.instance.addPostFrameCallback((_) {
            messageContoller.jumpTo(messageContoller.position.maxScrollExtent);
          });
          return ListView.builder(
            controller: messageContoller,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final messageContent = snapshot.data![index];
              var timeSent = DateFormat.Hm().format(messageContent.timeSent);

              if (!messageContent.isSeen &&
                  messageContent.recieverid ==
                      FirebaseAuth.instance.currentUser!.uid) {
                ref.read(chatControllerProvider).setChatMessageSeen(
                    context, widget.recieverUserId, messageContent.messageId);
              }
              if (messageContent.senderId ==
                  FirebaseAuth.instance.currentUser!.uid) {
                return MyMessageCard(
                  message: messageContent.text,
                  date: timeSent,
                  type: messageContent.type,
                  repliesText: messageContent.repliedMessage,
                  userName: messageContent.repliedTo,
                  repliedMessageType: messageContent.repliedMessageType,
                  onLeftSwipe: (() => onMessageSwipe(
                      messageContent.text, true, messageContent.type)),
                  isSeen: messageContent.isSeen,
                );
              }
              return SenderMessageCard(
                message: messageContent.text,
                date: timeSent,
                type: messageContent.type,
                userName: messageContent.repliedTo,
                repliedMessageType: messageContent.repliedMessageType,
                repliesText: messageContent.repliedMessage,
                onRightSwipe: () => onMessageSwipe(
                    messageContent.text, false, messageContent.type),
              );
            },
          );
        });
  }
}
