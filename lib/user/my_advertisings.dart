import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:test_project/screens/product_details_screen.dart';
import 'package:test_project/user/edit_user_products.dart';

class MyAdvertisings extends StatefulWidget {
  const MyAdvertisings({super.key, required this.sellerUserId});

  final String sellerUserId;

  @override
  State<MyAdvertisings> createState() => _MyAdvertisingsState();
}

class _MyAdvertisingsState extends State<MyAdvertisings> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController mainTitleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController howMuchUsedController = TextEditingController();
  TextEditingController quantityController = TextEditingController();

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
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        title: const Text('Your Advertisings'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('products')
              .where('seller_ifos.seller_id', isEqualTo: widget.sellerUserId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No products found.'));
            }

            final products = snapshot.data!.docs;

            return CustomScrollView(
              slivers: [
                // Add the non-sticky section here
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text.rich(
                      TextSpan(
                        text: 'You can ',
                        style: TextStyle(
                          fontSize: 40,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        children: const [
                          TextSpan(
                            text: 'edit',
                            style: TextStyle(
                              color: Colors.blue, // Blue color for "edit"
                            ),
                          ),
                          TextSpan(text: ' or '),
                          TextSpan(
                            text: 'delete',
                            style: TextStyle(
                              color: Colors.red, // Red color for "delete"
                            ),
                          ),
                          TextSpan(text: ' your products'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 18),
                ),

                // Product Grid Section
                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3 / 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = products[index].data() as Map<String, dynamic>;
                      final imageUrl = product['imageUrls'][0]; // Use the first image
                      final productId = products[index].id; // Get the document ID
                      final categoryId = product['categoryId'];

                      return GestureDetector(
                        onTap: () {
                          // Navigate to ProductDetailScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(
                                productName: product['name'],
                                productPrice: product['price'],
                                imageUrls: List<String>.from(product['imageUrls']),
                                description: product['description'],
                                quantity: product['quantity'],
                                status: product['status'],
                                howMuchUsed: product['how_much_used'],
                                productId: productId,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Hero(
                                    tag: productId,
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  product['name'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  product['description'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                '${product['price']} JOD',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),

                              // Edit Button
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                child: ElevatedButton(
                                  onPressed: () {
                                    mainTitleController.text = product['name'] ?? ""; // Use empty string if null
                                    descriptionController.text = product['description'] ?? ""; // Use empty string if null
                                    priceController.text = product['price']?.toString() ?? ""; // Use empty string if null
                                    howMuchUsedController.text = product['how_much_used'] ?? ""; // Use empty string if null
                                    quantityController.text = product['quantity']?.toString() ?? ""; // Use empty string if null
                                    final imageUrls = List<String>.from(product['imageUrls'] ?? []); // Use empty list if null
                                    final productId = products[index].id; // Get the product ID

                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (ctx) => EditUserProducts(
                                          productPriceController: priceController,
                                          productNameController: mainTitleController,
                                          productDescriptionController: descriptionController,
                                          quantityController: quantityController, // Pass the quantity controller
                                          categoryId: categoryId,
                                          initialImageUrls: imageUrls,
                                          productId: productId, // Pass the product ID
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.edit_square, color: Colors.white, size: 23),
                                      SizedBox(width: 5),
                                      Text(
                                        'Edit',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Delete Button
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 5),
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Show a confirmation dialog
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Delete Product'),
                                          content: const Text('Are you sure you want to delete this product?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                // Close the dialog
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text(
                                                'No',
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                // Close the dialog
                                                Navigator.of(context).pop();

                                                // Delete the product from Firestore
                                                try {
                                                  await _firestore
                                                      .collection('products')
                                                      .doc(products[index].id) // Use the product ID
                                                      .delete();

                                                  // Show a success message
                                                  showToastrMessage("Your Product Has Been Deleted Successfully");
                                                } catch (e) {
                                                  // Show an error message
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Failed to delete product: $e'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              },
                                              child: const Text(
                                                'Yes',
                                                style: TextStyle(color: Colors.green),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.delete, color: Colors.white, size: 23),
                                      SizedBox(width: 5),
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: products.length,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}