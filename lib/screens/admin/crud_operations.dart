import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_project/screens/admin/admin_signup.dart';
import 'package:test_project/screens/admin/category_to_be_edited.dart';
import 'package:test_project/screens/admin/edit_delivery_details.dart';
import 'package:test_project/screens/admin/edit_user_details.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CrudOperationsScreen extends StatefulWidget {
  const CrudOperationsScreen({super.key});

  @override
  State<CrudOperationsScreen> createState() {
    return _CrudOperationsScreenState();
  }
}

class _CrudOperationsScreenState extends State<CrudOperationsScreen> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _hasCardInformation = false;

  @override
  void initState() {
    super.initState();
    _checkCardInformation();
  }

  Future<void> _checkCardInformation() async {
    final adminDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    if (adminDoc.exists && adminDoc['stripePaymentMethodId'] != null) {
      setState(() {
        _hasCardInformation = true;
      });
    }
  }

  void _openAddExpenseOverlay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const CategoryToBeEdited(),
    );
  }

  Future deleteUser(String id, Map<String, dynamic> userDetails) async {
    // Temporarily save user details before deletion
    await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .delete()
        .then((value) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: const Text("User has been deleted"),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              // Re-add the user if "Undo" is pressed
              FirebaseFirestore.instance
                  .collection("users")
                  .doc(id)
                  .set(userDetails)
                  .then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("User deletion undone")));
              });
            },
          ),
        ),
      );
    });
  }

  Future deleteDeliveryUser(String id, Map<String, dynamic> userDetails) async {
    // Temporarily save user details before deletion
    await FirebaseFirestore.instance
        .collection("delivery")
        .doc(id)
        .delete()
        .then((value) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: const Text("User has been deleted"),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              // Re-add the user if "Undo" is pressed
              FirebaseFirestore.instance
                  .collection("delivery")
                  .doc(id)
                  .set(userDetails)
                  .then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("User deletion undone")));
              });
            },
          ),
        ),
      );
    });
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    final deliverySnapshot =
        await FirebaseFirestore.instance.collection('delivery').get();

    List<Map<String, dynamic>> usersList = [];
    usersList.addAll(
      usersSnapshot.docs
          .map((doc) => {
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
                'source': 'users', // Mark data from users collection
              })
          .toList(),
    );

    usersList.addAll(
      deliverySnapshot.docs
          .map((doc) => {
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
                'source': 'delivery', // Mark data from delivery collection
              })
          .toList(),
    );

    return usersList;
  }

  void _showAddCardDialog(BuildContext context) {
    stripe.CardFieldInputDetails? _newCardDetails;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Card Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              stripe.CardField(
                onCardChanged: (card) {
                  _newCardDetails = card;
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Card Details',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_newCardDetails == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter card details')),
                  );
                  return;
                }

                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User not logged in')),
                  );
                  return;
                }

                try {
                  // Create a PaymentMethod using Stripe
                  final paymentMethod =
                      await stripe.Stripe.instance.createPaymentMethod(
                    params: stripe.PaymentMethodParams.card(
                      paymentMethodData: stripe.PaymentMethodData(
                        billingDetails: stripe.BillingDetails(
                          email: user.email, // Use the logged-in user's email
                        ),
                      ),
                    ),
                  );

                  // Save the PaymentMethod ID to the admin's document
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid) // Use the logged-in user's UID
                      .update({
                    'stripePaymentMethodId': paymentMethod.id,
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Card information saved successfully')),
                  );

                  setState(() {
                    _hasCardInformation = true;
                  });

                  Navigator.pop(ctx);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Failed to save card information: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: OutlinedButton(
          onPressed: () {
            _openAddExpenseOverlay();
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: Theme.of(context).colorScheme.primaryContainer,
              width: 1.5.w,
            ),
          ),
          child: Text(
            'Category',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          if (!_hasCardInformation)
            IconButton(
              icon: const Icon(Icons.credit_card),
              onPressed: () {
                _showAddCardDialog(context);
              },
            ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const AdminSignUpScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primaryContainer),
              decoration: InputDecoration(
                hintText: "Search for users .....",
                hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primaryContainer),
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = "";
                    });
                  },
                  icon: Icon(
                    Icons.clear,
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0.r),
                  borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      width: 2.0.w),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUsers(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          final users = snapshot.data!.where((doc) {
            final email = doc['email']?.toLowerCase() ?? '';
            final fullName = doc['name']?.toLowerCase() ?? '';
            return email.contains(_searchQuery) ||
                fullName.contains(_searchQuery);
          }).toList();

          if (users.isEmpty) {
            return const Center(child: Text('No users match the search query'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (ctx, index) {
              final user = users[index];
              final username = user['username'] ?? 'N/A';
              final email = user['email'] ?? 'N/A';
              final phoneNumber = user['phone_number'] ?? 'N/A';
              final fullName = user['name'] ?? 'N/A';
              List<String> parts = fullName.split(' ');
              String firstTwoWords =
                  parts.length >= 2 ? parts.take(2).join(' ') : fullName;

              final roleDisplayed = user['role'] != null
                  ? '${user['role'][0].toUpperCase()}${user['role'].substring(1).toLowerCase()}'
                  : 'N/A';
              final role = user['role'];
              final imageUrl = user['image_url'] ?? null;

              final nationalID = user['national_id'] ?? 'N/A';
              final vehicleModel =
                  user['Vehicle_Infos']?['vehicle_model'] ?? 'N/A';
              final location = user['location'] ?? 'N/A';
              final vehicleNumber =
                  user['Vehicle_Infos']?['vehicle_number'] ?? 'N/A';
              final vehicleColor =
                  user['Vehicle_Infos']?['Vehicle_Color'] ?? 'N/A';
              final vehicleType = user['Vehicle_Infos']?['vehicle_type'];
              return InkWell(
                onTap: () {
                  if (role == 'delivery') {
                    final joiningDate = (user['joining_date'] as Timestamp?)
                        ?.toDate(); // Convert to DateTime
                    final dateOfBirth = (user['date_of_birth'] as Timestamp?)
                        ?.toDate(); // Convert to DateTime
                    Navigator.of(context)
                        .push(
                      MaterialPageRoute(
                        builder: (ctx) => EditDeliveryDetailsScreen(
                          userId: user['id'],
                          initialName: fullName,
                          initialEmail: email,
                          initialPhoneNumber: phoneNumber,
                          initialImageUrl: imageUrl,
                          initialNationalID: nationalID,
                          initialJoiningDate: joiningDate,
                          initialDateOfBirth: dateOfBirth,
                          initialVehicleModel: vehicleModel,
                          initialLocation: location,
                          initialVehicleNumber: vehicleNumber,
                          initialVehicleColor: vehicleColor,
                          initialVehicleType: vehicleType,
                        ),
                      ),
                    )
                        .then((_) {
                      setState(() {}); // Reload the user list when returning
                    });
                  } else {
                    Navigator.of(context)
                        .push(
                      MaterialPageRoute(
                        builder: (ctx) => EditUserDetailsScreen(
                          userId: user['id'],
                          initialName: fullName,
                          initialEmail: email,
                          initialUsername: username,
                          initialPhoneNumber: phoneNumber,
                          initialImageUrl: imageUrl,
                        ),
                      ),
                    )
                        .then((_) {
                      setState(() {}); // Reload the user list when returning
                    });
                  }
                },
                splashColor: Theme.of(context).colorScheme.primary,
                child: Dismissible(
                  key: ValueKey(user['id']),
                  background: Container(
                    color:
                        Theme.of(context).colorScheme.error.withOpacity(0.75),
                  ),
                  onDismissed: (direction) {
                    final userDetails = user;
                    if (role == 'delivery') {
                      deleteDeliveryUser(user['id'], userDetails);
                    } else {
                      deleteUser(user['id'], userDetails);
                    }
                  },
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : const AssetImage(
                                    'assets/images/default_avatar.avif')
                                as ImageProvider,
                      ),
                      title: Row(
                        children: [
                          Text(
                            username,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text(
                            roleDisplayed,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email: $email',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Phone: $phoneNumber',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              Text(
                                'Name: $firstTwoWords',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
