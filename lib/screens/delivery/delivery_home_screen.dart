import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:test_project/screens/auth_screen.dart';
import 'package:url_launcher/url_launcher.dart'; // Import the url_launcher package

class DeliveryHomeScreen extends StatelessWidget {
  final Map<String, dynamic>? deliveryData;

  const DeliveryHomeScreen({super.key, required this.deliveryData});

  // Function to open WhatsApp
  Future<void> _openWhatsApp() async {
    // Replace with the phone number you want to open in WhatsApp
    const phoneNumber = '+962798030585'; // Include the country code
    final url = Uri.parse('https://wa.me/$phoneNumber'); // Convert to Uri

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(deliveryData!['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone), // Phone icon
            onPressed: _openWhatsApp, // Open WhatsApp when pressed
          ),
          const SizedBox(width: 6,),
          IconButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const AuthScreen(),
                ),
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (deliveryData != null)
              Column(
                children: [
                  Text('Name: ${deliveryData!['name']}'),
                  Text('Email: ${deliveryData!['email']}'),
                  Text('Phone: ${deliveryData!['phone_number']}'),
                  Text('Vehicle Type: ${deliveryData!['Vehicle_Infos']['vehicle_type']}'),
                  Text('Vehicle Model: ${deliveryData!['Vehicle_Infos']['vehicle_model']}'),
                  Text('Vehicle Number: ${deliveryData!['Vehicle_Infos']['vehicle_number']}'),
                ],
              ),
            if (deliveryData == null)
              const Text('No delivery data found.'),
          ],
        ),
      ),
    );
  }
}