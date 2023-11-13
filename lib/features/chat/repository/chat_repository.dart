import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapp_ui/common/enums/message_enums.dart';
import 'package:whatsapp_ui/common/providers/message_reply_provider.dart';
import 'package:whatsapp_ui/common/repositories/common_firebase_storage_repository.dart';
import 'package:whatsapp_ui/common/utils/utils.dart';
import 'package:whatsapp_ui/info.dart';
import 'package:whatsapp_ui/models/chat_contact.dart';
import 'package:whatsapp_ui/models/group.dart';
import 'package:whatsapp_ui/models/message.dart';
import 'package:whatsapp_ui/models/user_model.dart';

final chatRepositoryProvider = Provider(
  (ref) => ChatRepository(
      firebaseFirestore: FirebaseFirestore.instance,
      firebaseAuth: FirebaseAuth.instance),
);

class ChatRepository {
  final FirebaseFirestore firebaseFirestore;
  final FirebaseAuth firebaseAuth;

  ChatRepository({required this.firebaseFirestore, required this.firebaseAuth});

  Stream<List<Group>> getChatGroups() {
    return firebaseFirestore.collection('groups').snapshots().map((event) {
      List<Group> groups = [];
      for (var document in event.docs) {
        var group = Group.fromMap(document.data());
        if (group.membersUid.contains(firebaseAuth.currentUser!.uid)) {
          groups.add(group);
        }
      }
      return groups;
    });
  }

  Stream<List<Message>> getChatStream(String recieverUserId) {
    return firebaseFirestore
        .collection('users')
        .doc(firebaseAuth.currentUser!.uid)
        .collection('chats')
        .doc(recieverUserId)
        .collection('messages')
        .orderBy('timeSent')
        .snapshots()
        .map((event) {
      List<Message> messages = [];
      for (var document in event.docs) {
        messages.add(Message.fromMap(document.data()));
      }
      return messages;
    });
  }

  Stream<List<Message>> getGroupChatStream(String groupId) {
    return firebaseFirestore
        .collection('groups')
        .doc(groupId)
        .collection('chats')
        .orderBy('timeSent')
        .snapshots()
        .map((event) {
      List<Message> messages = [];
      for (var document in event.docs) {
        messages.add(Message.fromMap(document.data()));
      }
      return messages;
    });
  }

  Stream<List<ChatContact>> getContacts() {
    return firebaseFirestore
        .collection('users')
        .doc(firebaseAuth.currentUser!.uid)
        .collection('chats')
        .snapshots()
        .asyncMap((event) async {
      List<ChatContact> contacts = [];
      for (var document in event.docs) {
        var chatContact = ChatContact.fromMap(document.data());
        var userData = await firebaseFirestore
            .collection('users')
            .doc(chatContact.contactId)
            .get();

        var user = UserModel.fromMap(userData.data()!);
        contacts.add(ChatContact(
            name: user.name,
            profileAvatar: user.profileAvatar,
            contactId: chatContact.contactId,
            timeSent: chatContact.timeSent,
            lastMessage: chatContact.lastMessage));
      }
      return contacts;
    });
  }

  void _saveDataToContactSubCollection(
      UserModel senderUserData,
      UserModel? recieverUserData,
      String text,
      DateTime timeSent,
      String recieverUserId,
      bool isGroupChat) async {
    if (isGroupChat) {
      await firebaseFirestore.collection('groups').doc(recieverUserId).update({
        'lastMessage': text,
        'timeSent': DateTime.now().microsecondsSinceEpoch
      });
    } else {
      var recieverChatContact = ChatContact(
          name: senderUserData.name,
          profileAvatar: senderUserData.profileAvatar,
          contactId: senderUserData.uid,
          timeSent: timeSent,
          lastMessage: text);
      await firebaseFirestore
          .collection('users')
          .doc(recieverUserId)
          .collection('chats')
          .doc(firebaseAuth.currentUser!.uid)
          .set(recieverChatContact.toMap());

      var senderChatContact = ChatContact(
          name: recieverUserData!.name,
          profileAvatar: recieverUserData.profileAvatar,
          contactId: recieverUserData.uid,
          timeSent: timeSent,
          lastMessage: text);
      await firebaseFirestore
          .collection('users')
          .doc(firebaseAuth.currentUser!.uid)
          .collection('chats')
          .doc(recieverUserId)
          .set(senderChatContact.toMap());
    }
  }

  _saveMessageToMessageSubCollection({
    required String recieverUserId,
    required String text,
    required DateTime timeSent,
    required String messageId,
    required String userName,
    required String? recieverUserName,
    required MessageEnum messageType,
    required MessageReply? messageReply,
    required String senderUserName,
    required MessageEnum repliedMessageType,
    required bool isGroupChat,
  }) async {
    final message = Message(
      senderId: firebaseAuth.currentUser!.uid,
      recieverid: recieverUserId,
      text: text,
      type: messageType,
      timeSent: timeSent,
      messageId: messageId,
      isSeen: false,
      repliedMessage: messageReply == null ? '' : messageReply.message,
      repliedTo: messageReply == null
          ? ''
          : messageReply.isMe
              ? senderUserName
              : recieverUserName ?? '',
      repliedMessageType: repliedMessageType,
    );

    if (isGroupChat) {
      await firebaseFirestore
          .collection('groups')
          .doc(recieverUserId)
          .collection('chats')
          .doc(messageId)
          .set(message.toMap());
    } else {
      await firebaseFirestore
          .collection('users')
          .doc(firebaseAuth.currentUser!.uid)
          .collection('chats')
          .doc(recieverUserId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      await firebaseFirestore
          .collection('users')
          .doc(recieverUserId)
          .collection('chats')
          .doc(firebaseAuth.currentUser!.uid)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());
    }
  }

