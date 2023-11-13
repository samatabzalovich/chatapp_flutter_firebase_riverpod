// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapp_ui/common/repositories/common_firebase_storage_repository.dart';
import 'package:whatsapp_ui/common/utils/utils.dart';

import '../../../models/status_model.dart';
import '../../../models/user_model.dart';

final statusRepositoryProvider = Provider((ref) => StatusRepository(
    firebaseFirestore: FirebaseFirestore.instance,
    firebaseAuth: FirebaseAuth.instance,
    ref: ref));

class StatusRepository {
  final FirebaseFirestore firebaseFirestore;
  final FirebaseAuth firebaseAuth;
  final ProviderRef ref;
  StatusRepository({
    required this.firebaseFirestore,
    required this.firebaseAuth,
    required this.ref,
  });

  void uploadStatus({
    required String username,
    required String profileAvatar,
    required String phoneNumber,
    required File statusImage,
    required BuildContext context,
  }) async {
    try {
      var statusId = const Uuid().v1();
      String uid = firebaseAuth.currentUser!.uid;

      String imageUrl = await ref
          .read(commonFirebaseStorageRepositoriesProvider)
          .storeFileToFirebase('/status/$statusId$uid', statusImage);

      List<Contact> contacts = [];
      if (await FlutterContacts.requestPermission()) {
        contacts = await FlutterContacts.getContacts(withProperties: true);
      }
      List<String> uidWhoCanSee = [];

      for (int i = 0; i < contacts.length; i++) {
        var userDataFirebase = await firebaseFirestore
            .collection('users')
            .where(
              'phoneNumber',
              isEqualTo: contacts[i].phones[0].number.replaceAll(
                    ' ',
                    '',
                  ),
            )
            .get();

        if (userDataFirebase.docs.isNotEmpty) {
          var userData = UserModel.fromMap(userDataFirebase.docs[0].data());
          uidWhoCanSee.add(userData.uid);
        }
      }
      bool isMyNumberHere = false;
      for (var element in uidWhoCanSee) {
        if (element == firebaseAuth.currentUser!.phoneNumber) {
          isMyNumberHere = true;
        }
      }
      if (isMyNumberHere == false) {
        uidWhoCanSee.add(firebaseAuth.currentUser!.uid);
      }

      List<String> statusImageUrls = [];
      var statusesSnapshot = await firebaseFirestore
          .collection('status')
          .where(
            'uid',
            isEqualTo: firebaseAuth.currentUser!.uid,
          )
          .get();

      if (statusesSnapshot.docs.isNotEmpty) {
        Status status = Status.fromMap(statusesSnapshot.docs[0].data());
        statusImageUrls = status.photoUrl;
        statusImageUrls.add(imageUrl);
        await firebaseFirestore
            .collection('status')
            .doc(statusesSnapshot.docs[0].id)
            .update({
          'photoUrl': statusImageUrls,
          'whoCanSee': uidWhoCanSee,
        });
        return;
      } else {
        statusImageUrls = [imageUrl];
      }
      Status status = Status(
        uid: uid,
        username: username,
        phoneNumber: phoneNumber,
        photoUrl: statusImageUrls,
        createdAt: DateTime.now(),
        profileAvatar: profileAvatar,
        statusId: statusId,
        whoCanSee: uidWhoCanSee,
      );
      await firebaseFirestore
          .collection('status')
          .doc(statusId)
          .set(status.toMap());
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  Future<List<Status>> getStatus(BuildContext context) async {
    List<Status> statusData = [];
    try {
      List<Contact> contacts = [];
      if (await FlutterContacts.requestPermission()) {
        contacts = await FlutterContacts.getContacts(withProperties: true);
      }

      for (int i = 0; i < contacts.length; i++) {
        var statusesSnapshot = await firebaseFirestore
            .collection('status')
            .where(
              'phoneNumber',
              isEqualTo: contacts[i].phones[0].number.replaceAll(
                    ' ',
                    '',
                  ),
            )
            .where(
              'createdAt',
              isGreaterThan: DateTime.now()
                  .subtract(const Duration(hours: 24))
                  .millisecondsSinceEpoch,
            )
            .get();
        for (var tempData in statusesSnapshot.docs) {
          Status tempStatus = Status.fromMap(tempData.data());
          if (tempStatus.whoCanSee.contains(firebaseAuth.currentUser!.uid)) {
            statusData.add(tempStatus);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print(e);
      showSnackBar(context: context, content: e.toString());
    }
    return statusData;
  }
}
