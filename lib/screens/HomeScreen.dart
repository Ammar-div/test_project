import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For user authentication
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:test_project/screens/admin/pc_category/all_categories.dart';
import 'package:test_project/screens/product_details_screen.dart';
import 'package:test_project/widgets/main_drawr.dart';

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
  final NotiService _notiService = NotiService();

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

    // Listen for product status changes
    _listenForProductStatusChanges();
  }

  void _listenForProductStatusChanges() {
    final user = _auth.currentUser;
    if (user == null) {
      print('User is not logged in. Notifications will not be triggered.');
      return;
    }

    print('Listening for product status changes for seller: ${user.uid}');

    _firestore
        .collection('products')
        .where('seller_ifos.seller_id', isEqualTo: user.uid) // Only listen to products owned by the seller
        .snapshots()
        .listen((snapshot) {
      print('Received ${snapshot.docChanges.length} changes in product status.');

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final product = change.doc.data() as Map<String, dynamic>;
          print('Product status changed: ${product['product_order_status']}');

          if (product['product_order_status'] == 'It has been purchased') {
            print('Notification triggered for seller: ${user.uid}');

            // Show notification only if the current user is the seller
            _notiService.showNotification(
              title: 'Product Purchased',
              body: 'One of your products has been purchased!',
            );

            // Store the notification in Firestore for later
            _firestore.collection('notifications').add({
              'userId': user.uid,
              'title': 'Product Purchased',
              'body': 'One of your products has been purchased!',
              'read': false,
              'timestamp': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    });
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
    if (user != null) {
      // Check for pending notifications when the user logs in
      _notiService.checkPendingNotifications(user.uid);
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        actions: [
          Image.asset(
            'assets/images/logo.png',
            width: 90,
            height: 90,
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
              return product['product_order_status'] != 'It has been purchased';
            }).toList();

            if (products.isEmpty) {
              return const Center(child: Text('No available products.'));
            }

            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: Column(
                    children: [
                      AllCategories(),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
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
                                    '${product['price'].toStringAsFixed(0)} JOD',
                                    style: const TextStyle(
                                      fontSize: 16,
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
                                        : Stream<QuerySnapshot>.empty(),
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
      ),
    );
  }
}

class NotiService {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // Initialization
  Future<void> initNotification() async {
    if (_isInitialized) return; // prevent re-initialization

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'daily_channel_id', // Same ID as in notificationDetails
      'Daily Notifications',
      description: 'Daily Notification Channel',
      importance: Importance.max,
    );

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Prepare initialization settings
    const initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    // Initialize the plugin
    await notificationsPlugin.initialize(initSettings);
    _isInitialized = true;
  }

  // Notifications Detail setup
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel_id',
        'Daily Notifications',
        channelDescription: 'Daily Notification Channel',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  // Show notification
  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    try {
      print('Attempting to show notification...');
      await notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails(),
      );
      print('Notification shown successfully.');
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  Future<void> checkPendingNotifications(String userId) async {
    final firestore = FirebaseFirestore.instance;
    final notifications = await firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId) // Only fetch notifications for the seller
        .where('read', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      final data = doc.data();
      await showNotification(
        title: data['title'],
        body: data['body'],
      );
      // Mark the notification as read
      await doc.reference.update({'read': true});
    }
  }
}