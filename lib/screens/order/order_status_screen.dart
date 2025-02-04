import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({
    super.key,
    required this.imageUrls,
    required this.mainTitle,
    required this.description,
    required this.totalAmount,
    required this.quantity,
    required this.productStatus,
    required this.howMuchUsed,
    required this.receiverName,
    required this.receiverPhoneNumber,
    required this.receiverEmail,
    required this.orderStatus,
    required this.paymentStatus,
    required this.timestamp,
  });

  final List<String> imageUrls;
  final String mainTitle;
  final String description;
  final double totalAmount;
  final int quantity;
  final String productStatus;
  final String howMuchUsed;
  final String receiverName;
  final String receiverPhoneNumber;
  final String receiverEmail;
  final String orderStatus;
  final String paymentStatus;
  final Timestamp timestamp; // Add this line

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  bool _isExpanded = false;
  bool _isOverflowing = false;


   // Helper function to format the timestamp
  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate(); // Convert Timestamp to DateTime
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} | ${dateTime.hour}:${dateTime.minute}'; // Customize the format as needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Status'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Container(
                // color: Theme.of(context).colorScheme.primaryContainer,
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
                            return Container(
                              width: MediaQuery.of(context).size.width,
                              margin: const EdgeInsets.symmetric(horizontal: 5.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.mainTitle,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Use a TextPainter to measure the text dimensions
                        final textPainter = TextPainter(
                          text: TextSpan(
                            text: widget.description,
                            style: const TextStyle(fontSize: 16),
                          ),
                          maxLines: 4, // Match the maxLines in the Text widget
                          textDirection: TextDirection.ltr,
                        );
          
                        // Layout the text to measure its dimensions
                        textPainter.layout(maxWidth: constraints.maxWidth);
          
                        // Check if the text is overflowing
                        final isOverflowing = textPainter.didExceedMaxLines;
          
                        // Update _isOverflowing if necessary
                        if (_isOverflowing != isOverflowing) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {
                              _isOverflowing = isOverflowing;
                            });
                          });
                        }
          
                        return Column(
                          children: [
                            AnimatedCrossFade(
                              firstChild: Text(
                                widget.description,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              secondChild: Text(
                                widget.description,
                                textAlign: TextAlign.center,
                              ),
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
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
          
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10 , vertical: 20),
                decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(8),
                    ),
                child: Column(
                  children: [ 
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('Total Amount (JOD)'),
                          Text('Quantity'),
                      ],
                    ),
                       const SizedBox(height: 8), // Add some spacing
                       const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25),
                          child: Divider( // Add a divider here
                            thickness: 0.5, // Thickness of the line
                            color: Color.fromARGB(255, 0, 0, 0), // Color of the line
                          ),
                        ),
                        const SizedBox(height: 8), // Add some spacing


                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(widget.totalAmount.toStringAsFixed(0)),
                        Text(widget.quantity.toString()),
                      ],
                    ),
                            
                  ],
                ),
              ),

              const SizedBox(height: 22,),
               Container(
                padding: const EdgeInsets.symmetric(horizontal: 10 , vertical: 20),
                decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(8),
                    ),
                child: Column(
                  children: [ 
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('Product Status'),
                          Text('How much used'),
                      ],
                    ),
                       const SizedBox(height: 8), // Add some spacing
                       const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25),
                          child: Divider( // Add a divider here
                            thickness: 0.5, // Thickness of the line
                            color: Color.fromARGB(255, 0, 0, 0), // Color of the line
                          ),
                        ),
                        const SizedBox(height: 8), // Add some spacing


                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(widget.productStatus),
                        Text(widget.howMuchUsed),
                      ],
                    ),           
                  ],
                ),
              ),
              const SizedBox(height: 22,),

               Container(
                padding: const EdgeInsets.symmetric(horizontal: 10 , vertical: 20),
                decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(8),
                    ),
                child: Column(
                  children: [ 
                    const Text('Delivered to : ',
                    textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),                    
                      ),
                       const SizedBox(height: 8), // Add some spacing

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(widget.receiverName),
                        Text(widget.receiverPhoneNumber),
                      ],
                    ),

                    const SizedBox(height: 8,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(widget.receiverEmail),
                        const Text('                       '),
                      ],
                    ),
                            
                  ],
                ),
              ),

              const SizedBox(height: 22,),

               Container(
                padding: const EdgeInsets.symmetric(horizontal: 20 , vertical: 20),
                decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(8),
                    ),
                child: Column(
                  children: [ 

                    Row(
                      children: [
                        Text('Order Status : ${widget.orderStatus}' ,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8,),
                   Row(
                      children: [
                        Text('Payment Status : ${widget.paymentStatus}' ,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8,),

                    Row(
                      children: [
                        Text(
                          'Ordered Date: ${_formatTimestamp(widget.timestamp)}', // Format and display the timestamp
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                            
                  ],
                ),
              ),
              const SizedBox(height: 22,),
            ],
          ),
        ),
      ),
    );
  }
}