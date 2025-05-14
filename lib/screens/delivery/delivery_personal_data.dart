import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test_project/screens/HomeScreen.dart';
import 'package:url_launcher/url_launcher.dart'; // Import the intl package
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DeliveryPersonalData extends StatelessWidget {
  final Map<String, dynamic>? deliveryData;
  final String deliveryId;
  const DeliveryPersonalData({super.key, required this.deliveryData, required this.deliveryId});

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

  @override
  Widget build(BuildContext context) {
    // Format the joining date to display only year, month, and day
    final joiningDate = deliveryData!['joining_date'] != null
        ? DateFormat('yyyy-MM-dd').format(deliveryData!['joining_date'].toDate())
        : 'N/A';

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundImage: deliveryData?['image_url'] != null && deliveryData!['image_url'].isNotEmpty
                        ? NetworkImage(deliveryData!['image_url']) as ImageProvider
                        : const AssetImage('assets/images/profile_placeholder.jpg'),
                  ),
                  Text(
                    deliveryData!['name'],
                    style:  TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 21.sp,
                    ),
                  ),
                ],
              ),
               SizedBox(height: 50.h),
               Row(
                children: [
                  Text(
                    "Captain's information",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19.sp,
                    ),
                  ),
                ],
              ),
               SizedBox(height: 20.h),
              Row(
                children: [
                  const Text(
                    'Captain ID',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    deliveryId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Divider(
                color: Colors.grey[300],
              ),
              Row(
                children: [
                  const Text(
                    'Phone Number',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    deliveryData!['phone_number'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Divider(
                color: Colors.grey[300],
              ),
              Row(
                children: [
                  const Text(
                    'Email',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    deliveryData!['email'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Divider(
                color: Colors.grey[300],
              ),
              Row(
                children: [
                  const Text(
                    'National ID',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    deliveryData!['national_id'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Divider(
                color: Colors.grey[300],
              ),
              Row(
                children: [
                  const Text(
                    'Area',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    deliveryData!['location'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Divider(
                color: Colors.grey[300],
              ),
              Row(
                children: [
                  const Text(
                    'Joining Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    joiningDate, // Use the formatted date here
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Divider(
                color: Colors.grey[300],
              ),
               SizedBox(height: 40.h),
               Row(
                children: [
                  Text(
                    "Vehicle information",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19.sp,
                    ),
                  ),
                ],
              ),
               SizedBox(height: 20.h),
              Row(
                children: [
                  const Text(
                    'Vehicle Number',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    deliveryData!['Vehicle_Infos']['vehicle_number'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Divider(
                color: Colors.grey[300],
              ),
              Row(
                children: [
                  const Text(
                    'Vehicle Type',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    deliveryData!['Vehicle_Infos']['vehicle_type'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Divider(
                color: Colors.grey[300],
              ),
              Row(
                children: [
                  const Text(
                    'Vehicle Model',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    deliveryData!['Vehicle_Infos']['vehicle_model'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Divider(
                color: Colors.grey[300],
              ),
              Row(
                children: [
                  const Text(
                    'Vehicle Color',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    deliveryData!['Vehicle_Infos']['Vehicle_Color'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Divider(
                color: Colors.grey[300],
              ),
               SizedBox(height: 30.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 240, 202, 200),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (ctx) => const HomeScreen(),
                        ),
                      );
                    },
                    child:  Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8.w),
                        Text('Log out'),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 200, 230, 240),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _openWhatsApp,
                    child:  Row(
                      mainAxisSize: MainAxisSize.min, // Ensure the Row takes only the required space
                      children: [
                        Icon(Icons.phone), // Add the phone icon
                        SizedBox(width: 8.w), // Add some spacing between the icon and text
                        Text('Support'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}