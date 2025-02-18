import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    required this.receiverPickUpLocation,
    required this.orderID,
    this.deliveryInfos, // Make it optional with `?`
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
  final Timestamp timestamp;
  final String receiverPickUpLocation;
  final String orderID;
  final Map<String, dynamic>? deliveryInfos; // Make it nullable

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


late String _orderStatus; // Store the order status in the state

  @override
  void initState() {
    super.initState();
    _orderStatus = widget.orderStatus; // Initialize with the passed value
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
                        Text(widget.receiverPickUpLocation),
                      ],
                    ),

                    if(widget.orderStatus == "confirmed" || widget.orderStatus == "picked up" || widget.orderStatus == "awaiting acknowledgment")
                    const SizedBox(height: 15,),
                      
                      
                    if(widget.orderStatus == "confirmed" || widget.orderStatus == "picked up" || widget.orderStatus == "awaiting acknowledgment")
                    const Divider(),

                    if(widget.orderStatus == "confirmed" || widget.orderStatus == "picked up" || widget.orderStatus == "awaiting acknowledgment")
                    const SizedBox(height: 15,),

                    if(widget.orderStatus == "confirmed" || widget.orderStatus == "picked up" || widget.orderStatus == "awaiting acknowledgment")
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundImage: widget.deliveryInfos?['image_url'] != null && widget.deliveryInfos!['image_url'].isNotEmpty
                              ? NetworkImage(widget.deliveryInfos!['image_url']) as ImageProvider
                              : const AssetImage('assets/images/profile_placeholder.jpg'),
                        ),
                        Text(
                          widget.deliveryInfos!['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),


                    if(widget.orderStatus == "confirmed" || widget.orderStatus == "picked up" || widget.orderStatus == "awaiting acknowledgment")
                    const SizedBox(height: 16,),

                    if(widget.orderStatus == "confirmed" || widget.orderStatus == "picked up" || widget.orderStatus == "awaiting acknowledgment")
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text('${widget.deliveryInfos!['Vehicle_Infos']['vehicle_type']} : ${widget.deliveryInfos!['Vehicle_Infos']['vehicle_model']}',
                           style: const TextStyle(
                            fontWeight: FontWeight.bold,
                           ),
                           ),
                           const Spacer(),
                          // In the build method, update the Row that displays the vehicle color
                            Row(
                              children: [
                                Text('Color: ${widget.deliveryInfos!['Vehicle_Infos']['Vehicle_Color']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8), // Add some spacing between the text and the circle
                                Container(
                                  width: 20, // Diameter of the circle
                                  height: 20, // Diameter of the circle
                                  decoration: BoxDecoration(
                                    color: _getColorFromString(widget.deliveryInfos!['Vehicle_Infos']['Vehicle_Color']), // Parse the color
                                    shape: BoxShape.circle, // Make it a circle
                                  ),
                                ),
                              ],
                            ),
                                                    ],
                      ),
                    ),

                    if(widget.orderStatus == "confirmed" || widget.orderStatus == "picked up" || widget.orderStatus == "awaiting acknowledgment")
                    const SizedBox(height: 16,),

                    if(widget.orderStatus == "confirmed" || widget.orderStatus == "picked up" || widget.orderStatus == "awaiting acknowledgment")
                    Padding(
                    padding: const EdgeInsets.only(left: 20 , right: 22),
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
                              // fontSize: 16, // Adjust the font size as needed
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_orderStatus == "awaiting acknowledgment")
                  const SizedBox(height: 30,),

                  if (_orderStatus == "awaiting acknowledgment")
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Update the order status to "delivered"
                          await FirebaseFirestore.instance
                              .collection('orders')
                              .doc(widget.orderID)
                              .update({
                                'status': 'delivered',
                              });

                          // Show a success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order acknowledged as delivered.'),
                            ),
                          );

                          // Update the local state
                          setState(() {
                            _orderStatus = 'delivered';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Acknowledge Receipt'),
                      ),
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
                    if(widget.orderStatus == "pending")
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 12),
                      width: double.infinity,
                      color: Colors.blueGrey[100],
                      child: Row(
                        children: [
                          Text('Order Status : ${widget.orderStatus}' ,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),

                     if(widget.orderStatus == "delivered")
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 12),
                      width: double.infinity,
                      color: Colors.green[400],
                      child: Row(
                        children: [
                          Text('Order Status : ${widget.orderStatus}' ,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),

                     if(widget.orderStatus == "canceled")
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 12),
                      width: double.infinity,
                       color: Colors.red[200],
                      child: Row(
                        children: [
                          Text('Order Status : ${widget.orderStatus}' ,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if(widget.orderStatus == "picked up")
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 12),
                      width: double.infinity,
                      color: Colors.orange[300],
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
                          const SizedBox(height: 14,),
                          Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delivery_dining_sharp, color: Colors.green[600]),
                          const SizedBox(width: 6),
                          const Text(
                            'Captain is on his way.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                        ],
                      ),
                    ),

                    if(widget.orderStatus == "confirmed")
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 12),
                      width: double.infinity,
                      color: const Color.fromARGB(255, 162, 210, 233),
                      child: Row(
                        children: [
                          Text('Order Status : ${widget.orderStatus}' ,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),


                    const SizedBox(height: 8,),
                    if(widget.paymentStatus == "held")
                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 12),
                      width: double.infinity,
                      color: Colors.blueGrey[100],
                     child: Row(
                        children: [
                          Text('Payment Status : ${widget.paymentStatus}' ,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                   ),

                  if(widget.paymentStatus == "released")
                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 12),
                      width: double.infinity,
                     color: Colors.green[400],
                     child: Row(
                        children: [
                          Text('Payment Status : ${widget.paymentStatus}' ,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                   ),

                    if(widget.paymentStatus == "refunded")
                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 12),
                      width: double.infinity,
                     color: Colors.red[200],
                     child: Row(
                        children: [
                          Text('Payment Status : ${widget.paymentStatus}' ,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
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