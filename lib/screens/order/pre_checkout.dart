import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:test_project/screens/order/order_confirmation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:test_project/widgets/keys.dart';

final List<String> pickUpLocation = [
  "Al Yasmin",
  "Nazzal",
  "Al Moqabalain",
  "Al Abdali",
  "Al Shmesani",
  "Jabal Amman",
  "Jabal Al Hadid",
  "Jabal Al Husain",
  "Al Akhdar",
  "Al Quesmeh",
  "Abdoun",
  "Tla'a Al Ali",
  "Wadi Al Saer",
  "Abu Nussair",
  "Al Muhagerein",
  "Al Mouaqar",
  "Wast Al Balad",
  "Al Wehdat",
  "Naour",
  "Ras Al Ein",
  "Marka",
  "Marg Al Hamam",
  "Sahab",
  "Shafa Badran",
  "Soualih",
  "Al Madina Al Riadiah",
  "Al Madina Al Tibiah",
  "Tabarbor",
];

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

  String? _selectedPickUpLocation;
  late TextEditingController searchController;
  List<String> filteredPickUpLocations = [];
  Map<String, dynamic>? IntentPaymentData;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    userEmailController = TextEditingController();
    userFullNameController = TextEditingController();
    userPhoneNumberController = TextEditingController();
    searchController = TextEditingController();
    filteredPickUpLocations = pickUpLocation;
    fetchUserData();
  }

  @override
  void dispose() {
    userEmailController.dispose();
    userFullNameController.dispose();
    userPhoneNumberController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    final userId = user!.uid;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userEmail = userDoc['email'];
    final userFullName = userDoc['name'];
    final userPhoneNumber = userDoc['phone_number'];

    setState(() {
      userEmailController.text = userEmail;
      userFullNameController.text = userFullName;
      userPhoneNumberController.text = userPhoneNumber;
    });
  }

  void _filterLocations(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredPickUpLocations = List.from(pickUpLocation);
      } else {
        filteredPickUpLocations = pickUpLocation
            .where((location) =>
                location.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _showSearchableDropdown(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Pick Up Location'),
              content: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search for a location...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (query) {
                        setState(() {
                          _filterLocations(query);
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredPickUpLocations.length,
                        itemBuilder: (context, index) {
                          final location = filteredPickUpLocations[index];
                          return ListTile(
                            title: Text(location),
                            onTap: () {
                              this.setState(() {
                                _selectedPickUpLocation = location;
                              });
                              setState(() {
                                searchController.clear();
                                filteredPickUpLocations = List.from(pickUpLocation);
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> showPaymentSheet() async {
    try {
      await stripe.Stripe.instance.presentPaymentSheet().then((val) {
        IntentPaymentData = null;
        // Navigate to OrderConfirmation after successful payment
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => const OrderConfirmation(),
          ),
        );
      }).onError((errorMsg, sTrace) {
        if (kDebugMode) {
          print(errorMsg.toString() + sTrace.toString());
        }
      });
    } on stripe.StripeException catch (error) {
      if (kDebugMode) {
        print(error);
      }
      showDialog(
        context: context,
        builder: (c) => const AlertDialog(
          content: Text('Cancelled'),
        ),
      );
    } catch (errorMsg) {
      if (kDebugMode) {
        print(errorMsg);
      }
      print(errorMsg.toString());
    }
  }

Future<Map<String, dynamic>> MakeIntentForPayment(String amountToBeCharge, String currency) async {
  try {
    // Convert the amount to a double, multiply by 100, and then convert to an integer
    int amountInCents = (double.parse(amountToBeCharge) * 100).round();

    Map<String, dynamic> paymentInfo = {
      "amount": amountInCents.toString(), // Use the integer value in cents
      "currency": currency,
      "payment_method_types[]": "card",
    };

    var responseFromStripeAPI = await http.post(
      Uri.parse("https://api.stripe.com/v1/payment_intents"),
      body: paymentInfo,
      headers: {
        "Authorization": "Bearer $SecretKey",
        "Content-type": "application/x-www-form-urlencoded"
      },
    );

    print("response from API = " + responseFromStripeAPI.body);

    return jsonDecode(responseFromStripeAPI.body);
  } catch (errorMsg) {
    if (kDebugMode) {
      print(errorMsg);
    }
    print(errorMsg.toString());
    rethrow;
  }
}

  Future<void> paymentSheetInitialization(String amountToBeCharge, String currency) async {
    try {
      IntentPaymentData = await MakeIntentForPayment(amountToBeCharge, currency);

      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          allowsDelayedPaymentMethods: true,
          paymentIntentClientSecret: IntentPaymentData!["client_secret"],
          style: ThemeMode.dark,
          merchantDisplayName: "SellzBuy",
        ),
      ).then((val) {
        print(val);
      });

      await showPaymentSheet();
    } catch (errorMsg, s) {
      if (kDebugMode) {
        print(s);
      }
      print(errorMsg.toString());
    }
  }

  Future<void> _confirmOrder() async {
    if (_formkey.currentState?.validate() != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide valid information')),
      );
      return;
    }

    if (_selectedPickUpLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select Pick Up Location.'))
      );
      return;
    }

    try {
      final productDoc = await FirebaseFirestore.instance.collection('products').doc(widget.productId).get();
      final sellerLocation = productDoc['seller_ifos']['seller_pick_up_location'];
      final sellerPhoneNumber = productDoc['seller_ifos']['seller_phone_number'] ?? 'None';

      await flutterLocalNotificationsPlugin.cancelAll();

             // Open payment sheet with the total amount
      await paymentSheetInitialization(
      _orderTotal(widget.totalAmount).toString(), // Pass the amount as a string
      'USD',
      );

      _formkey.currentState?.save();

      final productInfo = {
        "product_order_status": "It has been purchased",
      };

      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .update(productInfo);

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
        'status': "pending",
        "delivery_person_id": null,
        "receiver_infos": {
          "receiver_name": _enteredFullName,
          "receiver_email": _enteredEmail,
          "receiver_phone_number": _enteredPhoneNumber,
          "receiver_pick_up_location": _selectedPickUpLocation,
        },
        "payment_status": "held",
        "timestamp": Timestamp.fromDate(DateTime.now()),
        "seller_location": sellerLocation,
        "seller_phone_number": sellerPhoneNumber,
        "acceptance_date": null,
        "pick_up_date": null,
        "delivered_date": null,
        "is_received": false,
      };
      final docRef = FirebaseFirestore.instance.collection("orders").doc();
      await docRef.set(orderInfos);


      showToastrMessage("Your order has been placed successfully.");

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (ctx) => const OrderConfirmation(),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: $e')),
      );
    }
  }

  double _orderTotal(double productPrice) {
    var DeliveryFee = 3;
    var ServiceFee = 0.35;
    productPrice = (productPrice + DeliveryFee + ServiceFee);
    return productPrice;
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 153, 191, 216),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  color: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey,
                                width: 1.0,
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
                        const SizedBox(height: 5),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Text('Delivery fee'),
                            const Spacer(),
                            Text('3 JOD'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Text('Service fee'),
                            const Spacer(),
                            Text('0.35 JOD'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Order Total(incl. tax)', style: TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text('${_orderTotal(widget.totalAmount).toString()} JOD'),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  color: Colors.white,
                  elevation: 5,
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
                          Container(
                            alignment: Alignment.centerLeft,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey,
                                  width: 1.0,
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
                          const SizedBox(height: 0),
                          TextFormField(
                            controller: userEmailController,
                            decoration: const InputDecoration(labelText: 'Email Address'),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty || !value.contains('@')) {
                                return 'Please enter a valid email address.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredEmail = value!;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: userFullNameController,
                            decoration: const InputDecoration(labelText: 'Full Name'),
                            keyboardType: TextInputType.name,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty || value.contains('@') || value.contains('_') || value.contains('-') || value.trim().length <= 2) {
                                return 'Please enter a valid name.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredFullName = value!;
                            },
                          ),
                          const SizedBox(height: 16),
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
                              if (value.trim().length != 10 && value.trim().length != 13) {
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
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pick up location',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _showSearchableDropdown(context),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  ),
                                  child: Text(
                                    _selectedPickUpLocation ?? 'Select pick up location',
                                    style: TextStyle(
                                      color: _selectedPickUpLocation != null ? Colors.black : const Color.fromARGB(255, 97, 81, 73),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Flexible(
                                flex: 3,
                                child: SizedBox(
                                  width: double.infinity,
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
                                        mainAxisAlignment: MainAxisAlignment.center,
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
                              const SizedBox(width: 16),
                              Flexible(
                                flex: 3,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
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
                                        mainAxisAlignment: MainAxisAlignment.center,
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