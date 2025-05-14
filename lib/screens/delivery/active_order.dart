import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:test_project/active_order_data.dart';
import 'package:test_project/screens/delivery/delivery_success_screen.dart'; // Replace with the actual path
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ActiveOrder extends StatefulWidget {
  const ActiveOrder({super.key});

  @override
  State<ActiveOrder> createState() => _ActiveOrderState();
}

class _ActiveOrderState extends State<ActiveOrder> {
  bool _isLoading = false;
  bool _isReceived = false; // Track whether the order has been received
   bool _isMarkingDelivered = false;

  @override
  void initState() {
    super.initState();
    _checkIfReceived(); // Check Firestore for the "is_received" status on app startup
  }

  // Check Firestore to see if the order has been received
  Future<void> _checkIfReceived() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final orderDoc = await FirebaseFirestore.instance
        .collection('orders')
        .where('delivery_person_id', isEqualTo: user.uid)
        .get();

    if (orderDoc.docs.isNotEmpty) {
      final orderData = orderDoc.docs.first.data();
      setState(() {
        _isReceived = orderData['is_received'] ?? false;
      });
    }
  }

  void showToastrMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: const Color.fromARGB(255, 106, 179, 116),
      textColor: const Color.fromARGB(255, 255, 255, 255),
      fontSize: 16.0.sp,
    );
  }

   void showLongToastrMessage(String message, int durationInSeconds) {
  int repeatCount = (durationInSeconds / 3.5).ceil(); // Repeat count
  for (int i = 0; i < repeatCount; i++) {
    Future.delayed(Duration(milliseconds: i * 3500), () {
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: const Color.fromARGB(255, 106, 179, 116),
        textColor: const Color.fromARGB(255, 255, 255, 255),
        fontSize: 16.0.sp,
      );
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        centerTitle: true,
      ),
      body: ValueListenableBuilder<ActiveOrderData?>(
        valueListenable: activeOrderNotifier,
        builder: (context, activeOrderData, child) {
          if (activeOrderData == null) {
            return  Center(
              child: Text(
                'No active order found.',
                style: TextStyle(fontSize: 18.sp, color: Colors.grey),
              ),
            );
          }

          final order = activeOrderData.orderData;
          final product = activeOrderData.productData;
          final receiverInfo = order['receiver_infos'];
          final sellerInfo = product['seller_ifos'];

          // Format the timestamp to display only year, month, and day
          final formattedDate = DateFormat('yyyy-MM-dd').format(
            DateTime.fromMillisecondsSinceEpoch(order['timestamp'].seconds * 1000),
          );

          // Check if acceptance_date is null
          final acceptanceDate = order['acceptance_date'];
          final formattedAcceptanceDate = acceptanceDate != null
              ? DateFormat('MMM d, h:mm a').format((acceptanceDate as Timestamp).toDate())
              : 'Not available'; // Placeholder for null acceptance_date

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
                      Lottie.network('https://lottie.host/7c708d27-0d79-49c8-b28e-7bcc472bfa40/mpqzewoGEO.json'),
                    ],
                  ),
                  ),


                // Order Information Card
                _buildInfoCard(
                  title: 'Order Information',
                  children: [
                    _buildInfoRow(Icons.receipt, 'Order ID', activeOrderData.orderId),
                    _buildInfoRow(Icons.category, 'Category', activeOrderData.categoryName),
                    _buildInfoRow(Icons.shopping_cart, 'Quantity', order['product_infos']['quantity'].toString()),
                    _buildInfoRow(Icons.calendar_today, 'Order Date', formattedDate),
                    _buildInfoRow(Icons.event_available, 'Acceptance Date', formattedAcceptanceDate),
                  ],
                ),
                const SizedBox(height: 20),

                // Seller Information Card
                _buildInfoCard(
                  title: 'Seller Information',
                  children: [
                    _buildInfoRow(Icons.person, 'Name', sellerInfo['seller_name']),
                    _buildInfoRow(Icons.email, 'Email', sellerInfo['seller_email']),
                    _buildInfoRow(Icons.phone, 'Phone', sellerInfo['seller_phone_number']),
                    _buildInfoRow(Icons.location_on, 'Location', sellerInfo['seller_pick_up_location']),
                    const SizedBox(height: 16),
                    if (!_isReceived) // Show "Received" button only if not already received
                      Align(
                        alignment: Alignment.center,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null // Disable the button when loading
                              : () async {
                                  setState(() {
                                    _isLoading = true; // Start loading
                                  });

                                  try {
                                    final user = FirebaseAuth.instance.currentUser;
                                    final orderDoc = await FirebaseFirestore.instance
                                        .collection('orders')
                                        .where('delivery_person_id', isEqualTo: user!.uid)
                                        .get();
                                    
                                    final orderDocument = orderDoc.docs.first;
                                    if(orderDocument['is_received'] == true)
                                    {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You already received the order')));
                                    }
                                    final orderId = orderDocument.id;
                                    final productId = orderDocument['product_infos']['product_id'];
                                    final productInfo = {
                                      "product_order_status": "picked up",
                                    };

                                    final orderInfo = {
                                      "status": "picked up",
                                      "pick_up_date": Timestamp.fromDate(DateTime.now()),
                                      "is_received": true, // Update the "is_received" field
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
                                      _isReceived = true; // Update local state
                                    });
                                  } catch (e) {
                                    showToastrMessage("Failed to update order: $e");
                                  } finally {
                                    setState(() {
                                      _isLoading = false; // Stop loading
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                          ),
                          child: _isLoading
                              ?  SizedBox(
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
                const SizedBox(height: 20),

                // Receiver Information Card
                _buildInfoCard(
                  title: 'Receiver Information',
                  children: [
                    _buildInfoRow(Icons.person, 'Name', receiverInfo['receiver_name']),
                    _buildInfoRow(Icons.email, 'Email', receiverInfo['receiver_email']),
                    _buildInfoRow(Icons.phone, 'Phone', receiverInfo['receiver_phone_number']),
                    _buildInfoRow(Icons.location_on, 'Location', receiverInfo['receiver_pick_up_location']),
                    const SizedBox(height: 16),
                    if (_isReceived) // Show "Mark as Delivered" button only if received
                     Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: _isMarkingDelivered
                            ? null // Disable the button while waiting
                            : () async {
                                setState(() {
                                  _isMarkingDelivered = true; // Show loading spinner
                                });

                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) return;

                                final orderDoc = await FirebaseFirestore.instance
                                    .collection('orders')
                                    .where('delivery_person_id', isEqualTo: user.uid)
                                    .get();

                                final orderDocument = orderDoc.docs.first;
                                final orderId = orderDocument.id;

                                if (orderDocument['status'] == "awaiting acknowledgment") {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text('Awaiting buyer acknowledgment.'),
                                  ));
                                  return;
                                }

                                // Update the order status to "awaiting acknowledgment"
                                await FirebaseFirestore.instance
                                    .collection('orders')
                                    .doc(orderId)
                                    .update({
                                      'status': 'awaiting acknowledgment',
                                      'delivered_date': Timestamp.fromDate(DateTime.now()),
                                    });

                                // Listen for real-time updates to the order status
                                FirebaseFirestore.instance
                                    .collection('orders')
                                    .doc(orderId)
                                    .snapshots()
                                    .listen((documentSnapshot) {
                                  final status = documentSnapshot['status'];
                                  if (status == 'delivered') {
                                    // Clear the active order data from Firestore
                                    FirebaseFirestore.instance
                                        .collection('delivery_captains')
                                        .doc(user.uid)
                                        .update({'active_order': FieldValue.delete()});

                                    // Clear the ValueNotifier
                                    activeOrderNotifier.value = null;

                                    // Navigate to the success screen
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => const DeliverySuccessScreen(),
                                      ),
                                    );
                                  }
                                });

                                showLongToastrMessage(
                                    "Order marked as delivered. Awaiting buyer acknowledgment.", 7);
                              },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                        ),
                        child: _isMarkingDelivered
                            ?  Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                   Text('Mark as Delivered'),
                                   SizedBox(width: 8.w), // Add spacing between text and spinner
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

  // Helper method to build an info card
  Widget _buildInfoCard({required String title, required List<Widget> children}) {
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
              style:  TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  // Helper method to build an info row with an icon
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade800, size: 16),
           SizedBox(width: 10.w),
          Text(
            '$label: ',
            style:  TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style:  TextStyle(
              fontSize: 14.sp,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}