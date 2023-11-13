// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ChatContact {
  final String name;
  final String profileAvatar;
  final String contactId;
  final DateTime timeSent;
  final String lastMessage;

  ChatContact(
      {required this.name,
      required this.profileAvatar,
      required this.contactId,
      required this.timeSent,
      required this.lastMessage});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'profileAvatar': profileAvatar,
      'contactId': contactId,
      'timeSent': timeSent.millisecondsSinceEpoch,
      'lastMessage': lastMessage,
    };
  }

  factory ChatContact.fromMap(Map<String, dynamic> map) {
    return ChatContact(
      name: map['name'] ?? '',
      profileAvatar: map['profileAvatar'] ?? '',
      contactId: map['contactId'] ?? '',
      timeSent: DateTime.fromMillisecondsSinceEpoch(map['timeSent']),
      lastMessage: map['lastMessage'] ?? '',
    );
  }
}
