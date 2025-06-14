import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_project/screens/HomeScreen.dart';
import 'package:test_project/screens/auth_screen.dart';
import 'package:test_project/screens/order/pre_checkout.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_project/constants/colors.dart';




class ProductDetailScreen extends StatefulWidget {
  final String productName;
  final double productPrice;
  final List<String> imageUrls;
  final String description;
  final String status;
  final String howMuchUsed;
  final int quantity;
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productName,
    required this.productPrice,
    required this.imageUrls,
    required this.description,
    required this.status,
    required this.howMuchUsed,
    required this.quantity,
    required this.productId,
  });

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFavorite = false;
  bool _isExpanded = false;
  bool _isOverflowing = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUserId;
  bool _isSeller = false;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final textPainter = TextPainter(
        text: TextSpan(text: widget.description, style: const TextStyle()),
        maxLines: 4,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: MediaQuery.of(context).size.width - 32);
      setState(() {
        _isOverflowing = textPainter.didExceedMaxLines;
      });
    });

    // Get the current user ID and check if it matches the seller_id
    _currentUserId = _auth.currentUser?.uid;
    _checkIfSeller();
  }

  Future<void> _checkIfSeller() async {
    DocumentSnapshot productDocumentObj = await _firestore.collection('products').doc(widget.productId).get();
    final sellerId = productDocumentObj["seller_ifos"]["seller_id"];

    setState(() {
      _isSeller = _currentUserId == sellerId;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Function to add/remove a product from favorites
Future<void> _toggleFavorite() async {
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
      .where('productId', isEqualTo: widget.productId);

  final favoriteSnapshot = await favoriteRef.get();

  if (favoriteSnapshot.docs.isEmpty) {
    // Add to favorites
    await _firestore.collection('favorites').add({
      'userId': user.uid,
      'productId': widget.productId,
      'productName': widget.productName,
      'productPrice': widget.productPrice,
      'imageUrl': widget.imageUrls[0],
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

  void _navigateToPreCheckout() async {
  DocumentSnapshot productDocumentObj = 
      await _firestore.collection('products').doc(widget.productId).get();
  final sellerId = productDocumentObj["seller_ifos"]["seller_id"];
  final imageUrl = widget.imageUrls[0];


  final user = FirebaseAuth.instance.currentUser;
  if(user != null)
  {
    if(user.uid == sellerId)
    {
      // owner of the product
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: 
      (ctx) => const HomeScreen(), ));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("The user can't buy his own product.")));
      return;
    }
  }

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (ctx) => PreCheckout(
        productMainTitle: widget.productName,
        totalAmount: widget.productPrice,
        productDescription: widget.description,
        imageUrl: imageUrl,
        productId: widget.productId,
        sellerId: sellerId,
        quantity: widget.quantity,
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: kBackgroundGrey,
      appBar: AppBar(
        backgroundColor: kPrimaryBlue,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios, color: kWhite),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CarouselSlider(
            options: CarouselOptions(
              height: 300.h,
              autoPlay: widget.imageUrls.length > 1, // Auto-play only if there is more than one image
              enlargeCenterPage: true,
              viewportFraction: 1.0,
            ),
            items: widget.imageUrls.map((imageUrl) {
              return Builder(
                builder: (BuildContext context) {
                  return Hero(
                    // Use a unique tag for each image by combining productId and index
                    tag: 'product-image-${widget.productId}-${widget.imageUrls.indexOf(imageUrl)}',
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        image: DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
             SizedBox(height: 20.h),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.productName,
                    style:  TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                   SizedBox(height: 8.h),
                  Row(
                    children: [
                      Text(
                        '${widget.productPrice.toStringAsFixed(0)} JOD',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Spacer(),
                      if (!_isSeller)
                      StreamBuilder<QuerySnapshot>(
                        stream: _auth.currentUser != null
                            ? _firestore
                                .collection('favorites')
                                .where('userId', isEqualTo: _auth.currentUser?.uid)
                                .where('productId', isEqualTo: widget.productId)
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
                                  await _firestore.collection('products').doc(widget.productId).get();
                                    final sellerId = productDocumentObj["seller_ifos"]["seller_id"];
                                     final user = FirebaseAuth.instance.currentUser;
                                      if(user != null)
                                      {
                                        if(user.uid == sellerId)
                                        {
                                          // owner of the product
                                          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: 
                                          (ctx) => const HomeScreen(), ));
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("The user can't favorite his own product.")));
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

                                      _toggleFavorite();
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
                   SizedBox(height: 25.h),

                  // Conditionally display the Checkout button
                  if (!_isSeller)
                    Center(
                      child: SizedBox(
                        width: screenWidth * 0.80.w,
                        child: ElevatedButton(
                          onPressed: () async {
                            final productDoc = await FirebaseFirestore.instance.collection('products').doc(widget.productId).get();
                            final productOrderStatus = productDoc['product_order_status'];

                            if(productOrderStatus == "delivered"
                              || productOrderStatus == "picked up" || productOrderStatus == "confirmed") {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('The product has been ordered')),
                              );
                              return;
                            }


                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) {
                                // Show a dialog if the user is not logged in
                                final result = await showDialog<Map<String, dynamic>>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Sign In Required'),
                                      content: const Text('You need to sign in to proceed with the checkout.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(); // Close the dialog
                                          },
                                          child: const Text(
                                            'Close',
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop(); // Close the dialog

                                            // Navigate to login screen
                                            final authResult = await Navigator.of(context).push<Map<String, dynamic>>(
                                              MaterialPageRoute(builder: (ctx) => const AuthScreen()),
                                            );

                                            // Check if login was successful and proceed to checkout
                                            if (authResult != null && authResult['success'] == true) {
                                              _navigateToPreCheckout();
                                            }
                                          },
                                          child: const Text(
                                            'Sign In',
                                            style: TextStyle(color: Colors.blue),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              } else {
                                _navigateToPreCheckout(); // Proceed to checkout if already logged in
                              }
                            },


                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            backgroundColor: const Color.fromARGB(255, 72, 110, 255),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: const Text(
                            'Checkout',
                            style: TextStyle(
                              color: Color.fromARGB(255, 234, 241, 255),
                            ),
                          ),
                        ),
                      ),
                    ),
                   SizedBox(height: 20.h),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                   SizedBox(height: 8.h),
                  AnimatedCrossFade(
                    firstChild: Text(
                      widget.description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    secondChild: Text(widget.description),
                    crossFadeState: _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                  if (_isOverflowing)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Text(_isExpanded ? 'Show Less' : 'Show More'),
                    ),
                   SizedBox(height: 30.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                             Text(
                              'Status : ',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.status,
                              style:  TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                             Text(
                              'Number : ',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.quantity.toString(),
                              style:  TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if(widget.howMuchUsed != 'Not specified')
                   SizedBox(height: 16.h),
                  if(widget.howMuchUsed != 'Not specified')
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                         Text(
                          'Duration of use : ',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.howMuchUsed,
                          style:  TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}








class AdvertisingProductDetailScreen extends StatefulWidget {
  final String productName;
  final double productPrice;
  final List<String> imageUrls;
  final String description;
  final String status;
  final String howMuchUsed;
  final int quantity;
  final String productId;
  final String productOrderStatus;
  final String pickUpLocation;
  final Map<String, dynamic>? deliveryInfos;

  const AdvertisingProductDetailScreen({
    super.key,
    required this.productName,
    required this.productPrice,
    required this.imageUrls,
    required this.description,
    required this.status,
    required this.howMuchUsed,
    required this.quantity,
    required this.productId,
    required this.productOrderStatus,
    required this.pickUpLocation,
    this.deliveryInfos,
  });

  @override
  _AdvertisingProductDetailScreenState createState() => _AdvertisingProductDetailScreenState();
}

class _AdvertisingProductDetailScreenState extends State<AdvertisingProductDetailScreen> {
  bool _isExpanded = false;
  bool _isOverflowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final textPainter = TextPainter(
        text: TextSpan(text: widget.description, style: const TextStyle()),
        maxLines: 4,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: MediaQuery.of(context).size.width - 32);
      setState(() {
        _isOverflowing = textPainter.didExceedMaxLines;
      });
    });
  }

  Future<int> _getFavoriteCount(String productId) async {
  final QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('favorites')
      .where('productId', isEqualTo: productId)
      .get();

  return snapshot.docs.length;
}

  // Helper function to map color names to Color objects
  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'brown':
        return Colors.brown;
      case 'silver':
        return Colors.grey;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      default:
        return Colors.grey; // Default color if the color name is not recognized
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
    body: SingleChildScrollView(
      child: Column(
        children: [
          // Back button at the top-left
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 30, left: 16),
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
            ),
          ),
           SizedBox(height: 10.h),
          CarouselSlider(
            options: CarouselOptions(
              height: 300.h,
              autoPlay: widget.imageUrls.length > 1,
              enlargeCenterPage: true,
              viewportFraction: 1.0,
            ),
            items: widget.imageUrls.map((imageUrl) {
              return Builder(
                builder: (BuildContext context) {
                  return Hero(
                    tag: widget.productId,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        image: DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
           SizedBox(height: 20.h),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.productName,
                  style:  TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                 SizedBox(height: 8.h),
                Text(
                  '${widget.productPrice.toStringAsFixed(0)} JOD',
                  style:  TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                 SizedBox(height: 25.h),
                // Display the number of users who favorited the product
                FutureBuilder<int>(
                  future: _getFavoriteCount(widget.productId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      final favoriteCount = snapshot.data ?? 0;
                      return Text(
                        '$favoriteCount users have favorited this product',
                        style:  TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      );
                    }
                  },
                ),
                 SizedBox(height: 25.h),
                 Text(
                  'Description',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18.sp,
                  ),
                ),
                 SizedBox(height: 8.h),
                AnimatedCrossFade(
                  firstChild: Text(
                    widget.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  secondChild: Text(widget.description),
                  crossFadeState: _isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
                if (_isOverflowing)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Text(_isExpanded ? 'Show Less' : 'Show More'),
                  ),
                 SizedBox(height: 30.h),
                if (widget.productOrderStatus == "Not requested yet")
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    width: double.infinity.w,
                    color: kPrimaryBlue.withOpacity(0.1),
                    child: Row(
                      children: [
                         Text(
                          'Order status : ',
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryBlue,
                          ),
                        ),
                        Text(
                          widget.productOrderStatus,
                          style:  TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.productOrderStatus == "It has been purchased")
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    width: double.infinity.w,
                    color: Colors.green[400],
                    child: Row(
                      children: [
                         Text(
                          'Product order status : ',
                          style: TextStyle(
                            fontSize: widget.productOrderStatus == "It has been purchased" ? 14.sp : 17.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.productOrderStatus,
                          style:  TextStyle(
                            fontSize: widget.productOrderStatus == "It has been purchased" ? 14.sp : 17.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.productOrderStatus == "confirmed")
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    width: double.infinity.w,
                    color: const Color.fromARGB(255, 162, 210, 233),
                    child: Row(
                      children: [
                        const Text(
                          'Order status : ',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.productOrderStatus,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.productOrderStatus == "confirmed")
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delivery_dining_sharp, color: Colors.green[600]),
                         SizedBox(width: 6.w),
                        const Text(
                          'Your Delivery captain will contact you soon.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                if (widget.productOrderStatus == "picked up")
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    width: double.infinity.w,
                    color: Colors.orange[300],
                    child: Row(
                      children: [
                         Text(
                          'Order status : ',
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.productOrderStatus,
                          style:  TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.productOrderStatus == "picked up")
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delivery_dining_sharp, color: Colors.green[600]),
                         SizedBox(width: 6.w),
                        const Text(
                          'Captain is now heading to the buyer.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                if (widget.productOrderStatus == "delivered")
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    width: double.infinity.w,
                    color: Colors.green[400],
                    child: Row(
                      children: [
                         Text(
                          'Order status : ',
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.productOrderStatus,
                          style:  TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),






                if (widget.productOrderStatus == "confirmed" || widget.productOrderStatus == "picked up")
                   SizedBox(height: 15.h),
                if (widget.productOrderStatus == "confirmed" || widget.productOrderStatus == "picked up")
                  const Divider(),
                if (widget.productOrderStatus == "confirmed" || widget.productOrderStatus == "picked up")
                   SizedBox(height: 15.h),
                if (widget.productOrderStatus == "confirmed" || widget.productOrderStatus == "picked up")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: widget.deliveryInfos?['image_url'] != null &&
                                widget.deliveryInfos!['image_url'].isNotEmpty
                            ? NetworkImage(widget.deliveryInfos!['image_url']) as ImageProvider
                            : const AssetImage('assets/images/profile_placeholder.jpg'),
                      ),
                      Text(
                        widget.deliveryInfos!['name'],
                        style:  TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.sp,
                        ),
                      ),
                    ],
                  ),
                if (widget.productOrderStatus == "confirmed" || widget.productOrderStatus == "picked up")
                   SizedBox(height: 16.h),
                if (widget.productOrderStatus == "confirmed" || widget.productOrderStatus == "picked up")
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          '${widget.deliveryInfos!['Vehicle_Infos']['vehicle_type']} : ${widget.deliveryInfos!['Vehicle_Infos']['vehicle_model']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              'Color: ${widget.deliveryInfos!['Vehicle_Infos']['Vehicle_Color']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                             SizedBox(width: 8.w),
                            Container(
                              width: 20.w,
                              height: 20.h,
                              decoration: BoxDecoration(
                                color: _getColorFromString(
                                    widget.deliveryInfos!['Vehicle_Infos']['Vehicle_Color']),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                if (widget.productOrderStatus == "confirmed" || widget.productOrderStatus == "picked up")
                   SizedBox(height: 16.h),
                if (widget.productOrderStatus == "confirmed" || widget.productOrderStatus == "picked up")
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 22),
                    child: Row(
                      children: [
                        Text(
                          'Number: ${widget.deliveryInfos!['Vehicle_Infos']['vehicle_number']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () async {
                            // Clean the phone number (remove non-numeric characters)
                            final String phoneNumber = widget.deliveryInfos!['phone_number'].replaceAll(RegExp(r'[^0-9]'), '');
                            final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

                            // Check if the device can launch the phone dialer
                            if (await canLaunchUrl(phoneUri)) {
                              await launchUrl(phoneUri);
                            } else {
                              // Handle the case where the device cannot make phone calls
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cannot make phone calls on this device.'),
                                ),
                              );
                            }
                          },
                          child: Text(
                            'Call: ${widget.deliveryInfos!['phone_number']}',
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.productOrderStatus == "confirmed" || widget.productOrderStatus == "picked up")
                   SizedBox(height: 16.h),
                if (widget.productOrderStatus == "confirmed" || widget.productOrderStatus == "picked up")
                  const Divider(),
                if (widget.productOrderStatus == "confirmed" || widget.productOrderStatus == "picked up")
                   SizedBox(height: 11.h),
                if (widget.productOrderStatus == "It has been favorited")
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    width: double.infinity.w,
                    color: Colors.orange[300],
                    child: Row(
                      children: [
                         Text(
                          'Order status : ',
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.productOrderStatus,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                 SizedBox(height: 14.sp),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  width: double.infinity.w,
                  color: Colors.blueGrey[100],
                  child: Row(
                    children: [
                       Text(
                        'Product Status : ',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.status,
                        style:  TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                 SizedBox(height: 14.h),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  width: double.infinity.w,
                  color: Colors.blueGrey[100],
                  child: Row(
                    children: [
                       Text(
                        'Number : ',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.quantity.toString(),
                        style:  TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                 SizedBox(height: 14.h),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  width: double.infinity.w,
                  color: Colors.blueGrey[100],
                  child: Row(
                    children: [
                       Text(
                        'Duration of use : ',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.howMuchUsed,
                        style:  TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                 SizedBox(height: 14.h),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  width: double.infinity.w,
                  color: Colors.blueGrey[100],
                  child: Row(
                    children: [
                       Text(
                        'Area : ',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.pickUpLocation,
                        style:  TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                 SizedBox(height: 14.h),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}