import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gmaps/auth/view/login_view.dart';
import 'package:flutter_gmaps/auth/view/signup_view.dart';
import 'package:flutter_gmaps/constants/assets_constants.dart';
import 'package:flutter_gmaps/Views/home_view.dart';
import 'package:flutter_gmaps/utils/Theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends ConsumerStatefulWidget {
  static Route route() {
    return MaterialPageRoute<void>(builder: (_) => WelcomePage());
  }

  const WelcomePage({Key? key}) : super(key: key);

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDarkMode = prefs.getBool('isDarkMode') ?? false;
      setState(() {
        _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading theme: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = _themeMode == ThemeMode.dark;
    await prefs.setBool('isDarkMode', !isDarkMode);
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeMode == ThemeMode.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const Column(
                      children: <Widget>[
                        Text(
                          "Bienvenido a AYI",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                          ),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height / 3,
                      child: SvgPicture.asset(AssetsConstants.WelcomeLogo),
                    ),
                    Column(
                      children: <Widget>[
                        Text(
                          "Explora tus alrededores con AYI",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 15,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 1),
                    Column(
                      children: <Widget>[
                        MaterialButton(
                          minWidth: double.infinity,
                          height: 60,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpView(),
                              ),
                            );
                          },
                          color: const Color.fromRGBO(0, 121, 107, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Text(
                            "Registrarse con correo electrónico",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        MaterialButton(
                          minWidth: double.infinity,
                          height: 60,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomeView(
                                  toggleTheme: _toggleTheme,
                                  isDarkMode: isDarkMode,
                                ),
                              ),
                            );
                          },
                          color: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Text(
                            "Continuar sin iniciar sesión",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    RichText(
                      text: TextSpan(
                        text: "¿Ya tienes una cuenta? ",
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: 'Iniciar sesión',
                            style: const TextStyle(
                              color: Color.fromRGBO(0, 121, 107, 1),
                              fontSize: 16,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  LoginView.route(),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.brightness_6),
                  onPressed: _toggleTheme,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
