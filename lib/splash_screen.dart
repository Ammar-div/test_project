import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:test_project/onbording/onbording.dart';
import 'package:test_project/screens/HomeScreen.dart';
import 'package:test_project/screens/delivery/delivery_home_screen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool? _isFirstLaunch;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _checkFirstLaunch();
    await Future.delayed(const Duration(seconds: 2)); // Adjust splash screen duration
    _navigateToNextScreen();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('onboarding_completed') ?? false;
    setState(() {
      _isFirstLaunch = !isFirstLaunch;
    });
  }

  Future<void> _navigateToNextScreen() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Fetch the user's role from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final deliveryDoc = await FirebaseFirestore.instance
          .collection('delivery')
          .doc(user.uid)
          .get();

      String role = 'customer'; // Default role

      if (userDoc.exists) {
        role = userDoc['role'] ?? 'customer';
      } else if (deliveryDoc.exists) {
        role = deliveryDoc['role'] ?? 'delivery';
      }

      // Navigate based on the user's role
      if (role == 'delivery') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DeliveryHomeScreen(
              deliveryData: deliveryDoc.data(), // Pass delivery data to the screen
              deliveryDoc.id,
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );
      }
    } else {
      // If the user is not logged in, navigate to the onboarding or login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => _isFirstLaunch! ? const OnBording() : const HomeScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 242, 223, 214),
              Color.fromARGB(150, 242, 223, 214),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Center(
          child: Image.asset('assets/images/logo.png', width: 200),
        ),
      ),
    );
  }
}