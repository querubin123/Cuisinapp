import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'EateryOwnerSettingsPage.dart';
import 'EaterySignInPage.dart';
import 'splash_page.dart'; // Make sure to import your splash_page.dart
import 'signup_options_page.dart'; // Make sure to import your signup_options_page.dart

Future<void> main() async {
  // Load .env file
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  final MaterialColor myColor = const MaterialColor(0xFFCDE990, {
    50: Color(0xFFF1F8E9),
    100: Color(0xFFDCEDC8),
    200: Color(0xFFC5E1A5),
    300: Color(0xFFAED581),
    400: Color(0xFF9CCC65),
    500: Color(0xFF8BC34A),
    600: Color(0xFF7CB342),
    700: Color(0xFF689F38),
    800: Color(0xFF558B2F),
    900: Color(0xFF33691E),
  });

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cuisinapp',
      theme: ThemeData(
        primarySwatch: myColor,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/signup_options': (context) => const SignUpOptionsPage(),
        '/eatery_owner_settings': (context) => EateryOwnerSettingsPage(),
        '/eatery_sign_in': (context) => EaterySignInPage(),
      },
    );
  }
}
