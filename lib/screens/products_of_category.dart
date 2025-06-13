import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:test_project/screens/product_details_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';



class ProductsOfCategory extends StatefulWidget {
  const ProductsOfCategory(this.categoryName, {super.key , required this.categoryId});

  final String categoryId;
  final String categoryName;

  @override
  State<ProductsOfCategory> createState() => _ProductsOfCategoryState();
}

class _ProductsOfCategoryState extends State<ProductsOfCategory> with SingleTickerProviderStateMixin {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isFavorite = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;



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


Future<int> _getFavoriteCount(String productId) async {
  final QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('favorites')
      .where('productId', isEqualTo: productId)
      .get();

  return snapshot.docs.length;
}

    // Function to add/remove a product from favorites
  Future<void> _toggleFavorite(String productId, String productName, double productPrice, String imageUrl) async {
    final user = _auth.currentUser;
    if (user == null) {
      // Handle case where user is not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to add favorites')),
      );
      return;
    }
    final favoriteRef = _firestore
        .collection('favorites')
        .where('userId', isEqualTo: user.uid)
        .where('productId', isEqualTo: productId);
    final favoriteSnapshot = await favoriteRef.get();
    if (favoriteSnapshot.docs.isEmpty) {
      // Add to favorites
      await _firestore.collection('favorites').add({
        'userId': user.uid,
        'productId': productId,
        'productName': productName,
        'productPrice': productPrice,
        'imageUrl': imageUrl,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$productName added to favorites')),
      );
    } else {
      // Remove from favorites
      await favoriteSnapshot.docs.first.reference.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product removed from favorites')),
      );
    }
  }


    @override
  void initState() {
    super.initState();

     _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

   @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      stream: _firestore
          .collection('products')
          .where('deleted_at', isNull: true)
          .where('categoryId', isEqualTo: widget.categoryId)
          .where('product_order_status', isEqualTo: 'Not requested yet')
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
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Stack(
                          children: [
                            // Background Image
                            Hero(
                              tag: productId,
                              child: Image.network(
                                imageUrl,
                                height: 130,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            // Gradient Overlay
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Content
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            product['name'],
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 17.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              height: 1.2,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${product['price'].toStringAsFixed(0)} JOD',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      product['description'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.white.withOpacity(0.9),
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.access_time, size: 10, color: Colors.white),
                                              const SizedBox(width: 2),
                                              Text(
                                                timeAgo,
                                                style: TextStyle(
                                                  fontSize: 8.sp,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        StreamBuilder<QuerySnapshot>(
                                          stream: _auth.currentUser != null
                                              ? _firestore
                                                  .collection('favorites')
                                                  .where('userId', isEqualTo: _auth.currentUser?.uid)
                                                  .where('productId', isEqualTo: productId)
                                                  .snapshots()
                                              : const Stream<QuerySnapshot>.empty(),
                                          builder: (context, favoriteSnapshot) {
                                            final isFavorite = _auth.currentUser != null &&
                                                favoriteSnapshot.hasData &&
                                                favoriteSnapshot.data!.docs.isNotEmpty;

                                            return Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () async {
                                                  DocumentSnapshot productDocumentObj =
                                                      await _firestore.collection('products').doc(productId).get();
                                                  final sellerId = productDocumentObj["seller_ifos"]["seller_id"];
                                                  final user = FirebaseAuth.instance.currentUser;
                                                  if (user != null) {
                                                    if (user.uid == sellerId) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text("The user can't favorite his own product.")));
                                                      return;
                                                    }
                                                  }

                                                  if (_auth.currentUser == null) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('You must be logged in to add favorites')),
                                                    );
                                                  } else {
                                                    setState(() {
                                                      _isFavorite = !_isFavorite;
                                                    });

                                                    if (_isFavorite) {
                                                      _animationController.forward().then((_) {
                                                        _animationController.reverse();
                                                      });
                                                    } else {
                                                      _animationController.reverse();
                                                    }

                                                    _toggleFavorite(
                                                      productId,
                                                      product['name'],
                                                      product['price'],
                                                      imageUrl,
                                                    );
                                                  }
                                                },
                                                icon: Icon(
                                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                                  size: 16,
                                                  color: isFavorite ? Colors.red : Colors.white,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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