import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:test_project/screens/order/order_confirmation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class PreCheckout extends StatefulWidget {
  const PreCheckout({
    super.key,
    required this.productMainTitle,
    required this.productDescription,
    required this.totalAmount,
    required this.imageUrl,
    required this.productId,
    required this.sellerId,
    required this.quantity,
  });

  final String productMainTitle;
  final String productDescription;
  final String imageUrl;
  final double totalAmount;
  final String productId;
  final String sellerId;
  final int quantity;

  @override
  State<PreCheckout> createState() => _PreCheckoutState();
}

class _PreCheckoutState extends State<PreCheckout> {
  final user = FirebaseAuth.instance.currentUser;
  late TextEditingController userEmailController;
  late TextEditingController userFullNameController;
  late TextEditingController userPhoneNumberController;
  final _formkey = GlobalKey<FormState>();
  var _enteredEmail = '';
  var _enteredPhoneNumber = '';
  var _enteredFullName = '';

  // List of order statuses
  final List<String> orderStatus = [
    "pending",
    "delivered",
    "canceled",
    "picked up",
  ];

  // List of product statuses
  final List<String> paymentStatus = [
    "held",
    "released",
    "refunded",
  ];


  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();


  @override
  void initState() {
    super.initState();
    // Initialize controllers
    userEmailController = TextEditingController();
    userFullNameController = TextEditingController();
    userPhoneNumberController = TextEditingController();

    // Fetch user data and set initial values for controllers
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final userId = user!.uid;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userEmail = userDoc['email'];
    final userFullName = userDoc['name'];
    final userPhoneNumber = userDoc['phone_number'];

    // Set initial values for controllers
    setState(() {
      userEmailController.text = userEmail;
      userFullNameController.text = userFullName;
      userPhoneNumberController.text = userPhoneNumber;
    });
  }

  @override
  void dispose() {
    userEmailController.dispose();
    userFullNameController.dispose();
    userPhoneNumberController.dispose();
    super.dispose();
  }


