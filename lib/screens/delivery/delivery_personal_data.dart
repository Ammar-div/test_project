import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test_project/screens/HomeScreen.dart';
import 'package:url_launcher/url_launcher.dart'; // Import the intl package
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_project/constants/colors.dart';

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
      backgroundColor: kBackgroundGrey,
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                      color: kPrimaryBlue,
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
                      color: kPrimaryBlue,
                    ),
                  ),
                ],
              ),
               SizedBox(height: 20.h),
              Row(
                children: [
                  Text(
                    'Captain ID',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    deliveryId,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                ],
              ),
              Divider(
                color: kPrimaryBlue.withOpacity(0.2),
              ),
              Row(
                children: [
                  Text(
                    'Phone Number',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    deliveryData!['phone_number'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                ],
              ),
              Divider(
                color: kPrimaryBlue.withOpacity(0.2),
              ),
              Row(
                children: [
                  Text(
                    'Email',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    deliveryData!['email'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                ],
              ),
              Divider(
                color: kPrimaryBlue.withOpacity(0.2),
              ),
              Row(
                children: [
                  Text(
                    'National ID',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    deliveryData!['national_id'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                ],
              ),
              Divider(
                color: kPrimaryBlue.withOpacity(0.2),
              ),
              Row(
                children: [
                  Text(
                    'Area',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    deliveryData!['location'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                ],
              ),
              Divider(
                color: kPrimaryBlue.withOpacity(0.2),
              ),
              Row(
                children: [
                  Text(
                    'Joining Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    joiningDate,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                ],
              ),
              Divider(
                color: kPrimaryBlue.withOpacity(0.2),
              ),
               SizedBox(height: 40.h),
               Row(
                children: [
                  Text(
                    "Vehicle information",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19.sp,
                      color: kPrimaryBlue,
                    ),
                  ),
                ],
              ),
               SizedBox(height: 20.h),
              Row(
                children: [
                  Text(
                    'Vehicle Number',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    deliveryData!['Vehicle_Infos']['vehicle_number'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                ],
              ),
              Divider(
                color: kPrimaryBlue.withOpacity(0.2),
              ),
              Row(
                children: [
                  Text(
                    'Vehicle Type',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    deliveryData!['Vehicle_Infos']['vehicle_type'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                ],
              ),
              Divider(
                color: kPrimaryBlue.withOpacity(0.2),
              ),
              Row(
                children: [
                  Text(
                    'Vehicle Model',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    deliveryData!['Vehicle_Infos']['vehicle_model'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                ],
              ),
              Divider(
                color: kPrimaryBlue.withOpacity(0.2),
              ),
              Row(
                children: [
                  Text(
                    'Vehicle Color',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    deliveryData!['Vehicle_Infos']['Vehicle_Color'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                ],
              ),
              Divider(
                color: kPrimaryBlue.withOpacity(0.2),
              ),
               SizedBox(height: 30.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryBlue,
                      foregroundColor: kWhite,
                    ),
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (ctx) => const HomeScreen(),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout, color: kWhite),
                        SizedBox(width: 8.w),
                        Text('Log out', style: TextStyle(color: kWhite)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryBlue,
                      foregroundColor: kWhite,
                    ),
                    onPressed: _openWhatsApp,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone, color: kWhite),
                        SizedBox(width: 8.w),
                        Text('Support', style: TextStyle(color: kWhite)),
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