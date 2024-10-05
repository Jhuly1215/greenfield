import 'package:flutter/material.dart';
import 'package:flutter_gmaps/Views/MiTeleferico/Registro/ListAreasCultivo.dart';
import 'package:flutter_gmaps/auth/controller/auth_controller.dart';
import 'package:flutter_gmaps/common/error_page.dart';
import 'package:flutter_gmaps/common/loading_page.dart';
import 'package:flutter_gmaps/models/user_model.dart';
import 'package:flutter_gmaps/user_profile/controller/user_profile_controller.dart';
import 'package:flutter_gmaps/user_profile/view/edit_profile_view.dart';
import 'package:flutter_gmaps/utils/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfile extends ConsumerWidget {
  final String uid; // Usamos uid para identificar al usuario
  const UserProfile({
    super.key,
    required this.uid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(userDetailsProvider(uid));

    void _refreshUserDetails() {
      ref.refresh(userDetailsProvider(uid));
    }

    return userAsyncValue.when(
      data: (user) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.tealAccent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(user.profilePic),
                          radius: 50,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.teal[700],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          ListTile(
                            leading: const Icon(Icons.person, color: Colors.white),
                            title: const Text(
                              'Datos Personales',
                              style: TextStyle(color: Colors.white),
                            ),
                            trailing: const Icon(Icons.edit, color: Colors.white),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                EditProfileView.route(),
                              );
                              _refreshUserDetails();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.cable, color: Colors.white),
                            title: const Text('Tierras', style: TextStyle(color: Colors.white)),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ListLineasTelefericoScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Colors.tealAccent),
                          ListTile(
                            title: const Text(
                              'Cerrar Sesión',
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            onTap: () {
                              ref.read(authControllerProvider.notifier).logout(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Loader(),
      error: (err, stack) => ErrorText(error: err.toString()),
    );
  }
}
