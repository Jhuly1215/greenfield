import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gmaps/core/utils.dart';
import 'package:flutter_gmaps/models/user_model.dart';
import 'package:flutter_gmaps/resources/storage_api.dart';
import 'package:flutter_gmaps/resources/user_methods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userProfileControllerProvider =
    StateNotifierProvider<UserProfileController, bool>((ref) {
  return UserProfileController(
    storageAPI: ref.watch(storageAPIProvider),
    userAPI: ref.watch(userAPIProvider),
  );
});

final getLatestUserProfileDataProvider = StreamProvider((ref) {
  final userAPI = ref.watch(userAPIProvider);
  return userAPI.getLatestUserProfileData();
});

class UserProfileController extends StateNotifier<bool> {
  final StorageAPI _storageAPI;
  final UserAPI _userAPI;
  UserProfileController({
    required StorageAPI storageAPI,
    required UserAPI userAPI,
  })  : 
        _storageAPI = storageAPI,
        _userAPI = userAPI,
        super(false);

  void updateUserProfile({
    required UserModel userModel,
    required BuildContext context,
    File? bannerFile,
    File? profileFile,
  }) async {
    state = true;

    try {
      String? profilePicUrl = userModel.profilePic;

      // Subir profileFile y obtener la URL
      if (profileFile != null) {
        final profileUrls = await _storageAPI.uploadImage([profileFile]);
        profilePicUrl = profileUrls[0];
        print('Profile URL: $profilePicUrl');
      }

      userModel = userModel.copyWith(
        profilePic: profilePicUrl,
      );

      final res = await _userAPI.updateUserData(userModel);
      state = false;
      res.fold(
        (l) => showSnackBar(context, l.message),
        (r) => Navigator.pop(context),
      );
    } catch (e) {
      state = false;
      showSnackBar(context, e.toString());
    }
  }
}
