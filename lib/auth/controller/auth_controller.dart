import 'package:firebase_auth/firebase_auth.dart' as model;
import 'package:flutter/material.dart';
import 'package:flutter_gmaps/Views/home_view.dart';
import 'package:flutter_gmaps/auth/view/login_view.dart';
import 'package:flutter_gmaps/auth/view/welcome.dart';
import 'package:flutter_gmaps/core/utils.dart';
import 'package:flutter_gmaps/models/user_model.dart';
import 'package:flutter_gmaps/resources/auth_api.dart';
import 'package:flutter_gmaps/resources/user_methods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authControllerProvider = StateNotifierProvider<AuthController, bool>((ref) {
  return AuthController(
    authAPI: ref.watch(authAPIProvider),
    userAPI: ref.watch(userAPIProvider),
  );
});

final currentUserDetailsProvider = FutureProvider((ref) {
  final currentUserId = ref.watch(currentUserAccountProvider).value!.uid;
  final userDetails = ref.watch(userDetailsProvider(currentUserId));
  return userDetails.value;
});

final userDetailsProvider = FutureProvider.family((ref, String uid) {
  final authController = ref.watch(authControllerProvider.notifier);
  return authController.getUserData(uid);
});

final currentUserAccountProvider = FutureProvider((ref) {
  final authController = ref.watch(authControllerProvider.notifier);
  return authController.currentUser();
});

class AuthController extends StateNotifier<bool> {
  ValueChanged<String?>? onMessage;
  ValueChanged<String?>? onEmailVerification;
  final AuthAPI _authAPI;
  final UserAPI _userAPI;

  AuthController({
    required AuthAPI authAPI,
    required UserAPI userAPI,
  })  : _authAPI = authAPI,
        _userAPI = userAPI,
        super(false);

  Future<model.User?> currentUser() => _authAPI.currentUserAccount();

  void signUp({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String birthDate,
    required BuildContext context,
  }) async {
    state = true;
    final res = await _authAPI.signUp(
      email: email,
      password: password,
    );
    state = false;
    res.fold(
      (l) => showSnackBar(context, l.message),
      (r) async {
        UserModel userModel = UserModel(
          email: email,
          name: name,
          phoneNumber: phoneNumber,
          birthDate: birthDate,
          password: password,
          uid: r!.uid, profilePic: '',
        );
        final res2 = await _userAPI.saveUserData(userModel);
        res2.fold((l) => showSnackBar(context, l.message), (r) {
          showSnackBar(context, 'Account created! Please login.');
          Navigator.push(context, LoginView.route());
        });
      },
    );
  }

  void login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    state = true;
    final res = await _authAPI.login(
      email: email,
      password: password,
    );
    state = false;
    res.fold(
      (l) => showSnackBar(context, l.message),
      (r) async {
        final prefs = await SharedPreferences.getInstance();
        final isDarkMode = prefs.getBool('isDarkMode') ?? false;
        Navigator.push(
          context,
          HomeView.route(toggleTheme: () {
            // Actualiza el tema global aquí si es necesario
          }, isDarkMode: isDarkMode),
        );
      },
    );
  }

  Future<UserModel> getUserData(String uid) async {
    final document = await _userAPI.getUserData(uid);
    if (document.exists) {
      final updatedUser = UserModel.fromMap(
        document.data() as Map<String, dynamic>,
        documentId: document.id, // Agrega el ID del documento al constructor
      );
      return updatedUser;
    } else {
      throw Exception('User data not found for uid: $uid');
    }
  }

  void logout(BuildContext context) async {
    final res = await _authAPI.logout();
    res.fold((l) => null, (r) {
      Navigator.pushAndRemoveUntil(
        context,
        WelcomePage.route(),
        (route) => false,
      );
    });
  }
}
