import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:test_project/active_order_data.dart';
import 'package:test_project/screens/delivery/active_order.dart';
import 'package:test_project/screens/delivery/active_order.dart';
import 'package:test_project/screens/delivery/delivery_personal_data.dart';
import 'package:test_project/screens/delivery/earning_summary.dart';
import 'package:test_project/screens/delivery/orders_summary.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_project/constants/colors.dart';

class DeliveryHomeScreen extends StatefulWidget {
  final Map<String, dynamic>? deliveryData;
  final String deliveryId;

  const DeliveryHomeScreen(this.deliveryId,
      {super.key, required this.deliveryData});

  @override
  State<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  final GlobalKey _loadingKey = GlobalKey();

  void showToastrMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: kPrimaryBlue,
      textColor: kWhite,
      fontSize: 16.0.sp,
    );
  }

  int _page = 0;
  GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  Stream? ordersList;
  late List<Widget> _screens; // Declare _screens as a late variable

  @override
  void initState() {
    super.initState();
    _refreshOrders(); // Initialize the orders list
    _initializeScreens(); // Initialize the _screens list
    _fetchActiveOrder(); // Fetch the active order data
  }

  Future<void> _fetchActiveOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('delivery_captains')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final activeOrder = doc.data()!['active_order'] as Map<String, dynamic>;
      activeOrderNotifier.value = ActiveOrderData(
        categoryName: activeOrder['categoryName'],
        orderData: activeOrder['orderData'],
        productData: activeOrder['productData'],
        orderId: activeOrder['orderId'],
        productId: activeOrder['productId'],
      );
    }
  }

  Future<void> _refreshOrders() async {
    setState(() {
      ordersList = FirebaseFirestore.instance
          .collection('orders')
          .orderBy('timestamp', descending: false)
          .snapshots();
    });
  }

  void _initializeScreens() {
    _screens = [
      // Home Screen (index 0) - Fetch and display orders
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('delivery_person_id',
                isNull:
                    true) // Only fetch orders where delivery_person_id is null
            .snapshots(),
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

          return RefreshIndicator(
            onRefresh: () async {
              await _refreshOrders(); // Refresh the orders list
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              itemCount: orders.length,
              itemBuilder: (ctx, index) {
                final order = orders[index].data() as Map<String, dynamic>;
                final quantity = order['product_infos']['quantity'] ?? 0;
                final productId = order['product_infos']['product_id'];
                final sellerLocation = order['seller_location'];
                final receiverLocation =
                    order['receiver_infos']['receiver_pick_up_location'];

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('products')
                      .doc(productId)
                      .get(),
                  builder: (context, productSnapshot) {
                    if (productSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (productSnapshot.hasError) {
                      return Center(
                        child: Text('Error: ${productSnapshot.error}'),
                      );
                    }

                    final productData =
                        productSnapshot.data!.data() as Map<String, dynamic>;
                    final categoryId = productData['categoryId'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('categories')
                          .doc(categoryId)
                          .get(),
                      builder: (context, productSnapshot) {
                        if (productSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (productSnapshot.hasError) {
                          return Center(
                            child: Text('Error: ${productSnapshot.error}'),
                          );
                        }

                        final categoryData = productSnapshot.data!.data()
                            as Map<String, dynamic>;
                        final categoryName =
                            categoryData['name'] ?? 'Null Category';

                        return Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                kPrimaryBlue.withOpacity(0.1),
                                kPrimaryBlue.withOpacity(0.2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16.r),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '$sellerLocation -> $receiverLocation',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18.sp,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                      ),
                                      child: Text(
                                        'x$quantity',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.sp,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),

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
                                                        : categoryName ==
                                                                'mouse pad'
                                                            ? 'assets/images/mousepad.png'
                                                            : categoryName ==
                                                                    'Mouse'
                                                                ? 'assets/images/mouse.png'
                                                                : categoryName ==
                                                                        "Table"
                                                                    ? 'assets/images/standing-desk.png'
                                                                    : categoryName ==
                                                                            "Chair"
                                                                        ? 'assets/images/gaming-chair.png'
                                                                        : categoryName ==
                                                                                "Fans"
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
                                      width: 24.w,
                                      height: 24.h,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      categoryName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),

                                // Delivery Icons and Take Button
                                Row(
                                  children: [
                                    const Icon(
                                      FontAwesomeIcons.carSide,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 10.w),
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
                                      onPressed: () async {
                                        try {
                                          final orderDoc =
                                              await FirebaseFirestore.instance
                                                  .collection('orders')
                                                  .doc(orders[index].id)
                                                  .get();
                                          final deliveryID =
                                              orderDoc['delivery_person_id'];

                                          if (deliveryID != null) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'The order has been taken.')));
                                            return;
                                          }

                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) => WillPopScope(
                                              onWillPop: () async =>
                                                  false, // Prevent dialog from being dismissed
                                              child: Center(
                                                key:
                                                    _loadingKey, // Use the GlobalKey
                                                child:
                                                    const CircularProgressIndicator(
                                                  color: Color.fromARGB(
                                                      255, 158, 203, 214),
                                                ),
                                              ),
                                            ),
                                          );

                                          final user =
                                              FirebaseAuth.instance.currentUser;
                                          final acceptanceDate = DateTime
                                              .now(); // Get the current date and time
                                          final orderInfo = {
                                            "status": "confirmed",
                                            "delivery_person_id": user!.uid,
                                            "acceptance_date": Timestamp.fromDate(
                                                acceptanceDate), // Convert DateTime to Timestamp
                                          };

                                          // Extract productId from the order data
                                          final orderData = orders[index].data()
                                              as Map<String, dynamic>;
                                          final productId = orderData[
                                                  'product_infos'][
                                              'product_id']; // Ensure this is the correct path

                                          final productInfo = {
                                            "product_order_status": "confirmed",
                                          };

                                          // Update Firestore documents
                                          await FirebaseFirestore.instance
                                              .collection('products')
                                              .doc(productId)
                                              .update(productInfo);
                                          await FirebaseFirestore.instance
                                              .collection('orders')
                                              .doc(orders[index].id)
                                              .update(orderInfo);

                                          // Store the active order data in Firestore for the delivery captain
                                          await FirebaseFirestore.instance
                                              .collection('delivery_captains')
                                              .doc(user.uid)
                                              .set({
                                            'active_order': {
                                              'categoryName':
                                                  categoryData['name'] ??
                                                      'Null Category',
                                              'orderData': {
                                                ...orderData, // Include all order data
                                                'acceptance_date':
                                                    Timestamp.fromDate(
                                                        acceptanceDate), // Convert DateTime to Timestamp
                                              },
                                              'productData': productData,
                                              'orderId': orders[index].id,
                                              'productId': productId,
                                            },
                                          });

                                          // Close loading indicator
                                          if (_loadingKey.currentContext !=
                                              null) {
                                            Navigator.of(
                                                    _loadingKey.currentContext!)
                                                .pop();
                                          }

                                          showToastrMessage(
                                              "You have taken the order, good luck!");

                                          // Update the ValueNotifier with the active order data
                                          activeOrderNotifier.value =
                                              ActiveOrderData(
                                            categoryName:
                                                categoryData['name'] ??
                                                    'Null Category',
                                            orderData: {
                                              ...orderData, // Include all order data
                                              'acceptance_date': Timestamp.fromDate(
                                                  acceptanceDate), // Convert DateTime to Timestamp
                                            },
                                            productData: productData,
                                            orderId: orders[index].id,
                                            productId: productId,
                                          );

                                          // Navigate to the ActiveOrder screen only if the widget is still mounted
                                          if (mounted) {
                                            setState(() {
                                              _page =
                                                  3; // Assuming ActiveOrder is at index 3
                                            });
                                          }
                                        } catch (e) {
                                          // Close loading indicator in case of error
                                          if (_loadingKey.currentContext !=
                                              null) {
                                            Navigator.of(
                                                    _loadingKey.currentContext!)
                                                .pop();
                                          }
                                          showToastrMessage(
                                              "An error occurred: $e");
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
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
      const ActiveOrder(), // ActiveOrder (index 3)
      DeliveryPersonalData(
          deliveryData: {}, deliveryId: ''), // Placeholder, will be replaced
    ];
  }

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
        height: 60.0,
        items: <Widget>[
          Icon(Icons.home, size: 30, color: kWhite),
          Icon(Icons.history, size: 30, color: kWhite),
          Icon(Icons.attach_money, size: 30, color: kWhite),
          Icon(Icons.person, size: 30, color: kWhite),
        ],
        color: kPrimaryBlue,
        buttonBackgroundColor: kPrimaryBlue,
        backgroundColor: kBackgroundGrey,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 600),
        onTap: (index) {
          setState(() {
            _page = index;
          });
        },
      ),
    );
  }
}