   // Helper method to create a bullet point
Widget _buildBulletPoint(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• ',
          style: TextStyle(fontSize: 30),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          
        ),
      ],
    ),
  );
}

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


  Future<void> _confirmOrder() async {
  if (_formkey.currentState?.validate() != true) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please provide valid information')),
    );
    return;
  }

  try {

    // Cancel all notifications
    await flutterLocalNotificationsPlugin.cancelAll();

    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Save the form data
    _formkey.currentState?.save();

    // Update the product_order_status
    final productInfo = {
      "product_order_status": "It has been purchased",
    };

    await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .update(productInfo);

    // Save order information in Firestore
    final userId = user!.uid;
    final orderInfos = {
      "buyer_id": userId,
      "seller_id": widget.sellerId,
      "product_infos": {
        "product_id": widget.productId,
        "quantity": widget.quantity,
        "image_url": widget.imageUrl,
        "total_amount": _orderTotal(widget.totalAmount),
      },
      'status': orderStatus[0],
      "delivery_person_id": '9IWiv0gCv1Y60CRwjwGqYsuGTtr2',
      "receiver_infos": {
        "receiver_name": _enteredFullName,
        "receiver_email": _enteredEmail,
        "receiver_phone_number": _enteredPhoneNumber,
      },
      "payment_status": paymentStatus[0],
      "timestamp": Timestamp.fromDate(DateTime.now()),
    };
    final docRef = FirebaseFirestore.instance.collection("orders").doc();
    await docRef.set(orderInfos);

    // Close loading indicator
    Navigator.pop(context);

    showToastrMessage("Your order has been placed successfully.");

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (ctx) => const OrderConfirmation(),
      ),
    );
  } catch (e) {
    Navigator.pop(context); // Close loading indicator if an error occurs
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Something went wrong: $e')),
    );
  }
}


  double _orderTotal(double productPrice)
  {
    var DeliveryFee = 3;
    var ServiceFee = 0.35;
    productPrice = (productPrice + DeliveryFee + ServiceFee);
    return productPrice;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set the background color of the page
      backgroundColor: const Color.fromARGB(255, 153, 191, 216),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            // Add padding around the card to make it look better
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  // Set the background color of the card to white
                  color: Colors.white,
                  // Add elevation to create a shadow behind the card
                  elevation: 5,
                  // Add border radius to the card
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // "Order Detail" text with bottom border
                        Container(
                          alignment: Alignment.centerLeft,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey, // Border color
                                width: 1.0, // Border width
                              ),
                            ),
                          ),
                          child: const Text(
                            'Order Detail',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Product image and details row
                        Row(
                          children: [
                            Image.network(
                              widget.imageUrl,
                              height: 90,
                              width: 90,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.productMainTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.productDescription,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                            Row(
                              children: [
                                Text('Product price: ${widget.totalAmount}'),
                                const Spacer(),
                                Text('Quantity: ${widget.quantity}'),
                              ],
                            ),
                            const SizedBox(height: 5,),

                            const Divider(),

                            const SizedBox(height: 16,),

                           const Row(
                              children: [
                                 Text('Delivery fee'),
                                 Spacer(),
                                 Text('3 JOD'),
                              ],
                            ),
                            const SizedBox(height: 8,),

                            const Row(
                              children: [
                                 Text('Service fee'),
                                 Spacer(),
                                 Text('0.35 JOD'),
                              ],
                            ),
                            const SizedBox(height: 8,),
                             Row(
                              children: [
                                 const Text('Order Total(incl. tax)',style: 
                                 TextStyle(fontWeight: FontWeight.bold),),
                                 const Spacer(),
                                 Text('${_orderTotal(widget.totalAmount).toString()} JOD'),
                              ],
                            ),
                            const SizedBox(height: 8,),

  
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  // Set the background color of the card to white
                  color: Colors.white,
                  // Add elevation to create a shadow behind the card
                  elevation: 5,
                  // Add border radius to the card
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formkey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // "Order Header" text with bottom border
                          Container(
                            alignment: Alignment.centerLeft,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey, // Border color
                                  width: 1.0, // Border width
                                ),
                              ),
                            ),
                            child: const Text(
                              'Order Header',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 0),
          
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBulletPoint("Enter the recipient's information"),
                            ],
                          ),
                          const SizedBox(height: 0,),
                          // Email TextFormField
                          TextFormField(
                            controller: userEmailController,
                            decoration: const InputDecoration(labelText: 'Email Address'),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty ||
                                    !value.contains('@')) {
                                  return 'Please enter a valid email address.';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredEmail = value!;
                              },
                          ),
                          const SizedBox(height: 16),
                          // Full Name TextFormField
                          TextFormField(
                            controller: userFullNameController,
                            decoration: const InputDecoration(labelText: 'Full Name'),
                            keyboardType: TextInputType.name,
                             validator: (value) {
                                if (value == null ||value.trim().isEmpty ||value.contains('@') || value.contains('_') || value.contains('-') || value.trim().length<=2) {
                                  return 'Please enter a valid name.';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredFullName = value!;
                              },
                          ),
                          const SizedBox(height: 16),
                          // Phone Number TextFormField
                          TextFormField(
                            controller: userPhoneNumberController,
                            decoration: const InputDecoration(labelText: 'Phone Number'),
                            keyboardType: TextInputType.phone,
                             validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Phone number is required.';
                                  }
                                  if (value.trim().length <= 9) {
                                    return 'Phone number must be max 10 characters.';
                                  }
                                  if(value.trim().length != 10 && value.trim().length != 13)
                                  {
                                    return 'Phone number must be 10 characters or starting with +962';
                                  }
                                  if (!value.startsWith('077') && !value.startsWith('078') && !value.startsWith('079') && !value.startsWith('+96277') && !value.startsWith('+96278') && !value.startsWith('+96279')) {
                                    return 'Phone number must be "077" or "078" or "079" or "+962" .';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  _enteredPhoneNumber = value!;
                                },
                          ),

                          const SizedBox(height: 22,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Back Button
                              Flexible(
                                flex: 3, // 3 parts of the available space
                                child: SizedBox(
                                  width: double.infinity, // Take full width of the Flexible
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.yellow[800],
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center, // Center contents horizontally
                                        children: [
                                          Icon(Icons.arrow_back_ios_new, color: Colors.white),
                                          SizedBox(width: 6),
                                          Text('Back'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16), // Add spacing between buttons
                              // Checkout Button
                              Flexible(
                                flex: 3, // 3 parts of the available space
                                child: SizedBox(
                                  width: double.infinity, // Take full width of the Flexible
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _confirmOrder();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center, // Center contents horizontally
                                        children: [
                                          Icon(Icons.check_circle_outline, color: Colors.white),
                                          SizedBox(width: 6),
                                          Text('Checkout'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}