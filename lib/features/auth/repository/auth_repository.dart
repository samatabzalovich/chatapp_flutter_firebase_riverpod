import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import 'package:whatsapp_ui/common/repositories/common_firebase_storage_repository.dart';
import 'package:whatsapp_ui/common/utils/constants.dart';
import 'package:whatsapp_ui/features/auth/screens/OTP_screen.dart';
import 'package:whatsapp_ui/features/auth/screens/user_information_screen.dart';
import 'package:whatsapp_ui/common/utils/utils.dart';
import 'package:whatsapp_ui/models/user_model.dart';
import '../../../../mobile_layout_screen.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(
    firebaseAuth: FirebaseAuth.instance,
    firebaseFirestore: FirebaseFirestore.instance));

class AuthRepository {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firebaseFirestore;

  AuthRepository({required this.firebaseAuth, required this.firebaseFirestore});

  Future<UserModel?> getCurrentUserData() async {
    var userData = await firebaseFirestore
        .collection('users')
        .doc(firebaseAuth.currentUser?.uid)
        .get();

    UserModel? user;
    if (userData.data() != null) {
      user = UserModel.fromMap(userData.data()!);
    }
    return user;
  }

  void signInWithPhone(BuildContext context, String phoneNumber) async {
    try {
      await firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: ((phoneAuthCredential) async {
          await firebaseAuth.signInWithCredential(phoneAuthCredential);
        }),
        verificationFailed: ((error) {
          throw Exception(error.message);
        }),
        codeSent: ((String verificationId, int? resendToken) async {
          Navigator.pushNamed(context, OTPScreen.routeName,
              arguments: verificationId);
        }),
        codeAutoRetrievalTimeout: ((String verificationId) {}),
      );
    } on FirebaseException catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  void verifyOTP(
      {required BuildContext context,
      required String verificationId,
      required String userOTP}) async {
    try {
      PhoneAuthCredential phoneAuthCredential = PhoneAuthProvider.credential(
          verificationId: verificationId, smsCode: userOTP);
      await firebaseAuth.signInWithCredential(phoneAuthCredential);
      Navigator.pushNamedAndRemoveUntil(
          context, UserInformationScreen.routeName, (route) => false);
    } on FirebaseException catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  void saveUserDataToFirebase({
    required String name,
    required File? profileAvatar,
    required ProviderRef ref,
    required BuildContext context,
  }) async {
    try {
      String uid = firebaseAuth.currentUser!.uid;
      String photoUrl = staticAvatarUrl;

      if (profileAvatar != null) {
        photoUrl = await ref
            .read(commonFirebaseStorageRepositoriesProvider)
            .storeFileToFirebase('profilePic/$uid', profileAvatar);
      }

      var user = UserModel(
          name: name,
          uid: uid,
          profileAvatar: photoUrl,
          isOnline: true,
          phoneNumber: firebaseAuth.currentUser!.phoneNumber!,
          groupId: []);

      await firebaseFirestore.collection('users').doc(uid).set(user.toMap());

      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MobileLayoutScreen()),
          (route) => false);
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  Stream<UserModel> userData(String userId) {
    return firebaseFirestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((event) => UserModel.fromMap(event.data()!));
  }

  void setUserState(bool isOnline) async {
    await firebaseFirestore
        .collection('users')
        .doc(firebaseAuth.currentUser!.uid)
        .update({'isOnline': isOnline});
  }
}
