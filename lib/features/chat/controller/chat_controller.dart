import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/common/enums/message_enums.dart';
import 'package:whatsapp_ui/common/providers/message_reply_provider.dart';
import 'package:whatsapp_ui/features/auth/controller/auth_controller.dart';
import 'package:whatsapp_ui/features/chat/repository/chat_repository.dart';
import 'package:whatsapp_ui/models/chat_contact.dart';

import '../../../models/group.dart';
import '../../../models/message.dart';

final chatControllerProvider = Provider((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return ChatController(chatRepository: chatRepository, ref: ref);
});

class ChatController {
  final ChatRepository chatRepository;
  final ProviderRef ref;

  ChatController({required this.chatRepository, required this.ref});

  Stream<List<Message>> chatStream(String recieverUserId) {
    return chatRepository.getChatStream(recieverUserId);
  }

  Stream<List<Message>> groupChatStream(String groupId) {
    return chatRepository.getGroupChatStream(groupId);
  }

  Stream<List<ChatContact>> chatContacts() {
    return chatRepository.getContacts();
  }

  Stream<List<Group>> chatGroups() {
    return chatRepository.getChatGroups();
  }

  void sendTextMessage(BuildContext context, String text, String recieverUserId,
      bool isGroupChat) {
    final messageReply = ref.read(messageReplyProvider);

    ref.read(userDataAuthProvider).whenData((value) {
      return chatRepository.sendTextMessage(
          context: context,
          text: text,
          recieverUserId: recieverUserId,
          senderUser: value!,
          messageReply: messageReply,
          isGroupChat: isGroupChat);
    });
    ref.read(messageReplyProvider.notifier).update((state) => null);
  }

  void sendGIFMessage(BuildContext context, String gifUrl,
      String recieverUserId, bool isGroupChat) {
    // int gifUrlIndexPart = gifUrl.lastIndexOf('-') + 1;
    // String gifUrlPart = gifUrl.substring(gifUrlIndexPart);

    // String newGifUrl = 'https://i.giphy.com/media/$gifUrlPart/200.gif';

    // final messageReply = ref.read(messageReplyProvider);

    // ref.read(userDataAuthProvider).whenData((value) {
    //   return chatRepository.sendGIFMessage(
    //       context: context,
    //       gifUrl: newGifUrl,
    //       recieverUserId: recieverUserId,
    //       senderUser: value!,
    //        messageReply: messageReply,
    //        isGroupChat: isGroupChat,
    // );
    // }
    // );
    // ref.read(messageReplyProvider.notifier).update((state) => null);
  }

  void sendFileMessage(BuildContext context, File file, String recieverUserId,
      MessageEnum messageEnum, bool isGroupChat) {
    final messageReply = ref.read(messageReplyProvider);
    ref.read(userDataAuthProvider).whenData((value) {
      return chatRepository.sendFileMessage(
          context: context,
          file: file,
          recieverUserId: recieverUserId,
          senderUserData: value!,
          ref: ref,
          messageEnum: messageEnum,
          messageReply: messageReply,
          isGroupChat: isGroupChat);
    });
    ref.read(messageReplyProvider.notifier).update((state) => null);
  }

  void setChatMessageSeen(
    BuildContext context,
    String recieverUserId,
    String messageId,
  ) {
    chatRepository.setChatMessageSeen(context, recieverUserId, messageId);
  }
}
