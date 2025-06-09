import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_project/constants/colors.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: kPrimaryBlue,
      ),
      body: user == null
          ? const Center(child: Text('Please sign in to view your orders'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('orderDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No orders yet'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final order = snapshot.data!.docs[index];
                    final orderData = order.data() as Map<String, dynamic>;
                    final orderDate = (orderData['orderDate'] as Timestamp).toDate();

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ExpansionTile(
                        title: Text('Order #${order.id.substring(0, 8)}'),
                        subtitle: Text(
                          'Date: ${orderDate.day}/${orderDate.month}/${orderDate.year}',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Status: ${orderData['status'] ?? 'Pending'}'),
                                const SizedBox(height: 8),
                                Text('Total: ${orderData['total'] ?? 0} JOD'),
                                if (orderData['items'] != null) ...[
                                  const SizedBox(height: 8),
                                  const Text('Items:'),
                                  ...List<Widget>.from(
                                    (orderData['items'] as List).map(
                                      (item) => Padding(
                                        padding: const EdgeInsets.only(left: 16.0),
                                        child: Text('• ${item['name']} - ${item['price']} JOD'),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
} 