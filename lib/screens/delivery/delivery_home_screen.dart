import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:test_project/screens/auth_screen.dart';
import 'package:test_project/screens/delivery/active_order.dart';
import 'package:test_project/screens/delivery/delivery_personal_data.dart';
import 'package:test_project/screens/delivery/earning_summary.dart';
import 'package:test_project/screens/delivery/orders_summary.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class DeliveryHomeScreen extends StatefulWidget {
  final Map<String, dynamic>? deliveryData;
  final String deliveryId;

  const DeliveryHomeScreen(this.deliveryId, {super.key, required this.deliveryData});

  @override
  State<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  int _page = 0;
  GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  // Function to open WhatsApp
  Future<void> _openWhatsApp() async {
    const phoneNumber = '+962798030585';
    final url = Uri.parse('https://wa.me/$phoneNumber');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // List of screens to display based on the selected index
  final List<Widget> _screens = [
    const Center(child: Text('Home Screen')), // Home Screen (index 0)
    OrdersSummary(), // OrdersSummary (index 1)
    EarningSummary(), // EarningSummary (index 2)
    ActiveOrder(), // ActiveOrder (index 3)
    DeliveryPersonalData(deliveryData: {}, deliveryId: ''), // Placeholder, will be replaced
  ];

  @override
  Widget build(BuildContext context) {
    // Update the DeliveryPersonalData screen with the correct deliveryData and deliveryId
    _screens[4] = DeliveryPersonalData(
      deliveryData: widget.deliveryData,
      deliveryId: widget.deliveryId,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_page], // Display the selected screen
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _page,
        height: 65.0,
        items: const [
          Icon(Icons.home, size: 30),
          Icon(Icons.delivery_dining, size: 30), // OrdersSummary (index 1)
          Icon(Icons.account_balance_wallet, size: 30), // EarningSummary (index 2)
          Icon(Icons.history, size: 30), // ActiveOrder (index 3)
          Icon(Icons.person, size: 30), // DeliveryPersonalData (index 4)
        ],
        color: const Color.fromARGB(255, 128, 171, 206),
        buttonBackgroundColor: const Color.fromARGB(255, 62, 157, 235),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 400),
        onTap: (index) {
          setState(() {
            _page = index.clamp(0, 4);
          });
        },
      ),
    );
  }
}