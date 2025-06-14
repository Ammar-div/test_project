import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:test_project/screens/delivery/delivery_home_screen.dart';
import 'package:test_project/screens/delivery/earning_summary.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_project/constants/colors.dart';

class DeliverySuccessScreen extends StatelessWidget {
  final String orderId;

  const DeliverySuccessScreen({super.key, required this.orderId});

  Future<void> _saveEarnings(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final orderDoc = await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .get();

    if (!orderDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order not found.')),
      );
      return;
    }

    final deliveredDate = orderDoc['delivered_date'] as Timestamp? ?? Timestamp.now();

    await FirebaseFirestore.instance
        .collection('delivery_earnings')
        .doc('${user.uid}_$orderId')
        .set({
      'delivery_captain_id': user.uid,
      'order_id': orderId,
      'amount': 3.0,
      'date': Timestamp.fromDate(DateTime.now()),
      'delivered_date': deliveredDate,
    });
  }

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
              size: 100.sp,
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
              onPressed: () async {
                await _saveEarnings(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EarningSummary(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue,
                foregroundColor: kWhite,
              ),
              child: Text('OK', style: TextStyle(color: kWhite, fontSize: 16.sp)),
            ),
          ],
        ),
      ),
    );
  }
}