  void sendTextMessage({
    required BuildContext context,
    required String text,
    required String recieverUserId,
    required UserModel senderUser,
    required MessageReply? messageReply,
    required bool isGroupChat,
  }) async {
    try {
      var timeSend = DateTime.now();
      UserModel? recieverUserData;

      if (!isGroupChat) {
        var userDataMap = await firebaseFirestore
            .collection('users')
            .doc(recieverUserId)
            .get();
        recieverUserData = UserModel.fromMap(userDataMap.data()!);
      }

      var messageId = const Uuid().v1();

      _saveDataToContactSubCollection(
        senderUser,
        recieverUserData,
        text,
        timeSend,
        recieverUserId,
        isGroupChat,
      );

      _saveMessageToMessageSubCollection(
          recieverUserId: recieverUserId,
          text: text,
          timeSent: timeSend,
          messageType: MessageEnum.text,
          messageId: messageId,
          recieverUserName: recieverUserData?.name,
          userName: senderUser.name,
          messageReply: messageReply,
          senderUserName: senderUser.name,
          repliedMessageType: messageReply == null
              ? MessageEnum.text
              : messageReply.messageEnum,
          isGroupChat: isGroupChat);
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  void sendFileMessage({
    required BuildContext context,
    required File file,
    required recieverUserId,
    required UserModel senderUserData,
    required ProviderRef ref,
    required MessageEnum messageEnum,
    required MessageReply? messageReply,
    required bool isGroupChat,
  }) async {
    try {
      var timeSent = DateTime.now();
      var messageId = const Uuid().v1();

      String imageUrl = await ref
          .read(commonFirebaseStorageRepositoriesProvider)
          .storeFileToFirebase(
            'chat/${messageEnum.type}/${senderUserData.uid}/$recieverUserId/$messageId',
            file,
          );
      UserModel? recieverUserData;
      if (!isGroupChat) {
        var userDataMap = await firebaseFirestore
            .collection('users')
            .doc(recieverUserId)
            .get();
        recieverUserData = UserModel.fromMap(userDataMap.data()!);
      }

      String contactMessage;

      switch (messageEnum) {
        case MessageEnum.image:
          contactMessage = '📷 Photo';
          break;
        case MessageEnum.video:
          contactMessage = '📸 Video';
          break;
        case MessageEnum.audio:
          contactMessage = '🎵 Audio';
          break;
        case MessageEnum.gif:
          contactMessage = 'GIF';
          break;
        default:
          contactMessage = 'GIF';
      }

      _saveDataToContactSubCollection(senderUserData, recieverUserData,
          contactMessage, timeSent, recieverUserId, isGroupChat);
      _saveMessageToMessageSubCollection(
        recieverUserId: recieverUserId,
        text: imageUrl,
        timeSent: timeSent,
        messageId: messageId,
        userName: senderUserData.name,
        recieverUserName: recieverUserData?.name,
        isGroupChat: isGroupChat,
        messageType: messageEnum,
        messageReply: messageReply,
        senderUserName: senderUserData.name,
        repliedMessageType:
            messageReply == null ? MessageEnum.text : messageReply.messageEnum,
      );
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  void sendGIFMessage({
    required BuildContext context,
    required String gifUrl,
    required String recieverUserId,
    required UserModel senderUser,
    required MessageReply? messageReply,
    required bool isGroupChat,
  }) async {
    try {
      var timeSend = DateTime.now();
      UserModel? recieverUserData;
      if (!isGroupChat) {
        var userDataMap = await firebaseFirestore
            .collection('users')
            .doc(recieverUserId)
            .get();
        recieverUserData = UserModel.fromMap(userDataMap.data()!);
      }

      var messageId = const Uuid().v1();

      _saveDataToContactSubCollection(senderUser, recieverUserData, 'GIF',
          timeSend, recieverUserId, isGroupChat);

      _saveMessageToMessageSubCollection(
        recieverUserId: recieverUserId,
        text: gifUrl,
        timeSent: timeSend,
        messageType: MessageEnum.gif,
        messageId: messageId,
        recieverUserName: recieverUserData?.name,
        isGroupChat: isGroupChat,
        userName: senderUser.name,
        messageReply: messageReply,
        senderUserName: senderUser.name,
        repliedMessageType:
            messageReply == null ? MessageEnum.text : messageReply.messageEnum,
      );
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  void setChatMessageSeen(
    BuildContext context,
    String recieverUserId,
    String messageId,
  ) async {
    try {
      await firebaseFirestore
          .collection('users')
          .doc(firebaseAuth.currentUser!.uid)
          .collection('chats')
          .doc(recieverUserId)
          .collection('messages')
          .doc(messageId)
          .update({'isSeen': true});

      await firebaseFirestore
          .collection('users')
          .doc(recieverUserId)
          .collection('chats')
          .doc(firebaseAuth.currentUser!.uid)
          .collection('messages')
          .doc(messageId)
          .update({'isSeen': true});
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }
}
