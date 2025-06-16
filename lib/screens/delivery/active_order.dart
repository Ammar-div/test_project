import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:test_project/active_order_data.dart';
import 'package:test_project/screens/delivery/delivery_success_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_project/constants/colors.dart';

class ActiveOrder extends StatefulWidget {
  const ActiveOrder({super.key});

  @override
  State<ActiveOrder> createState() => _ActiveOrderState();
}

class _ActiveOrderState extends State<ActiveOrder> {
  bool _isLoading = false;
  bool _isReceived = false;
  bool _isMarkingDelivered = false;
  bool _isAwaitingAcknowledgment = false;

  @override
  void initState() {
    super.initState();
    // Check if the order has been received when the widget is initialized
    _checkIfReceived();
  }

  Future<void> _checkIfReceived() async {
    final activeOrderData = activeOrderNotifier.value;
    if (activeOrderData == null || activeOrderData.orderId == null) return;

    try {
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(activeOrderData.orderId)
          .get();

      if (orderDoc.exists) {
        final orderData = orderDoc.data()!;
        setState(() {
          _isReceived = orderData['is_received'] ?? false;
          _isAwaitingAcknowledgment = orderData['status'] == 'awaiting acknowledgment';
        });
      }
    } catch (e) {
      showToastrMessage("Error checking order status: $e");
    }
  }

