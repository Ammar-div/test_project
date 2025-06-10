import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_project/constants/colors.dart';
import 'package:test_project/screens/product_details_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FavoritesScreen extends StatefulWidget {
  final bool? showHeader;
  const FavoritesScreen({super.key, this.showHeader});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

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

  Future<void> _toggleFavorite(String productId, String productName, double productPrice, String imageUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to manage favorites')),
      );
      return;
    }

    final favoriteRef = FirebaseFirestore.instance
        .collection('favorites')
        .where('userId', isEqualTo: user.uid)
        .where('productId', isEqualTo: productId);

    final favoriteSnapshot = await favoriteRef.get();

    if (favoriteSnapshot.docs.isEmpty) {
      await FirebaseFirestore.instance.collection('favorites').add({
        'userId': user.uid,
        'productId': productId,
        'productName': productName,
        'productPrice': productPrice,
        'imageUrl': imageUrl,
      });
    } else {
      await favoriteSnapshot.docs.first.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: kBackgroundGrey,
      appBar: widget.showHeader == true ? AppBar(
        title: const Text('Your Favorites'),
        backgroundColor: kPrimaryBlue,
      ) : null,
      body: user == null
          ? const Center(child: Text('Please sign in to view favorites'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('favorites')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No favorites yet'));
                }

                return ListView.builder(
                  padding: EdgeInsets.all(8.r),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final favorite = snapshot.data!.docs[index];
                    final productId = favorite['productId'];
                    final productName = favorite['productName'];
                    final productPrice = (favorite['productPrice'] as num).toDouble();
                    final imageUrl = favorite['imageUrl'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
                      builder: (context, productSnapshot) {
                        if (!productSnapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        if (!productSnapshot.data!.exists || 
                            (productSnapshot.data!.data() as Map<String, dynamic>)['deleted_at'] != null) {
                          // Remove from favorites if product is deleted or doesn't exist
                          _toggleFavorite(productId, productName, productPrice, imageUrl);
                          return const SizedBox.shrink();
                        }

                        final productData = productSnapshot.data!.data() as Map<String, dynamic>;

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.r),
                            side: BorderSide(
                              color: const Color.fromRGBO(50, 18, 0, 1),
                              width: 2.w,
                            ),
                          ),
                          clipBehavior: Clip.hardEdge,
                          elevation: 2,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailScreen(
                                    productName: productName,
                                    productPrice: productPrice,
                                    imageUrls: List<String>.from(productData['imageUrls']),
                                    description: productData['description'],
                                    quantity: productData['quantity'],
                                    status: productData['status'],
                                    howMuchUsed: productData['how_much_used'] ?? 'Not specified',
                                    productId: productId,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    Image.network(
                                      imageUrl,
                                      height: 200.h,
                                      width: double.infinity,
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
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('favorites')
                                            .where('userId', isEqualTo: user.uid)
                                            .where('productId', isEqualTo: productId)
                                            .snapshots(),
                                        builder: (context, favoriteSnapshot) {
                                          final isFavorite = favoriteSnapshot.hasData &&
                                              favoriteSnapshot.data!.docs.isNotEmpty;

                                          return AnimatedBuilder(
                                            animation: _scaleAnimation,
                                            builder: (context, child) {
                                              return Transform.scale(
                                                scale: _scaleAnimation.value,
                                                child: IconButton(
                                                  onPressed: () {
                                                    if (_animationController.isAnimating) return;
                                                    _animationController.forward().then((_) {
                                                      _animationController.reverse();
                                                    });
                                                    _toggleFavorite(
                                                      productId,
                                                      productName,
                                                      productPrice,
                                                      imageUrl,
                                                    );
                                                  },
                                                  icon: Icon(
                                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                                    color: isFavorite ? Colors.red : Colors.white,
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.all(12.r),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        productName,
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        productData['description'],
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 8.h),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${productPrice.toStringAsFixed(0)} JOD',
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius: BorderRadius.circular(12.r),
                                            ),
                                            child: Text(
                                              productData['status'],
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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
              },
            ),
    );
  }
} 