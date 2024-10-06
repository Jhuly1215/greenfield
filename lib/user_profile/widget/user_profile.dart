import 'package:flutter/material.dart';
import 'package:flutter_gmaps/Views/MiTeleferico/Registro/ListAreasCultivo.dart';
import 'package:flutter_gmaps/auth/controller/auth_controller.dart';
import 'package:flutter_gmaps/common/error_page.dart';
import 'package:flutter_gmaps/common/loading_page.dart';
import 'package:flutter_gmaps/models/user_model.dart';
import 'package:flutter_gmaps/user_profile/controller/user_profile_controller.dart';
import 'package:flutter_gmaps/user_profile/view/PrediccionesDF.dart';
import 'package:flutter_gmaps/user_profile/view/edit_profile_view.dart';
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
                colors: [Colors.white, Color(0xFF038C3E)],
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
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white, // Fondo blanco
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          ListTile(
                            leading: const Icon(Icons.person, color: Color(0xFF071D26)), // Color de íconos
                            title: const Text(
                              'Datos Personales',
                              style: TextStyle(color: Color(0xFF071D26)), // Letras color 071D26
                            ),
                            trailing: const Icon(Icons.edit, color: Color(0xFF071D26)),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                EditProfileView.route(),
                              );
                              _refreshUserDetails();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.cable, color: Color(0xFF071D26)),
                            title: const Text(
                              'Tierras',
                              style: TextStyle(color: Color(0xFF071D26)), // Letras color 071D26
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ListLineasTelefericoScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Colors.tealAccent),
                          // Botón para ver posibles incidencias
                          ListTile(
                            leading: const Icon(Icons.warning, color: Color(0xFF071D26)),
                            title: const Text(
                              'Ver posibles incidencias',
                              style: TextStyle(color: Color(0xFF071D26)), // Letras color 071D26
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => PrediccionesDF()), // Navegar a PrediccionesDF
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Colors.tealAccent),
                          // Botón de cerrar sesión
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF038C65), // Color de fondo del botón
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30), // Botón curveado
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () {
                                ref.read(authControllerProvider.notifier).logout(context);
                              },
                              child: const Text(
                                'Cerrar Sesión',
                                style: TextStyle(
                                  color: Colors.white, // Texto en blanco
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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
