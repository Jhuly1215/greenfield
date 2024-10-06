import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importa FirebaseAuth
import 'package:flutter_gmaps/user_profile/widget/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gmaps/models/user_model.dart';
import 'package:flutter_gmaps/common/error_page.dart';

// StreamProvider para obtener los datos del perfil de usuario en tiempo real
final userProfileStreamProvider = StreamProvider.autoDispose<UserModel>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid; // Obtén el UID del usuario actual
  if (uid != null) {
    final userProfileStream = FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
    return userProfileStream.map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromMap(snapshot.data()!, documentId: snapshot.id);
      } else {
        throw Exception('User not found');
      }
    });
  } else {
    throw Exception('User not authenticated');
  }
});

class UserProfileView extends ConsumerWidget {
  static MaterialPageRoute route() => MaterialPageRoute(
        builder: (context) => UserProfileView(),
      );

  const UserProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsyncValue = ref.watch(userProfileStreamProvider);

    return Scaffold(
      body: userProfileAsyncValue.when(
        data: (user) => UserProfile(uid: user.uid),
        loading: () => const Center(child: CircularProgressIndicator()), // Mostrar un indicador de carga mientras carga
        error: (error, st) => ErrorText(error: error.toString()),
      ),
    );
  }
}
