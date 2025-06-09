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
import 'package:test_project/screens/favorites_screen.dart';
import 'package:test_project/user/account_management.dart';
import 'package:test_project/screens/orders_screen.dart';

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
  int _selectedIndex = 0;
  
  String userName = '';

  // Add this list to store the screens
  final List<Widget> _screens = [
    const HomeContent(),
    const FavoritesScreen(),
    const OrdersScreen(),
    Builder(
      builder: (context) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          return const Center(child: Text('Please sign in to view your profile'));
        }
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            return AccountManagementScreen(
              userId: user.uid,
              initialName: userData['name'] ?? '',
              initialEmail: userData['email'] ?? '',
              initialUsername: userData['username'] ?? '',
              initialPhoneNumber: userData['phone_number'] ?? '',
              initialImageUrl: userData['image_url'],
            );
          },
        );
      },
    ),
  ];

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: kPrimaryBlue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// Create a new widget to hold the home content
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  // Helper function to calculate time difference
  static String _getTimeAgo(Timestamp publishDate) {
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

  // Function to add/remove a product from favorites
  static Future<void> _toggleFavorite(
    String productId,
    String productName,
    double productPrice,
    String imageUrl,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final favoriteRef = FirebaseFirestore.instance
        .collection('favorites')
        .where('userId', isEqualTo: user.uid)
        .where('productId', isEqualTo: productId);

    final favoriteSnapshot = await favoriteRef.get();

    if (favoriteSnapshot.docs.isEmpty) {
      // Add to favorites
      await FirebaseFirestore.instance.collection('favorites').add({
        'userId': user.uid,
        'productId': productId,
        'productName': productName,
        'productPrice': productPrice,
        'imageUrl': imageUrl,
      });
    } else {
      // Remove from favorites
      await favoriteSnapshot.docs.first.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Implement refresh logic here
      },
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('publishDate', descending: true)
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
                    SizedBox(height: 1.h),
                  ],
                ),
              ),
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5 / 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = products[index].data() as Map<String, dynamic>;
                    final imageUrl = product['imageUrls'][0];
                    final productId = products[index].id;
                    final publishDate = product['publishDate'] as Timestamp;
                    final timeAgo = _getTimeAgo(publishDate);

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
                                            stream: FirebaseAuth.instance.currentUser != null
                                                ? FirebaseFirestore.instance
                                                    .collection('favorites')
                                                    .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                                                    .where('productId', isEqualTo: productId)
                                                    .snapshots()
                                                : const Stream<QuerySnapshot>.empty(),
                                            builder: (context, favoriteSnapshot) {
                                              final isFavorite = FirebaseAuth.instance.currentUser != null &&
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
                                                        await FirebaseFirestore.instance.collection('products').doc(productId).get();
                                                    final sellerId = productDocumentObj["seller_ifos"]["seller_id"];
                                                    final user = FirebaseAuth.instance.currentUser;
                                                    if (user != null) {
                                                      if (user.uid == sellerId) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text("The user can't favorite his own product.")));
                                                        return;
                                                      }
                                                    }

                                                    if (FirebaseAuth.instance.currentUser == null) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('You must be logged in to add favorites')),
                                                      );
                                                    } else {
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