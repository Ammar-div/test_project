import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';


// Assuming you have a ValueNotifier defined elsewhere in your app
import 'package:test_project/active_order_data.dart'; // Replace with the actual path

class ActiveOrder extends StatefulWidget {
  const ActiveOrder({super.key});

  @override
  State<ActiveOrder> createState() => _ActiveOrderState();
}

class _ActiveOrderState extends State<ActiveOrder> {

  bool _isPressed = false;
   bool _isLoading = false;


  void showToastrMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: const Color.fromARGB(255, 106, 179, 116),
      textColor: const Color.fromARGB(255, 255, 255, 255),
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        centerTitle: true,
      ),
      body: ValueListenableBuilder<ActiveOrderData?>(
        valueListenable: activeOrderNotifier,
        builder: (context, activeOrderData, child) {
          if (activeOrderData == null) {
            return const Center(
              child: Text(
                'No active order found.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
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
                const SizedBox(height: 16),

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
                    if(!_isPressed)
                    const SizedBox(height: 16),
                   if (!_isPressed)
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
                                  final orderId = orderDocument.id;
                                  final productId = orderDocument['product_infos']['product_id'];
                                  final productInfo = {
                                    "product_order_status": "picked up",
                                  };

                                  final orderInfo = {
                                    "status": "picked up",
                                    "pick_up_date": Timestamp.fromDate(DateTime.now()),
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
                                    _isPressed = true;
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
                            ? const SizedBox(
                                width: 20,
                                height: 20,
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
                    if(_isPressed)
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;
                      
                          // Clear the active order data from Firestore
                          await FirebaseFirestore.instance
                              .collection('delivery_captains')
                              .doc(user.uid)
                              .update({'active_order': FieldValue.delete()});
                      
                          // Clear the ValueNotifier
                          activeOrderNotifier.value = null;
                      
                          showToastrMessage("Order marked as completed.");
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Mark as Completed'),
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
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
          Icon(icon, color: Colors.blue.shade800, size: 20),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}