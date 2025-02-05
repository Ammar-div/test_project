import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_project/screens/HomeScreen.dart';
import 'package:test_project/screens/order/order_status_screen.dart';

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
      appBar: AppBar(
        title: const Text('Your Orders'),
         leading: IconButton(
           icon: const Icon(Icons.arrow_back),
            onPressed: () {
               Navigator.pushReplacement( context, MaterialPageRoute(builder: (context) => const HomeScreen()),
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
              return const Center(
                child: Text('No Orders Found, Try adding one'),
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
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: 
                            (ctx) => OrderStatusScreen(
                              imageUrls : productImageUrls,
                              mainTitle : productMainTitle,
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
                            ),
                          )
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            color: Colors.grey, // Border color
                            width: 2, // Border width
                          ),
                          borderRadius: BorderRadius.circular(8.0), // Border radius
                        ),
                        child: ListTile(
                          leading: Image.network(
                            imageUrl,
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                          ),
                          title: Row(
                            children: [
                              // Constrain the productMainTitle to take up half of the available space
                              Flexible(
                                flex: 1, // Takes 1 part of the available space
                                child: Text(
                                  productMainTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                  maxLines: 1, // Limit to one line
                                  overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
                                ),
                              ),
                              const Spacer(), // Takes up remaining space
                              Text('x${quantity.toString()}'),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productDescription,
                                style: const TextStyle(fontWeight: FontWeight.bold),
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


// Card(
//                     margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundImage: imageUrl != null && imageUrl.isNotEmpty
//                             ? NetworkImage(imageUrl)
//                             : const AssetImage('assets/images/default_avatar.avif') as ImageProvider,
//                       ),
//                       title: Row(
//                         children: [
//                           Text(
//                             username,
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           const Spacer(),
//                           Text(
//                             roleDisplayed,
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                         ],
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Email: $email',
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           Text(
//                             'Phone: $phoneNumber',
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           Row(
//                             children: [
//                               Text(
//                                 'Name: $fullName',
//                                 style: const TextStyle(fontWeight: FontWeight.bold),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),