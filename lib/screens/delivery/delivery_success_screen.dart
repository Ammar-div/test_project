import 'package:flutter/material.dart';
import 'package:test_project/screens/delivery/delivery_home_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_project/constants/colors.dart';

class DeliverySuccessScreen extends StatelessWidget {
  const DeliverySuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundGrey,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: kPrimaryBlue,
              size: 100,
            ),
            SizedBox(height: 20.h),
            Text(
              'Order Successfully Delivered!',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: kPrimaryBlue,
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue,
                foregroundColor: kWhite,
              ),
              child: Text('OK', style: TextStyle(color: kWhite)),
            ),
          ],
        ),
      ),
    );
  }
}