import 'package:flutter/material.dart';
import 'package:test_project/screens/HomeScreen.dart';
import 'package:test_project/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:test_project/widgets/keys.dart';
import 'firebase_options.dart';
import 'package:flutter_stripe/flutter_stripe.dart';



var kColorScheme = ColorScheme.fromSeed(
  seedColor: const Color.fromARGB(255, 242, 223, 214),
);


void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications and await the result
  await NotiService().initNotification();
  
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = PublishableKey;
  await Stripe.instance.applySettings();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme : ThemeData().copyWith(
        colorScheme: kColorScheme,
        appBarTheme: const AppBarTheme().copyWith(
          backgroundColor: kColorScheme.onPrimaryContainer,
          foregroundColor: kColorScheme.primaryContainer,
        ),
      ),
       home: const SplashScreen(),
    );
  }
}