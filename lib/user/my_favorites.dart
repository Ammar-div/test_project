import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_project/screens/HomeScreen.dart';
import 'package:test_project/screens/product_details_screen.dart';
import 'package:test_project/screens/products_of_category.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyFavorites extends StatefulWidget {
  @override
  State<MyFavorites> createState() => _MyFavoritesState();
}

class _MyFavoritesState extends State<MyFavorites> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFavorite = false;
  late Stream<QuerySnapshot> _productsStream;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animationController.forward();

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

  // Function to add/remove a product from favorites
  Future<void> _toggleFavorite(
      String productId, String productName, double productPrice, String imageUrl) async {
    final user = _auth.currentUser;
    if (user == null) {
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
        SnackBar(content: Text('$productName removed from favorites')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Favorites'),
         leading: IconButton(
           icon: const Icon(Icons.arrow_back),
            onPressed: () {
               Navigator.pushReplacement( context, MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
                 }, 
                 ),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: _firestore
                    .collection('favorites')
                    .where('userId', isEqualTo: _auth.currentUser?.uid)
                    .snapshots(),
                    
                builder: (context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No favorites found.'));
                  }

                  final favorites = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: favorites.length,
                    itemBuilder: (ctx, index) {
                      final favorite = favorites[index].data() as Map<String, dynamic>;

                      String productId = favorite["productId"];
                      String productName = favorite["productName"];
                      double productPrice = (favorite["productPrice"] as num).toDouble();
                      String imageUrl = favorite["imageUrl"];

                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              // Fetch the product details from the products collection
                              DocumentSnapshot productSnapshot = await _firestore.collection('products').doc(productId).get();

                              if (productSnapshot.exists) {
                                Map<String, dynamic> productData = productSnapshot.data() as Map<String, dynamic>;
                                
                                // Check if product is deleted
                                if (productData['deleted_at'] != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('This product has been removed')),
                                  );
                                  // Remove from favorites if product is deleted
                                  await _toggleFavorite(productId, productName, productPrice, imageUrl);
                                  return;
                                }

                                String description = productData["description"];
                                String status = productData["status"];
                                String howMuchUsed = productData["how_much_used"] ?? 'None';
                                int quantity = productData["quantity"];
                                List<String> imageUrls = List<String>.from(productData["imageUrls"]);

                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (ctx) => ProductDetailScreen(
                                    productName: productName,
                                    productPrice: productPrice,
                                    imageUrls: imageUrls,
                                    description: description,
                                    status: status,
                                    howMuchUsed: howMuchUsed,
                                    quantity: quantity,
                                    productId: productId,
                                  ),
                                ));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Product details not found')),
                                );
                                // Remove from favorites if product doesn't exist
                                await _toggleFavorite(productId, productName, productPrice, imageUrl);
                              }
                            },
                            child: Card(
                              margin: const EdgeInsets.all(8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                side:  BorderSide(
                                  color: Color.fromRGBO(50, 18, 0, 1),
                                  width: 2.w,
                                ),
                              ),
                              clipBehavior: Clip.hardEdge,
                              elevation: 2,
                              child: Column(
                                children: [
                                  // Image with loading indicator
                                  Image.network(
                                    imageUrl,
                                    height: 300.h,
                                    width: double.infinity.w,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  (loadingProgress.expectedTotalBytes ?? 1)
                                              : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(Icons.error, size: 50, color: Colors.red),
                                      );
                                    },
                                  ),
                                   SizedBox(height: 8.h),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 6),
                                    child: Text(
                                      productName,
                                      textAlign: TextAlign.center,
                                      style:  TextStyle(
                                        fontSize: 22.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text(
                                          '${productPrice.toStringAsFixed(0)} JOD',
                                          style:  TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20.sp,
                                          ),
                                        ),
                                        StreamBuilder<QuerySnapshot>(
                                          stream: _firestore
                                              .collection('favorites')
                                              .where('userId', isEqualTo: _auth.currentUser?.uid)
                                              .where('productId', isEqualTo: productId)
                                              .snapshots(),
                                          builder: (context, favoriteSnapshot) {
                                            final isFavorite = _auth.currentUser != null &&
                                                favoriteSnapshot.hasData &&
                                                favoriteSnapshot.data!.docs.isNotEmpty;

                                            return AnimatedBuilder(
                                              animation: _scaleAnimation,
                                              builder: (context, child) {
                                                return Transform.scale(
                                                  scale: _scaleAnimation.value,
                                                  child: IconButton(
                                                    onPressed: () {
                                                      if (_auth.currentUser == null) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(
                                                              content: Text(
                                                                  'You must be logged in to add favorites')),
                                                        );
                                                      } else {
                                                        _toggleFavorite(
                                                          productId,
                                                          productName,
                                                          productPrice,
                                                          imageUrl,
                                                        );
                                                      }
                                                    },
                                                    icon: Icon(
                                                      isFavorite ? Icons.favorite : Icons.favorite_border,
                                                      color: isFavorite ? Colors.red : null,
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                           SizedBox(height: 25.h),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
