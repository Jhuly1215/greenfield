import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gmaps/auth/controller/auth_controller.dart';
import 'package:flutter_gmaps/auth/view/signup_view.dart';
import 'package:flutter_gmaps/auth/widgets/auth_field.dart';
import 'package:flutter_gmaps/common/loading_page.dart';
import 'package:flutter_gmaps/common/rounded_small_button.dart';
import 'package:flutter_gmaps/constants/ui_constants.dart';
import 'package:flutter_gmaps/utils/Theme.dart'; // Importa el archivo de tema correcto
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginView extends ConsumerStatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const LoginView(),
      );
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final appbar = UIConstants.appBar();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  void onLogin() {
    ref.read(authControllerProvider.notifier).login(
          email: emailController.text,
          password: passwordController.text,
          context: context,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);
    final theme = isDarkMode ? darkTheme : lightTheme; // Usa el tema correcto según la preferencia

    return Scaffold(
      appBar: appbar,
      backgroundColor: theme.scaffoldBackgroundColor, // Asegura que el fondo del Scaffold sea del color del tema
      body: isLoading
          ? const Loader()
          : Center(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Iniciar Sesión",
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 32, // Aumenta el tamaño del título
                              color: theme.textTheme.headlineSmall?.color,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Inicia sesión con tu cuenta",
                            style: TextStyle(
                              fontSize: 15,
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: 'Correo',
                          hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
                          filled: true,
                          fillColor: isDarkMode ? Colors.black45 : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                      ),
                      const SizedBox(height: 25),
                      TextFormField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        decoration: InputDecoration(
                          hintText: 'Contraseña',
                          hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
                          filled: true,
                          fillColor: isDarkMode ? Colors.black45 : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                      ),
                      const SizedBox(height: 40),
                      Align(
                        alignment: Alignment.centerRight,
                        child: RoundedSmallButton(
                          onTap: onLogin,
                          label: 'Iniciar Sesión',
                          backgroundColor: theme.primaryColor,
                          textColor: theme.scaffoldBackgroundColor,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: "No tienes una cuenta?",
                            style: theme.textTheme.bodyLarge,
                            children: [
                              TextSpan(
                                text: ' Registrarse',
                                style: TextStyle(
                                  color: theme.primaryColor,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      SignUpView.route(),
                                    );
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
            ),
    );
  }
}
