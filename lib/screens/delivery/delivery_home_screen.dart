import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_project/screens/delivery/active_order.dart';
import 'package:test_project/screens/delivery/delivery_personal_data.dart';
import 'package:test_project/screens/delivery/earning_summary.dart';
import 'package:test_project/screens/delivery/orders_summary.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DeliveryHomeScreen extends StatefulWidget {
  final Map<String, dynamic>? deliveryData;
  final String deliveryId;

  const DeliveryHomeScreen(this.deliveryId, {super.key, required this.deliveryData});

  @override
  State<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  int _page = 0;
  GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  // List of screens to display based on the selected index
  final List<Widget> _screens = [
    // Home Screen (index 0) - Fetch and display orders
   StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance.collection('orders').snapshots(),
  builder: (ctx, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Center(child: Text('No orders found.'));
    }

    final orders = snapshot.data!.docs;

    return Padding(
      padding: const EdgeInsets.only(top: 40.0), // Add space from the top
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        itemCount: orders.length,
        itemBuilder: (ctx, index) {
          final order = orders[index].data() as Map<String, dynamic>;
          final quantity = order['product_infos']['quantity'] ?? 0;
          final productId = order['product_infos']['product_id'];
          final sellerLocation = order['seller_location'];
          final receiverLocation = order['receiver_infos']['receiver_pick_up_location'];

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
            builder: (context, productSnapshot) {
              if (productSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (productSnapshot.hasError) {
                return Center(
                  child: Text('Error: ${productSnapshot.error}'),
                );
              }

              final productData = productSnapshot.data!.data() as Map<String, dynamic>;
              final categoryId = productData['categoryId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('categories').doc(categoryId).get(),
                builder: (context, productSnapshot) {
                  if (productSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (productSnapshot.hasError) {
                    return Center(
                      child: Text('Error: ${productSnapshot.error}'),
                    );
                  }

                  final categoryData = productSnapshot.data!.data() as Map<String, dynamic>;
                  final categoryName = categoryData['name'] ?? 'Null Category';

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade100,
                          Colors.blue.shade200,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location and Quantity
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  '$sellerLocation -> $receiverLocation',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'x$quantity',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Category and Icon
                          Row(
                            children: [
                              Image(
                                image: AssetImage(
                                  categoryName == 'Screens'
                                      ? 'assets/images/monitor.png'
                                      : categoryName == 'GPU'
                                          ? 'assets/images/gpu-mining.png'
                                          : categoryName == 'KeyBoard'
                                              ? 'assets/images/keyboard.png'
                                              : categoryName == 'CPU'
                                                  ? 'assets/images/cpu1.png'
                                                  : categoryName == 'mouse pad'
                                                      ? 'assets/images/mousepad.png'
                                                      : categoryName == 'Mouse'
                                                          ? 'assets/images/mouse.png'
                                                          : categoryName == "Table"
                                                              ? 'assets/images/standing-desk.png'
                                                              : categoryName == "Chair"
                                                                  ? 'assets/images/gaming-chair.png'
                                                                  : categoryName == "Fans"
                                                                      ? 'assets/images/fan.png'
                                                                      : categoryName == 'MotherBoard'
                                                                          ? 'assets/images/motherboard.png'
                                                                          : categoryName == "Headphones"
                                                                              ? 'assets/images/headphones.png'
                                                                              : categoryName == "Case"
                                                                                  ? 'assets/images/computer-case.png'
                                                                                  : categoryName == "RAM"
                                                                                      ? 'assets/images/ram.png'
                                                                                      : categoryName == "Memory"
                                                                                          ? 'assets/images/ssd-card.png'
                                                                                          : categoryName == "Power Supply"
                                                                                              ? 'assets/images/power-supply.png'
                                                                                              : 'assets/images/question-sign.png',
                                ),
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                categoryName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Delivery Icons and Take Button
                          Row(
                            children: [
                              const Icon(
                                FontAwesomeIcons.carSide,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 10),
                              if (categoryName == 'Mouse' ||
                                  categoryName == 'Keyboard' ||
                                  categoryName == 'GPU' ||
                                  categoryName == 'CPU' ||
                                  categoryName == 'Mouse Pad')
                                const Icon(
                                  Icons.delivery_dining,
                                  size: 25,
                                  color: Colors.white,
                                ),
                              const Spacer(),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: const Text(
                                  'Take',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  },
),
    OrdersSummary(), // OrdersSummary (index 1)
    EarningSummary(), // EarningSummary (index 2)
    ActiveOrder(), // ActiveOrder (index 3)
    DeliveryPersonalData(deliveryData: {}, deliveryId: ''), // Placeholder, will be replaced
  ];

  @override
  Widget build(BuildContext context) {
    // Update the DeliveryPersonalData screen with the correct deliveryData and deliveryId
    _screens[4] = DeliveryPersonalData(
      deliveryData: widget.deliveryData,
      deliveryId: widget.deliveryId,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_page], // Display the selected screen
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _page,
        height: 65.0,
        items: const [
          Icon(Icons.home, size: 30),
          Icon(Icons.delivery_dining, size: 30), // OrdersSummary (index 1)
          Icon(Icons.account_balance_wallet, size: 30), // EarningSummary (index 2)
          Icon(Icons.history, size: 30), // ActiveOrder (index 3)
          Icon(Icons.person, size: 30), // DeliveryPersonalData (index 4)
        ],
        color: const Color.fromARGB(255, 128, 171, 206),
        buttonBackgroundColor: const Color.fromARGB(255, 62, 157, 235),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 400),
        onTap: (index) {
          setState(() {
            _page = index.clamp(0, 4);
          });
        },
      ),
    );
  }
}