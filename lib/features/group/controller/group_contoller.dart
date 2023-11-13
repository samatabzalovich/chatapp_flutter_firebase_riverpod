// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whatsapp_ui/features/group/repository/group_repository.dart';

final groupContollerProvider = Provider((ref) {
  final groupRepository = ref.watch(groupRepositoryProvider);
  return GroupContoller(groupRepository: groupRepository, ref: ref);
});

class GroupContoller {
  final GroupRepository groupRepository;
  final ProviderRef ref;
  GroupContoller({
    required this.groupRepository,
    required this.ref,
  });

  void createGroup(BuildContext context, String name, File profilePic,
      List<Contact> selectedContact) {
    groupRepository.createGroup(context, name, profilePic, selectedContact);
  }
}
