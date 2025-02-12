import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class DeliveryOrderDetails extends StatefulWidget {
  final String categoryName;
  final Map<String, dynamic> orderData;
  final Map<String, dynamic> productData;
  final String orderId;

  const DeliveryOrderDetails({
    super.key,
    required this.categoryName,
    required this.orderData,
    required this.productData,
    required this.orderId,
  });

  @override
  State<DeliveryOrderDetails> createState() => _DeliveryOrderDetailsState();
}

class _DeliveryOrderDetailsState extends State<DeliveryOrderDetails> {
  @override
  Widget build(BuildContext context) {
    final order = widget.orderData;
    final product = widget.productData;
    final receiverInfo = order['receiver_infos'];
    final sellerInfo = product['seller_ifos'];

    // Format the timestamp to display only year, month, and day
    final formattedDate = DateFormat('yyyy-MM-dd').format(
      DateTime.fromMillisecondsSinceEpoch(order['timestamp'].seconds * 1000),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Order Information Card
            _buildInfoCard(
              title: 'Order Information',
              children: [
                _buildInfoRow(Icons.receipt, 'Order ID', widget.orderId),
                _buildInfoRow(Icons.category, 'Category', widget.categoryName),
                _buildInfoRow(Icons.shopping_cart, 'Quantity', order['product_infos']['quantity'].toString()),
                _buildInfoRow(Icons.calendar_today, 'Order Date', formattedDate),
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
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add action for marking the order as delivered
        },
        backgroundColor: Colors.blue.shade800,
        child: const Icon(Icons.done, color: Colors.white),
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