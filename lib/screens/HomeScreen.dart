import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For user authentication
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:test_project/screens/admin/pc_category/all_categories.dart';
import 'package:test_project/screens/auth_screen.dart';
import 'package:test_project/screens/product_details_screen.dart';
import 'package:test_project/widgets/main_drawr.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_project/constants/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFavorite = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> _productsStream;
  
  String userName = '';

  @override
  void initState() {
    super.initState();
    setState(() {});

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

    // Initialize the stream
    _productsStream = _firestore
        .collection('products')
        .orderBy('publishDate', descending: true)
        .snapshots();



       // Set up the auth state listener
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      _getUserName();
    } else {
      setState(() {
        userName = '';
      });
    }
  });
  }

  Future<int> _getFavoriteCount(String productId) async {
  final QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('favorites')
      .where('productId', isEqualTo: productId)
      .get();

  return snapshot.docs.length;
}

  void _getUserName() async {
    final user = _auth.currentUser;
    if(user != null)
    {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        setState(() {
           userName = userDoc['username'] ?? 'N/A';
        });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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

  // Function to refresh the stream
  Future<void> _refreshProducts() async {
    setState(() {
      _productsStream = _firestore
          .collection('products')
          .orderBy('publishDate', descending: true)
          .snapshots();
    });
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
        const SnackBar(content: Text('Product added to favorites')),
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
Widget build(BuildContext context) {
  final user = _auth.currentUser;
  return Scaffold(
    backgroundColor: kBackgroundGrey,
    appBar: AppBar(
      backgroundColor: kPrimaryBlue,
      actions: [
        if (user == null)
          GestureDetector(
            onTap: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const AuthScreen()),
              );

              if (result != null && result['success'] == true) {
                _getUserName();
              }
            },
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Icon(FontAwesomeIcons.user, size: 16, color: kWhite),
                  SizedBox(width: 6.w),
                  Text('Sign In', style: TextStyle(color: kWhite)),
                ],
              ),
            ),
          ),
        if (user != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Text(userName, style: TextStyle(color: kWhite)),
                SizedBox(width: 8.w),
                Icon(FontAwesomeIcons.userTie, size: 16, color: kWhite),
              ],
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(10),
        child: Container(),
      ),
    ),
    drawer: const MainDrawr(),
    body: RefreshIndicator(
      onRefresh: _refreshProducts, // Callback when user pulls to refresh
      child: StreamBuilder<QuerySnapshot>(
        stream: _productsStream,
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

          // Filter out products with "product_order_status" equal to "It has been purchased"
          final products = snapshot.data!.docs.where((doc) {
            final product = doc.data() as Map<String, dynamic>;
            return product['product_order_status'] == 'Not requested yet';
          }).toList();

          if (products.isEmpty) {
            return const Center(child: Text('No available products.'));
          }

          return CustomScrollView(
            slivers: [
               SliverToBoxAdapter(
                child: Column(
                  children: [
                    AllCategories(),
                    SizedBox(height: 5.h),
                  ],
                ),
              ),
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3 / 5.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = products[index].data() as Map<String, dynamic>;
                    final imageUrl = product['imageUrls'][0];
                    final productId = products[index].id;
                    final publishDate = product['publishDate'] as Timestamp;
                    final timeAgo = _getTimeAgo(publishDate); // Calculate time ago

                    return GestureDetector(
                      onTap: () {
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
                              howMuchUsed: product['how_much_used'] ?? 'Not specified',
                              productId: productId,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
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
                                style:  TextStyle(
                                  fontSize: 13.sp,
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
                                style:  TextStyle(
                                  fontSize: 10.sp,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text(
                                  '${product['price'].toStringAsFixed(0)} JOD',
                                  style:  TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
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

                                    return AnimatedBuilder(
                                      animation: _scaleAnimation,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: _scaleAnimation.value,
                                          child: IconButton(
                                            onPressed: () async {
                                              DocumentSnapshot productDocumentObj =
                                                  await _firestore.collection('products').doc(productId).get();
                                              final sellerId = productDocumentObj["seller_ifos"]["seller_id"];
                                              final user = FirebaseAuth.instance.currentUser;
                                              if (user != null) {
                                                if (user.uid == sellerId) {
                                                  // owner of the product
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
                                              size: 19,
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
                            // Display how long ago the product was posted
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
                              child: Text(
                                timeAgo,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 9.sp,
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
    ),
  );
}
}