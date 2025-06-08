import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_project/constants/colors.dart';

class OrdersSummary extends StatefulWidget {
  const OrdersSummary({super.key});

  @override
  State<OrdersSummary> createState() => _OrdersSummaryState();
}

class _OrdersSummaryState extends State<OrdersSummary> {
  // Get the current delivery captain's ID
  String getCurrentDeliveryCaptainId() {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  // Fetch orders delivered by the current delivery captain
  Future<List<Map<String, dynamic>>> fetchDeliveredOrders() async {
    final String deliveryCaptainId = getCurrentDeliveryCaptainId();

    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: 'delivered')
        .where('delivery_person_id', isEqualTo: deliveryCaptainId)
        .get();

    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  // Fetch product and category data for all orders
  Future<List<Map<String, dynamic>>> fetchOrderDetails(List<Map<String, dynamic>> orders) async {
    List<Map<String, dynamic>> orderDetails = [];

    for (final order in orders) {
      final productId = order['product_infos']['product_id'];
      final productSnapshot = await FirebaseFirestore.instance.collection('products').doc(productId).get();
      final productData = productSnapshot.data() as Map<String, dynamic>;
      final categoryId = productData['categoryId'];

      final categorySnapshot = await FirebaseFirestore.instance.collection('categories').doc(categoryId).get();
      final categoryData = categorySnapshot.data() as Map<String, dynamic>;
      final categoryName = categoryData['name'] ?? 'Null Category';

      orderDetails.add({
        ...order,
        'product_data': productData,
        'category_name': categoryName,
      });
    }

    return orderDetails;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundGrey,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchDeliveredOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: kPrimaryBlue));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: kPrimaryBlue)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No delivered orders found.', style: TextStyle(color: kPrimaryBlue)));
          } else {
            final orders = snapshot.data!;

            return FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchOrderDetails(orders),
              builder: (context, orderDetailsSnapshot) {
                if (orderDetailsSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: kPrimaryBlue));
                } else if (orderDetailsSnapshot.hasError) {
                  return Center(child: Text('Error: ${orderDetailsSnapshot.error}', style: TextStyle(color: kPrimaryBlue)));
                } else if (!orderDetailsSnapshot.hasData || orderDetailsSnapshot.data!.isEmpty) {
                  return Center(child: Text('No order details found.', style: TextStyle(color: kPrimaryBlue)));
                } else {
                  final orderDetails = orderDetailsSnapshot.data!;

                  return ListView.builder(
                    itemCount: orderDetails.length,
                    itemBuilder: (context, index) {
                      final order = orderDetails[index];
                      final productData = order['product_data'];
                      final categoryName = order['category_name'];

                      final deliveredDate = order['delivered_date'];
                      final formattedDeliveredDate = deliveredDate != null
                          ? DateFormat('MMM d, h:mm a').format((deliveredDate as Timestamp).toDate())
                          : 'Not available';

                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        color: kWhite,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order ID: ${order['buyer_id']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                  color: kPrimaryBlue,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text('Product: ${productData['name']}', style: TextStyle(color: kPrimaryBlue)),
                              Text('Category: $categoryName', style: TextStyle(color: kPrimaryBlue)),
                              Text('Quantity: ${order['product_infos']['quantity']}', style: TextStyle(color: kPrimaryBlue)),
                              Text('Total Amount: \$${order['product_infos']['total_amount']}', style: TextStyle(color: kPrimaryBlue)),
                              SizedBox(height: 8.h),
                              Text(
                                'Receiver Info:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryBlue,
                                ),
                              ),
                              Text('Name: ${order['receiver_infos']['receiver_name']}', style: TextStyle(color: kPrimaryBlue)),
                              Text('Phone: ${order['receiver_infos']['receiver_phone_number']}', style: TextStyle(color: kPrimaryBlue)),
                              Text('Pickup Location: ${order['receiver_infos']['receiver_pick_up_location']}', style: TextStyle(color: kPrimaryBlue)),
                              SizedBox(height: 8.h),
                              Text(
                                'Seller Info:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryBlue,
                                ),
                              ),
                              Text('Seller Location: ${order['seller_location']}', style: TextStyle(color: kPrimaryBlue)),
                              Text('Seller Phone: ${order['seller_phone_number']}', style: TextStyle(color: kPrimaryBlue)),
                              SizedBox(height: 8.h),
                              Text(
                                'Delivery Date: $formattedDeliveredDate',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: kPrimaryBlue.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            );
          }
        },
      ),
    );
  }
}