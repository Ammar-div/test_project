import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_project/constants/colors.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> order;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    // Add null checks for all fields
    final deliveredDate = order['delivered_date'] != null 
        ? (order['delivered_date'] as Timestamp).toDate() 
        : DateTime.now();
    final formattedDate = DateFormat('MMM d, yyyy h:mm a').format(deliveredDate);
    
    final amount = order['product_infos']?['total_amount']?.toDouble() ?? 0.0;
    final status = order['status']?.toString().toLowerCase() ?? 'pending';
    final productId = order['product_infos']?['product_id']?.toString() ?? 'N/A';
    final buyerId = order['buyer_id']?.toString() ?? 'N/A';
    final sellerId = order['seller_id']?.toString() ?? 'N/A';
    final quantity = order['product_infos']?['quantity']?.toString() ?? 'N/A';

    return Scaffold(
      backgroundColor: kBackgroundGrey,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID
            _buildInfoSection(
              'Order ID',
              orderId,
              Icons.receipt_long,
            ),
            SizedBox(height: 16.h),

            // Amount
            _buildInfoSection(
              'Amount',
              '${amount.toStringAsFixed(2)} JOD',
              Icons.attach_money,
              valueColor: Colors.green[700],
            ),
            SizedBox(height: 16.h),

            // Status
            _buildInfoSection(
              'Status',
              status.toUpperCase(),
              Icons.info_outline,
              valueColor: _getStatusColor(status),
            ),
            SizedBox(height: 16.h),

            // Date
            _buildInfoSection(
              'Delivery Date',
              formattedDate,
              Icons.calendar_today,
            ),
            SizedBox(height: 16.h),

            // Quantity
            _buildInfoSection(
              'Quantity',
              quantity,
              Icons.shopping_cart,
            ),
            SizedBox(height: 16.h),

            // Product
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('products')
                  .doc(productId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final productData = snapshot.data!.data() as Map<String, dynamic>?;
                  return _buildInfoSection(
                    'Product',
                    productData?['name'] ?? 'Unknown Product',
                    Icons.inventory_2_outlined,
                  );
                }
                return _buildInfoSection(
                  'Product',
                  'Loading...',
                  Icons.inventory_2_outlined,
                );
              },
            ),
            SizedBox(height: 16.h),

            // Buyer
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(buyerId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final userData = snapshot.data!.data() as Map<String, dynamic>?;
                  return _buildInfoSection(
                    'Buyer',
                    userData?['name'] ?? 'Unknown User',
                    Icons.person_outline,
                  );
                }
                return _buildInfoSection(
                  'Buyer',
                  'Loading...',
                  Icons.person_outline,
                );
              },
            ),
            SizedBox(height: 16.h),

            // Seller
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(sellerId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final userData = snapshot.data!.data() as Map<String, dynamic>?;
                  return _buildInfoSection(
                    'Seller',
                    userData?['name'] ?? 'Unknown User',
                    Icons.store_outlined,
                  );
                }
                return _buildInfoSection(
                  'Seller',
                  'Loading...',
                  Icons.store_outlined,
                );
              },
            ),
            SizedBox(height: 16.h),

            // Receiver Info
            _buildInfoSection(
              'Receiver Name',
              order['receiver_infos']?['receiver_name'] ?? 'N/A',
              Icons.person_outline,
            ),
            SizedBox(height: 16.h),

            _buildInfoSection(
              'Receiver Phone',
              order['receiver_infos']?['receiver_phone_number'] ?? 'N/A',
              Icons.phone_outlined,
            ),
            SizedBox(height: 16.h),

            _buildInfoSection(
              'Pickup Location',
              order['receiver_infos']?['receiver_pick_up_location'] ?? 'N/A',
              Icons.location_on_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    String value,
    IconData icon, {
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: Colors.blue.shade800,
              size: 24.r,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: valueColor ?? Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 