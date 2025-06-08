import 'package:flutter/material.dart';
import 'package:test_project/screens/HomeScreen.dart';
import 'package:test_project/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:test_project/widgets/keys.dart';
import 'firebase_options.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_project/constants/colors.dart';

var kColorScheme = ColorScheme.fromSeed(
  seedColor: kPrimaryBlue,
  background: kBackgroundGrey,
  surface: kWhite,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (BuildContext coontext, Widget? child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData().copyWith(
            colorScheme: kColorScheme,
            appBarTheme: const AppBarTheme().copyWith(
              backgroundColor: kColorScheme.onPrimaryContainer,
              foregroundColor: kColorScheme.primaryContainer,
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
