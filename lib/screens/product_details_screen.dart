import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_project/screens/HomeScreen.dart';
import 'package:test_project/screens/auth_screen.dart';
import 'package:test_project/screens/order/pre_checkout.dart';
import 'package:carousel_slider/carousel_slider.dart';





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
      // Handle case where user is not logged in
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
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: Text(widget.productName),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CarouselSlider(
            options: CarouselOptions(
              height: 300,
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
                        borderRadius: BorderRadius.circular(8),
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
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.productName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 25),

                  // Conditionally display the Checkout button
                  if (!_isSeller)
                    Center(
                      child: SizedBox(
                        width: screenWidth * 0.80,
                        child: ElevatedButton(
                          onPressed: () async {
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
                              borderRadius: BorderRadius.circular(8),
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
                  const SizedBox(height: 20),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Status : ',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.status,
                              style: const TextStyle(
                                fontSize: 20,
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Number : ',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.quantity.toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Duration of use : ',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.howMuchUsed,
                          style: const TextStyle(
                            fontSize: 20,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: Text(widget.productName),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
             CarouselSlider(
                options: CarouselOptions(
                  height: 300,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 1.0,
                ),
                items: widget.imageUrls.map((imageUrl) {
                  return Builder(
                    builder: (BuildContext context) {
                      return
                      Hero(tag: widget.productId,
                       child:  Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
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
            
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.productName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                      Text(
                        '${widget.productPrice.toStringAsFixed(0)} JOD',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),

                  const SizedBox(height: 25),

                  const Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
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

                    const SizedBox(height: 30),


                     if(widget.productOrderStatus == "Not requested yet")
                    Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 16),
                          width: double.infinity,
                          color: Colors.blueGrey[100],
                          child: Row(
                            children: [
                              const Text(
                                'Product order status : ',
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

                   if(widget.productOrderStatus == "It has been purchased")
                   Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 16),
                          width: double.infinity,
                          color: Colors.green[400],
                          child: Row(
                            children: [
                              const Text(
                                'Product order status : ',
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

                     if(widget.productOrderStatus == "It has been purchased")
                      Padding(padding: const EdgeInsets.symmetric(vertical: 14),
                     child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                        Icon(Icons.delivery_dining_sharp , color: Colors.green[600],),
                        const SizedBox(width: 6,),
                         const Text('Your Delivery captin will contact you soon.',
                         textAlign: TextAlign.center,
                            ),
                       ],
                     ),
                      ),



                    if(widget.productOrderStatus == "It has been favorited")
                   Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 16),
                          width: double.infinity,
                          color: Colors.orange[300],
                          child: Row(
                            children: [
                              const Text(
                                'Product order status : ',
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
                   const SizedBox(height: 14,),

                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 16),
                    width: double.infinity,
                    color: Colors.blueGrey[100],
                     child: Row(
                            children: [
                              const Text(
                                'Status : ',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.status,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                   ),

                  const SizedBox(height: 14,),
                    Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 16),
                    width: double.infinity,
                    color: Colors.blueGrey[100],
                     child: Row(
                            children: [
                              const Text(
                                'Number : ',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.quantity.toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                   ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 16),
                    width: double.infinity,
                    color: Colors.blueGrey[100],
                     child: Row(
                            children: [
                              const Text(
                                'Duration of use : ',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.howMuchUsed,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                   ),

                   const SizedBox(height: 14,),
                 

                 Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 16),
                    width: double.infinity,
                    color: Colors.blueGrey[100],
                     child: Row(
                            children: [
                              const Text(
                                'Area : ',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.pickUpLocation,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                   ),
                  const SizedBox(height: 14,),
                 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}