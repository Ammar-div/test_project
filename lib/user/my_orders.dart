import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_project/screens/HomeScreen.dart';
import 'package:test_project/screens/order/order_status_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_project/constants/colors.dart';

class MyOrders extends StatefulWidget {
  const MyOrders({super.key, required this.userId});

  final String userId;
  @override
  State<MyOrders> createState() => _MyOrdersState();
}

class _MyOrdersState extends State<MyOrders> {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundGrey,
      appBar: AppBar(
        backgroundColor: kPrimaryBlue,
        title: Text('Your Orders', style: TextStyle(color: kWhite)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kWhite),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('orders')
              .where('buyer_id', isEqualTo: widget.userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'No Orders Found, Try adding one',
                  style: TextStyle(fontSize: 11.r, color: kPrimaryBlue),
                ),
              );
            }

            final orders = snapshot.data!.docs;

            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (ctx, index) {
                final orderDoc = orders[index];
                final imageUrl = orderDoc['product_infos']['image_url'];
                final orderStatus = orderDoc['status'];
                final productIdInOrders = orderDoc['product_infos']['product_id'];
                final quantity = orderDoc['product_infos']['quantity'];
                final productTotalAmount = orderDoc['product_infos.total_amount'];
                final receiverEmail = orderDoc['receiver_infos.receiver_email'];
                final receiverName = orderDoc['receiver_infos']['receiver_name'];
                final receiverPhoneNumber = orderDoc['receiver_infos.receiver_phone_number'];
                final paymentStatus = orderDoc['payment_status'];
                final orderedDate = orderDoc['timestamp'];
                final receiverPickUpLocation = orderDoc['receiver_infos']['receiver_pick_up_location'];
                final orderID = orders[index].id;


                return FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('products').doc(productIdInOrders).get(),
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

                    if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
                      return const Center(
                        child: Text('Product not found'),
                      );
                    }

                    final productData = productSnapshot.data!.data() as Map<String, dynamic>;
                    final productMainTitle = productData['name'];
                    final productDescription = productData['description'];
                    final productImageUrls = List<String>.from(productData['imageUrls']);
                    final productStatus = productData['status'];
                    final howMuchUsed = productData['how_much_used']?? "None";

                    return InkWell(
                      onTap: () async {
                      final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderID).get();
                      final deliveryID = orderDoc['delivery_person_id'];

                      if (deliveryID != null) {
                        final deliveryDoc = await FirebaseFirestore.instance.collection('delivery').doc(deliveryID).get();
                        final deliveryInfos = deliveryDoc.data();

                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (ctx) => OrderStatusScreen(
                            imageUrls: productImageUrls,
                            mainTitle: productMainTitle,
                            description: productDescription,
                            totalAmount: productTotalAmount,
                            quantity: quantity,
                            productStatus: productStatus,
                            howMuchUsed: howMuchUsed,
                            receiverEmail: receiverEmail,
                            receiverName: receiverName,
                            receiverPhoneNumber: receiverPhoneNumber,
                            orderStatus: orderStatus,
                            paymentStatus: paymentStatus,
                            timestamp: orderedDate,
                            receiverPickUpLocation: receiverPickUpLocation,
                            orderID : orderID,
                            deliveryInfos: deliveryInfos!, // Only passed when not null
                          ),
                        ));
                      } else {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (ctx) => OrderStatusScreen(
                            imageUrls: productImageUrls,
                            mainTitle: productMainTitle,
                            description: productDescription,
                            totalAmount: productTotalAmount,
                            quantity: quantity,
                            productStatus: productStatus,
                            howMuchUsed: howMuchUsed,
                            receiverEmail: receiverEmail,
                            receiverName: receiverName,
                            receiverPhoneNumber: receiverPhoneNumber,
                            orderStatus: orderStatus,
                            paymentStatus: paymentStatus,
                            timestamp: orderedDate,
                            receiverPickUpLocation: receiverPickUpLocation,
                             orderID : orderID,
                            // deliveryInfos is NOT passed here
                          ),
                        ));
                      }
                    },
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: kPrimaryBlue,
                            width: 2.w,
                          ),
                          borderRadius: BorderRadius.circular(8.0.r),
                        ),
                        child: ListTile(
                          leading: Image.network(
                            imageUrl,
                            height: 60.h,
                            width: 60.w,
                            fit: BoxFit.cover,
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                flex: 1,
                                child: Text(
                                  productMainTitle,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20.r,
                                    color: kPrimaryBlue,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'x${quantity.toString()}',
                                style: TextStyle(color: kPrimaryBlue),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productDescription,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryBlue,
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
