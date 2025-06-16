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
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFavorite = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> _productsStream;
  int _selectedIndex = 0;
  GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

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
          return const Center(
              child: Text('Please sign in to view your profile'));
        }
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
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
        .where('deleted_at', isNull: true)
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
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
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
          .where('deleted_at', isNull: true)
          .orderBy('publishDate', descending: true)
          .snapshots();
    });
  }

  // Function to add/remove a product from favorites
  Future<void> _toggleFavorite(String productId, String productName,
      double productPrice, String imageUrl) async {
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
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _selectedIndex,
        height: 60.0.h,
        items: <Widget>[
          Icon(Icons.home, size: 30, color: kWhite),
          Icon(Icons.favorite, size: 30, color: kWhite),
          Icon(Icons.shopping_bag, size: 30, color: kWhite),
          Icon(Icons.person, size: 30, color: kWhite),
        ],
        color: kPrimaryBlue,
        buttonBackgroundColor: kPrimaryBlue,
        backgroundColor: kBackgroundGrey,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 600),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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
            .where('deleted_at', isNull: true)
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
                    // Add the image search button above categories
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _searchByImage(context),
                          icon: const Icon(Icons.image_search),
                          label: const Text('Search by Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                        ),
                      ),
                    ),
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
                    final product =
                        products[index].data() as Map<String, dynamic>;
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
                              imageUrls:
                                  List<String>.from(product['imageUrls']),
                              description: product['description'],
                              quantity: product['quantity'],
                              status: product['status'],
                              howMuchUsed:
                                  product['how_much_used'] ?? 'Not specified',
                              productId: productId,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
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
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.access_time,
                                                    size: 10,
                                                    color: Colors.white),
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
                                            stream: FirebaseAuth
                                                        .instance.currentUser !=
                                                    null
                                                ? FirebaseFirestore.instance
                                                    .collection('favorites')
                                                    .where('userId',
                                                        isEqualTo: FirebaseAuth
                                                            .instance
                                                            .currentUser
                                                            ?.uid)
                                                    .where('productId',
                                                        isEqualTo: productId)
                                                    .snapshots()
                                                : const Stream<
                                                    QuerySnapshot>.empty(),
                                            builder:
                                                (context, favoriteSnapshot) {
                                              final isFavorite = FirebaseAuth
                                                          .instance
                                                          .currentUser !=
                                                      null &&
                                                  favoriteSnapshot.hasData &&
                                                  favoriteSnapshot
                                                      .data!.docs.isNotEmpty;

                                              return Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.2),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  onPressed: () async {
                                                    DocumentSnapshot
                                                        productDocumentObj =
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                                'products')
                                                            .doc(productId)
                                                            .get();
                                                    final sellerId =
                                                        productDocumentObj[
                                                                "seller_ifos"]
                                                            ["seller_id"];
                                                    final user = FirebaseAuth
                                                        .instance.currentUser;
                                                    if (user != null) {
                                                      if (user.uid ==
                                                          sellerId) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                                const SnackBar(
                                                                    content: Text(
                                                                        "The user can't favorite his own product.")));
                                                        return;
                                                      }
                                                    }

                                                    if (FirebaseAuth.instance
                                                            .currentUser ==
                                                        null) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                            content: Text(
                                                                'You must be logged in to add favorites')),
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
                                                    isFavorite
                                                        ? Icons.favorite
                                                        : Icons.favorite_border,
                                                    size: 16,
                                                    color: isFavorite
                                                        ? Colors.red
                                                        : Colors.white,
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

  String extractFilename(String url) {
    // Parse the URL properly
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;

    // Find the 'o' parameter which contains the encoded path
    final encodedPath = pathSegments.lastWhere(
      (segment) => segment.contains('.jpg') || segment.contains('.png'),
      orElse: () => '',
    );

    // Decode URL encoding (%2F becomes /, etc.)
    final decodedPath = Uri.decodeComponent(encodedPath);

    // Extract just the filename
    return decodedPath.split('/').last;
  }

  Future<void> _searchByImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        const pythonApiUrl = 'http://172.20.10.2:5001/search';
        var request = http.MultipartRequest('POST', Uri.parse(pythonApiUrl));
        request.files
            .add(await http.MultipartFile.fromPath('image', pickedFile.path));

        var response = await request.send();
        final responseBody = await response.stream.bytesToString();
        final responseData = jsonDecode(responseBody);

        Navigator.of(context).pop(); // Close loading indicator

        if (response.statusCode == 200 && responseData['status'] == 'success') {
          final results = List<List<dynamic>>.from(responseData['results']);

          // Extract just the numeric image names from results (without .jpg)
          final resultImageNames = results.map((result) {
            String filename = result[0].toString();
            return filename.split('.').first; // Gets just "1739130712336"
          }).toList();

          // Get all products from Firestore
          final productsQuery = await FirebaseFirestore.instance
              .collection('products')
              .where('deleted_at', isNull: true)
              .get();

          // Filter products that have any image matching the result names
          final matchedProducts = productsQuery.docs.where((doc) {
            final productData = doc.data();
            final imageUrls = List<String>.from(productData['imageUrls']);

            return imageUrls.any((url) {
              try {
                // Extract the numeric filename from Firebase Storage URL
                // Example URL: "https://.../product_images%2F1750009078909.jpg?..."
                final uri = Uri.parse(url);
                final path = uri
                    .path; // Gets "/v0/.../product_images%2F1750009078909.jpg"
                final encodedFilename = path
                    .split('/')
                    .last; // "product_images%2F1750009078909.jpg"
                final decodedFilename = Uri.decodeComponent(
                    encodedFilename); // "product_images/1750009078909.jpg"
                final filename =
                    decodedFilename.split('/').last; // "1750009078909.jpg"
                final imageName = filename.split('.').first; // "1750009078909"

                // Check if this image name exists in our results
                return resultImageNames.any((id) => imageName.contains(id));
              } catch (e) {
                print('Error parsing URL: $url, error: $e');
                return false;
              }
            });
          }).toList();

          if (matchedProducts.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No matching products found')),
            );
          } else {
            // Show results in a new screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Search Results')),
                  body: ListView.builder(
                    itemCount: matchedProducts.length,
                    itemBuilder: (context, index) {
                      final product = matchedProducts[index].data();
                      final imageUrl = product['imageUrls'][0];

                      return ListTile(
                        leading: Image.network(imageUrl,
                            width: 50, height: 50, fit: BoxFit.cover),
                        title: Text(product['name']),
                        subtitle: Text('${product['price']} JOD'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(
                                productName: product['name'],
                                productPrice: product['price'],
                                imageUrls:
                                    List<String>.from(product['imageUrls']),
                                description: product['description'],
                                quantity: product['quantity'],
                                status: product['status'],
                                howMuchUsed:
                                    product['how_much_used'] ?? 'Not specified',
                                productId: matchedProducts[index].id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Search failed: ${responseData['message'] ?? 'Unknown error'}')),
          );
        }
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
