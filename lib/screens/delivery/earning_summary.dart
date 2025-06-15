import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_project/constants/colors.dart';
import 'package:test_project/screens/delivery/delivery_home_screen.dart';

class EarningSummary extends StatelessWidget {
  const EarningSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      backgroundColor: kBackgroundGrey,
      appBar: AppBar(
        backgroundColor: kPrimaryBlue,
        title: Text(
          'Daily Earnings',
          style: TextStyle(color: kWhite, fontSize: 20.sp),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kWhite),
          onPressed: () {
            // Navigator.of(context).pushReplacement(
            //   MaterialPageRoute(
            //     builder: (context) => const DeliveryHomeScreen(),
            //   ),
            // );
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('delivery_earnings')
            .where('delivery_captain_id', isEqualTo: user!.uid)
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('date', isLessThan: Timestamp.fromDate(endOfDay))
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(fontSize: 16.sp, color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No earnings recorded for today.',
                style: TextStyle(fontSize: 18.sp, color: Colors.grey),
              ),
            );
          }

          final earnings = snapshot.data!.docs;
          double totalEarnings = earnings.fold(
              0.0, (sum, doc) => sum + (doc['amount'] as double));

          return Column(
            children: [
              // Total Earnings Card
              Container(
                margin: EdgeInsets.all(16.r),
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Earnings Today',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryBlue,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${totalEarnings.toStringAsFixed(2)} JOD',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Deliveries: ${earnings.length}',
                      style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Earnings List
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  itemCount: earnings.length,
                  itemBuilder: (context, index) {
                    final earning = earnings[index];
                    final date = (earning['date'] as Timestamp).toDate();
                    final formattedDate =
                        DateFormat('h:mm a').format(date);
                    final amount = earning['amount'] as double;
                    final orderId = earning['order_id'] as String;

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16.r),
                        leading: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.attach_money,
                            color: Colors.green[700],
                            size: 24.sp,
                          ),
                        ),
                        title: Text(
                          'Order #$orderId',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Time: $formattedDate',
                          style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                        ),
                        trailing: Text(
                          '${amount.toStringAsFixed(2)} JOD',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}