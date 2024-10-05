import 'package:flutter/material.dart';
import 'package:flutter_gmaps/auth/controller/auth_controller.dart';
import 'package:flutter_gmaps/auth/widgets/auth_field.dart';
import 'package:flutter_gmaps/common/loading_page.dart';
import 'package:flutter_gmaps/constants/ui_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:flutter_gmaps/utils/Theme.dart'; // Importa el archivo de tema correcto
import 'package:shared_preferences/shared_preferences.dart';

class SignUpView extends ConsumerStatefulWidget {
  static route() => MaterialPageRoute(builder: (context) => const SignUpView());
  const SignUpView({Key? key}) : super(key: key);

  @override
  ConsumerState<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends ConsumerState<SignUpView> {
  final appbar = UIConstants.appBar();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final nameController = TextEditingController();
  final birthDateController = TextEditingController();
  bool isPasswordVisible = false;
  bool pumaKatari = false;
  bool teleferico = false;
  String fullPhoneNumber = '';
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneNumberController.dispose();
    nameController.dispose();
    birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  String? validatePassword(String value) {
    if (value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one digit';
    }
    return null;
  }

  void onSignUp() {
    String phoneNumber = fullPhoneNumber;
    ref.read(authControllerProvider.notifier).signUp(
          email: emailController.text,
          password: passwordController.text,
          name: nameController.text,
          phoneNumber: phoneNumber,
          birthDate: birthDateController.text,
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
                    children: [
                      Text(
                        'Create an Account',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.headlineSmall?.color,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: 'Email',
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
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        decoration: InputDecoration(
                          hintText: 'Password',
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
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: !isPasswordVisible,
                        decoration: InputDecoration(
                          hintText: 'Confirm Password',
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
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'Full Name',
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
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: birthDateController,
                        decoration: InputDecoration(
                          hintText: 'Birth Date (YYYY-MM-DD)',
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
                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Phone Number:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      InternationalPhoneNumberInput(
                        onInputChanged: (PhoneNumber number) {
                          fullPhoneNumber = '${number.phoneNumber}';
                        },
                        selectorConfig: const SelectorConfig(
                          selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                          setSelectorButtonAsPrefixIcon: true,
                          leadingPadding: 20,
                          showFlags: true,
                        ),
                        inputDecoration: InputDecoration(
                          hintText: 'Phone Number',
                          hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
                          filled: true,
                          fillColor: isDarkMode ? Colors.black45 : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        textStyle: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black),
                        keyboardType: TextInputType.phone,
                        selectorTextStyle: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black),
                        textFieldController: phoneNumberController,
                        initialValue: PhoneNumber(isoCode: 'BO'),
                        countries: ['BO'],
                      ),
                      const SizedBox(height: 15),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: onSignUp,
                        child: const Text('Sign Up'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: theme.scaffoldBackgroundColor, backgroundColor: theme.primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
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
