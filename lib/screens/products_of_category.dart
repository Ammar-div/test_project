import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_project/screens/product_details_screen.dart';



class ProductsOfCategory extends StatefulWidget {
  const ProductsOfCategory(this.categoryName, {super.key , required this.categoryId});

  final String categoryId;
  final String categoryName;

  @override
  State<ProductsOfCategory> createState() => _ProductsOfCategoryState();
}

class _ProductsOfCategoryState extends State<ProductsOfCategory> {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


   // Helper function to calculate time difference
  String _getTimeAgo(Timestamp publishDate) {
    final now = DateTime.now();
    final date = publishDate.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        title: Text('${widget.categoryName}s'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(10),
          child: Container(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('products').where('categoryId' , isEqualTo: widget.categoryId).snapshots(),   // select all products
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

              // Product Grid Section
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3 / 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = products[index].data() as Map<String, dynamic>;
                    final imageUrl = product['imageUrls'][0]; // Use the first image
                    final productId = products[index].id; // Get the document ID
                    final publishDate = product['publishDate'] as Timestamp;
                    final timeAgo = _getTimeAgo(publishDate); // Calculate time ago

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
                              howMuchUsed: product['how_much_used'] ?? 'Not specified', // Handle null
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text(
                                  '${product['price']} JOD',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.favorite_border),
                                ),
                              ],
                            ),
                            // Display how long ago the product was posted
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0 , horizontal: 10),
                              child: Text(
                                timeAgo,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer, 
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
    );
  }
}