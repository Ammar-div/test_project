import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_project/screens/admin/pc_category/all_categories.dart';
import 'package:test_project/widgets/main_drawr.dart';
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

class _ProductDetailScreenState extends State<ProductDetailScreen> {
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
                  Row(
                    children: [
                      Text(
                        '‫${widget.productPrice.toStringAsFixed(2)} JOD',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),

                      const Spacer(),

                      IconButton(onPressed: () {},
                      icon: const Icon(Icons.favorite_border_outlined , 
                      size: 26,
                      ),
                      
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Center(
                    child: SizedBox(
                      width: screenWidth * 0.80,
                      child: ElevatedButton(
                        onPressed: () {},
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
                      
                      Row(
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
                        '‫${widget.productPrice.toStringAsFixed(2)} JOD',
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

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}