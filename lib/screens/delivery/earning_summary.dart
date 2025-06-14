import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_project/constants/colors.dart';

class EarningSummary extends StatefulWidget {
  const EarningSummary({super.key});

  @override
  State<EarningSummary> createState() => _EarningSummaryState();
}

class _EarningSummaryState extends State<EarningSummary> {
  Stream<QuerySnapshot> _getEarningsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return FirebaseFirestore.instance
        .collection('delivery_earnings')
        .where('delivery_captain_id', isEqualTo: user.uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots();
  }

  double _calculateTotalEarnings(List<QueryDocumentSnapshot> docs) {
    return docs.fold(0.0, (sum, doc) => sum + (doc['amount'] as num).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundGrey,
      appBar: AppBar(
        backgroundColor: kPrimaryBlue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kWhite, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Daily Earnings',
          style: TextStyle(color: kWhite, fontSize: 20.sp),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getEarningsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(fontSize: 16.sp)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No earnings for today.',
                style: TextStyle(fontSize: 18.sp, color: Colors.grey),
              ),
            );
          }

          final earningsDocs = snapshot.data!.docs;
          final totalEarnings = _calculateTotalEarnings(earningsDocs);

          return Column(
            children: [
              Container(
                padding: EdgeInsets.all(20.r),
                margin: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: kPrimaryBlue,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Earnings Today',
                      style: TextStyle(
                        color: kWhite,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      '${totalEarnings.toStringAsFixed(2)} JOD',
                      style: TextStyle(
                        color: Colors.green[300],
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  itemCount: earningsDocs.length,
                  itemBuilder: (context, index) {
                    final earning = earningsDocs[index].data() as Map<String, dynamic>;
                    return _buildEarningCard(earning, earningsDocs[index].id);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEarningCard(Map<String, dynamic> earning, String docId) {
    final deliveredDate = earning['delivered_date'] != null
        ? (earning['delivered_date'] as Timestamp).toDate()
        : DateTime.now();
    final formattedDate = DateFormat('MMM d, yyyy h:mm a').format(deliveredDate);
    final amount = earning['amount']?.toDouble() ?? 0.0;
    final orderId = earning['order_id']?.toString() ?? 'N/A';

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${orderId.substring(0, 8)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: kPrimaryBlue,
                  ),
                ),
                Text(
                  '${amount.toStringAsFixed(2)} JOD',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'Delivered: $formattedDate',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}