  void showToastrMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.green[700],
      textColor: kWhite,
      fontSize: 16.0.sp,
    );
  }

  void showLongToastrMessage(String message, int durationInSeconds) {
    int repeatCount = (durationInSeconds / 3.5).ceil();
    for (int i = 0; i < repeatCount; i++) {
      Future.delayed(Duration(milliseconds: i * 3500), () {
        Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green[700],
          textColor: kWhite,
          fontSize: 16.0.sp,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundGrey,
      appBar: AppBar(
        title: Text('Order Details', style: TextStyle(color: kWhite)),
        automaticallyImplyLeading: false,
        backgroundColor: kPrimaryBlue,
        elevation: 0,
        centerTitle: true,
      ),
      body: ValueListenableBuilder<ActiveOrderData?>(
        valueListenable: activeOrderNotifier,
        builder: (context, activeOrderData, child) {
          if (activeOrderData == null) {
            return Center(
              child: Text(
                'No active order found.',
                style: TextStyle(fontSize: 18.sp, color: Colors.grey),
              ),
            );
          }

          final order = activeOrderData.orderData;
          final product = activeOrderData.productData;
          final receiverInfo =
              (order['receiver_infos'] as Map?)?.cast<String, dynamic>() ?? {};
          final sellerInfo =
              (product['seller_ifos'] as Map?)?.cast<String, dynamic>() ?? {};

          final formattedDate = order['timestamp'] != null
              ? DateFormat('yyyy-MM-dd').format(
                  DateTime.fromMillisecondsSinceEpoch(
                      order['timestamp'].seconds * 1000),
                )
              : 'Unknown';

          final acceptanceDate = order['acceptance_date'];
          final formattedAcceptanceDate = acceptanceDate != null
              ? DateFormat('MMM d, h:mm a')
                  .format((acceptanceDate as Timestamp).toDate())
              : 'Not available';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 230,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.network(
                          'https://lottie.host/7c708d27-0d79-49c8-b28e-7bcc472bfa40/mpqzewoGEO.json'),
                    ],
                  ),
                ),
                _buildInfoCard(
                  title: 'Order Information',
                  children: [
                    _buildInfoRow(Icons.receipt, 'Order ID',
                        activeOrderData.orderId ?? 'N/A'),
                    _buildInfoRow(Icons.category, 'Category',
                        activeOrderData.categoryName ?? 'N/A'),
                    _buildInfoRow(
                        Icons.shopping_cart,
                        'Quantity',
                        order['product_infos']?['quantity']?.toString() ?? 'N/A'),
                    _buildInfoRow(
                        Icons.calendar_today, 'Order Date', formattedDate),
                    _buildInfoRow(Icons.event_available, 'Acceptance Date',
                        formattedAcceptanceDate),
                  ],
                ),
                SizedBox(height: 20.h),
                _buildInfoCard(
                  title: 'Seller Information',
                  children: [
                    _buildInfoRow(Icons.person, 'Name',
                        sellerInfo['seller_name'] ?? 'N/A'),
                    _buildInfoRow(Icons.email, 'Email',
                        sellerInfo['seller_email'] ?? 'N/A'),
                    _buildInfoRow(Icons.phone, 'Phone',
                        sellerInfo['seller_phone_number'] ?? 'N/A'),
                    _buildInfoRow(Icons.location_on, 'Location',
                        sellerInfo['seller_pick_up_location'] ?? 'N/A'),
                    SizedBox(height: 16.h),
                    if (!_isReceived) // Show "Received" button only if not received
                      Align(
                        alignment: Alignment.center,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  setState(() {
                                    _isLoading = true;
                                  });

                                  try {
                                    final user = FirebaseAuth.instance.currentUser;
                                    final orderId = activeOrderData.orderId;
                                    final productId =
                                        order['product_infos']['product_id'];

                                    final orderDoc = await FirebaseFirestore
                                        .instance
                                        .collection('orders')
                                        .doc(orderId)
                                        .get();

                                    if (orderDoc['is_received'] == true) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'You already received the order')));
                                      setState(() {
                                        _isReceived = true;
                                        _isLoading = false;
                                      });
                                      return;
                                    }

                                    final productInfo = {
                                      "product_order_status": "picked up",
                                    };
                                    final orderInfo = {
                                      "status": "picked up",
                                      "pick_up_date":
                                          Timestamp.fromDate(DateTime.now()),
                                      "is_received": true,
                                    };

                                    await FirebaseFirestore.instance
                                        .collection('products')
                                        .doc(productId)
                                        .update(productInfo);
                                    await FirebaseFirestore.instance
                                        .collection('orders')
                                        .doc(orderId)
                                        .update(orderInfo);

                                    showToastrMessage("Order Received");

                                    setState(() {
                                      _isReceived = true;
                                    });
                                  } catch (e) {
                                    showToastrMessage(
                                        "Failed to update order: $e");
                                  } finally {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Received'),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 20.h),
                _buildInfoCard(
                  title: 'Receiver Information',
                  children: [
                    _buildInfoRow(Icons.person, 'Name',
                        receiverInfo['receiver_name'] ?? 'N/A'),
                    _buildInfoRow(Icons.email, 'Email',
                        receiverInfo['receiver_email'] ?? 'N/A'),
                    _buildInfoRow(Icons.phone, 'Phone',
                        receiverInfo['receiver_phone_number'] ?? 'N/A'),
                    _buildInfoRow(Icons.location_on, 'Location',
                        receiverInfo['receiver_pick_up_location'] ?? 'N/A'),
                    SizedBox(height: 16.h),
                    if (_isReceived) // Show "Mark as Delivered" only if received
                      Align(
                        alignment: Alignment.center,
                        child: ElevatedButton(
                          onPressed: (_isMarkingDelivered || _isAwaitingAcknowledgment)
                              ? null
                              : () async {
                                  setState(() {
                                    _isMarkingDelivered = true;
                                  });

                                  final user = FirebaseAuth.instance.currentUser;
                                  if (user == null) {
                                    setState(() {
                                      _isMarkingDelivered = false;
                                    });
                                    return;
                                  }

                                  final orderId = activeOrderData.orderId;

                                  try {
                                    final orderDoc = await FirebaseFirestore
                                        .instance
                                        .collection('orders')
                                        .doc(orderId)
                                        .get();

                                    if (orderDoc['status'] ==
                                        "awaiting acknowledgment") {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Awaiting buyer acknowledgment.')));
                                      setState(() {
                                        _isMarkingDelivered = false;
                                        _isAwaitingAcknowledgment = true;
                                      });
                                      return;
                                    }

                                    await FirebaseFirestore.instance
                                        .collection('orders')
                                        .doc(orderId)
                                        .update({
                                      'status': 'awaiting acknowledgment',
                                      'delivered_date':
                                          Timestamp.fromDate(DateTime.now()),
                                    });

                                    // Listen for order status changes
                                    FirebaseFirestore.instance
                                        .collection('orders')
                                        .doc(orderId)
                                        .snapshots()
                                        .listen((documentSnapshot) {
                                      final status = documentSnapshot['status'];
                                      if (status == 'delivered') {
                                        FirebaseFirestore.instance
                                            .collection('delivery_captains')
                                            .doc(user.uid)
                                            .update({
                                          'active_order': FieldValue.delete()
                                        });

                                        activeOrderNotifier.value = null;

                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DeliverySuccessScreen(
                                                    orderId: orderId),
                                          ),
                                        );
                                      }
                                    });

                                    showLongToastrMessage(
                                        "Order marked as delivered. Awaiting buyer acknowledgment.",
                                        7);

                                    setState(() {
                                      _isAwaitingAcknowledgment = true;
                                    });
                                  } catch (e) {
                                    showToastrMessage(
                                        "Failed to mark as delivered: $e");
                                  } finally {
                                    setState(() {
                                      _isMarkingDelivered = false;
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                          ),
                          child: _isMarkingDelivered
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Mark as Delivered'),
                                    SizedBox(width: 8.w),
                                    SizedBox(
                                      width: 20.w,
                                      height: 20.h,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text('Mark as Delivered'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 10.h),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade800, size: 16.sp),
          SizedBox(width: 10.w),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}