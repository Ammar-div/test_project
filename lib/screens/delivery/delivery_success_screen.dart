import 'package:flutter/material.dart';
import 'package:test_project/screens/delivery/delivery_home_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';



class DeliverySuccessScreen extends StatelessWidget {
  const DeliverySuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 100,
            ),
             SizedBox(height: 20.h),
             Text(
              'Order Successfully Delivered!',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
             SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () {
                // Navigate back to the home screen or any other screen
                // Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}