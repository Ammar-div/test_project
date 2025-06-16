import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lottie/lottie.dart';
import 'package:test_project/screens/HomeScreen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SellProduct extends StatefulWidget {
  const SellProduct({
    super.key,
    required this.sellerUserId,
    required this.sellerEmail,
    required this.sellerlName,
  });

  final String sellerUserId;
  final String sellerEmail;
  final String sellerlName;

  @override
  State<SellProduct> createState() => _SellProductState();
}

class _SellProductState extends State<SellProduct> {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream? categoriesStream;

  Future<Stream<QuerySnapshot>> getCategoryDetails() async {
    return await FirebaseFirestore.instance
        .collection("categories")
        .where("deleted_at", isNull: true)
        .snapshots();
  }

  getOnTheLoad() async {
    categoriesStream = await getCategoryDetails();
    setState(() {});
  }

  @override
  void initState() {
    getOnTheLoad();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        title: const Text('Sell Product'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: StreamBuilder(
          stream: categoriesStream,
          builder: (context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
              return const Center(child: Text('No Available Categories'));
            }

            // Combine the header text and categories into a single list
            final List<Widget> items = [
              // Header Text
              Text(
                'What Product you want to sell',
                style: TextStyle(
                  fontSize: 25.sp,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 18.h),
            ];

            // Add categories to the list
            for (var i = 0; i < snapshot.data.docs.length; i++) {
              final db = snapshot.data.docs[i];
              final imageUrl =
                  db["imageUrl"] ?? 'https://placeholder.com/placeholder.jpg';
              final nameOfTheCategory = db["name"] ?? 'Unnamed Category';
              final categoryId = db.id; // Assuming the document has an ID

              items.add(
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Navigate to the SellProductCont screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SellProductCont(
                              categoryId: categoryId,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          side: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .primary, // Border color
                            width: 2.w, // Border width
                          ),
                        ),
                        clipBehavior: Clip.hardEdge,
                        elevation: 2,
                        child: Column(
                          children: [
                            // Image with individual loading indicator
                            Image.network(
                              imageUrl,
                              height: 300.h,
                              width: double.infinity.w,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.error,
                                      size: 50, color: Colors.red),
                                );
                              },
                            ),
                            SizedBox(height: 8.h),
                            // Add a top border to the Text widget
                            Container(
                              width: double
                                  .infinity.w, // Make the container full width
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary, // Border color
                                    width: 2.w, // Border width
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8), // Add padding
                                child: Text(
                                  nameOfTheCategory,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                        height: 25.sp), // Add vertical space after each card
                  ],
                ),
              );
            }

            // Use a ListView to display all items
            return ListView(
              padding: const EdgeInsets.all(0), // Remove default padding
              children: items,
            );
          },
        ),
      ),
    );
  }
}

final List<String> pickUpLocation = [
  "Al Yasmin",
  "Nazzal",
  "Al Moqabalain",
  "Al Abdali",
  "Al Shmesani",
  "Jabal Amman",
  "Jabal Al Hadid",
  "Jabal Al Husain",
  "Al Akhdar",
  "Al Quesmeh",
  "Abdoun",
  "Tla'a Al Ali",
  "Wadi Al Saer",
  "Abu Nussair",
  "Al Muhagerein",
  "Al Mouaqar",
  "Wast Al Balad",
  "Al Wehdat",
  "Naour",
  "Ras Al Ein",
  "Marka",
  "Marg Al Hamam",
  "Sahab",
  "Shafa Badran",
  "Soualih",
  "Al Madina Al Riadiah",
  "Al Madina Al Tibiah",
  "Tabarbor",
];

enum ProductStatus { Used, New }

enum HowMuchUsed {
  oneWeek('1 week'),
  twoWeeks('2 weeks'),
  threeWeeks('3 weeks'),
  oneMonth('1 month'),
  twoMonths('2 months'),
  threeMonths('3 months'),
  fourMonths('4 months'),
  fiveMonths('5 months'),
  sixMonths('6 months'),
  sevenMonths('7 months'),
  eightMonths('8 months'),
  nineMonths('9 months'),
  tenMonths('10 months'),
  elevenMonths('11 months'),
  oneYear('1 year'),
  oneYearAndThreeMonths('1.3 year'),
  oneYearAndSixMonths('1.6 year'),
  twoYears('+2 years'),
  threeYears('+3 years');

  final String displayName;

  const HowMuchUsed(this.displayName);

  @override
  String toString() => displayName;
}

class SellProductCont extends StatefulWidget {
  const SellProductCont({super.key, required this.categoryId});

  final String categoryId;

  @override
  State<SellProductCont> createState() => _SellProductContState();
}

class _SellProductContState extends State<SellProductCont> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController productPriceController;
  late TextEditingController productNameController;
  late TextEditingController productDescriptionController;
  late TextEditingController quantityController;
  late TextEditingController searchController; // Controller for search bar

  var _isUpdating = false;
  List<File> _selectedImages = []; // Store multiple images
//  var _selectedProductStatus = ProductStatus.New; // Default status
  ProductStatus? _selectedProductStatus; // Make it nullable
  HowMuchUsed? _selectedHowMuchUsed; // Nullable variable for HowMuchUsed
  String? _selectedPickUpLocation;
  List<String> filteredPickUpLocations = []; // Filtered list for search

  // List of product statuses
  final List<String> productOrderStatus = [
    "Not requested yet",
    "It has been purchased ",
    "It has been favorited",
    "Sold",
  ];

  @override
  void initState() {
    super.initState();
    productPriceController = TextEditingController();
    productNameController = TextEditingController();
    productDescriptionController = TextEditingController();
    quantityController = TextEditingController();
    searchController = TextEditingController();
    filteredPickUpLocations = pickUpLocation;
  }

  @override
  void dispose() {
    productPriceController.dispose();
    productNameController.dispose();
    productDescriptionController.dispose();
    quantityController.dispose();
    searchController.dispose();
    super.dispose();
  }

// Function to save card information
  Future<void> _saveCardInformation() async {
    try {
      // Create a PaymentMethod using Stripe
      final paymentMethod = await stripe.Stripe.instance.createPaymentMethod(
        params: stripe.PaymentMethodParams.card(
          paymentMethodData: stripe.PaymentMethodData(
            billingDetails: stripe.BillingDetails(
              email: FirebaseAuth.instance.currentUser?.email,
            ),
          ),
        ),
      );

      // Save the PaymentMethod ID to Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'stripePaymentMethodId': paymentMethod.id,
        });
      }

      showToastrMessage("Card information saved successfully.");
    } catch (e) {
      showToastrMessage("Failed to save card information: $e");
    }
  }

  // Function to filter locations based on search input
  void _filterLocations(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredPickUpLocations = List.from(pickUpLocation);
      } else {
        filteredPickUpLocations = pickUpLocation
            .where((location) =>
                location.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // Function to show the searchable dropdown dialog
  Future<void> _showSearchableDropdown(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Pick Up Location'),
              content: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5.h,
                width: MediaQuery.of(context).size.width * 0.8.w,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search for a location...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (query) {
                        setState(() {
                          _filterLocations(query);
                        });
                      },
                    ),
                    SizedBox(height: 10.h),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredPickUpLocations.length,
                        itemBuilder: (context, index) {
                          final location = filteredPickUpLocations[index];
                          return ListTile(
                            title: Text(location),
                            onTap: () {
                              // ✅ Update main widget state
                              this.setState(() {
                                _selectedPickUpLocation = location;
                              });

                              // Clear search and reset list
                              setState(() {
                                searchController.clear();
                                filteredPickUpLocations =
                                    List.from(pickUpLocation);
                              });

                              Navigator.pop(context); // Close dialog
                            },
                          );
                        },
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
  }

  Future<void> _pickImageFromCamera() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      setState(() {
        _selectedImages
            .add(File(pickedImage.path)); // Add the image to the list
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final pickedImages =
        await ImagePicker().pickMultiImage(); // Allow multiple image selection
    setState(() {
      _selectedImages.addAll(pickedImages
          .map((image) => File(image.path))); // Add all images to the list
    });
  }

  Future<List<String>> _uploadImages(List<File> images) async {
    List<String> imageUrls = [];

    for (var image in images) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('product_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      await ref.putFile(image);
      final url = await ref.getDownloadURL();
      imageUrls.add(url);
    }

    // After all uploads are done, call the Flask API
    try {
      print('Calling Flask API to update features...');
      final response = await http.post(
        Uri.parse('http://172.20.10.2:5001/update-features'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('API call successful: ${response.body}');
      } else {
        print('API call failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error calling API: $e');
    }

    return imageUrls;
  }

  void showToastrMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: const Color.fromARGB(255, 106, 179, 116),
      textColor: const Color.fromARGB(255, 255, 255, 255),
      fontSize: 16.0.sp,
    );
  }

  Future<void> _createProduct() async {
    if (_formKey.currentState?.validate() != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide valid information')),
      );
      return;
    }

    // Validate price input
    double? productPrice;
    try {
      productPrice = double.parse(productPriceController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid price format')),
      );
      return;
    }

    // Check if at least one image is selected
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }

    try {
      // Show a loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: SizedBox(
            height: 150.h,
            child: Lottie.network(
                'https://lottie.host/635ac215-31e4-41bc-9ee4-a4fa4ddc9f76/8ki4C5LVhJ.json'),
          ),
        ),
      );

      // Save card information
      await _saveCardInformation();

      // Fetch current user details
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      final userId = user.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User details not found')),
        );
        return;
      }

      final email = userDoc['email'] ?? 'N/A';
      final name = userDoc['name'] ?? 'N/A';
      final phoneNumber = userDoc['phone_number'];

      // Upload images and get their URLs
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages(_selectedImages);
      }

      // Convert the enum to a string
      final statusString = _selectedProductStatus?.toString().split('.').last;

      final howMuchUsedString = _selectedProductStatus == ProductStatus.Used
          ? _selectedHowMuchUsed?.toString()
          : null;

      // Save product details in Firestore
      final productInfo = {
        "name": productNameController.text,
        "price": productPrice,
        "categoryId": widget.categoryId,
        "description": productDescriptionController.text,
        'publishDate': Timestamp.fromDate(DateTime.now()),
        "imageUrls": imageUrls,
        "seller_ifos": {
          "seller_id": userId,
          "seller_name": name,
          "seller_email": email,
          "seller_pick_up_location": _selectedPickUpLocation,
          "seller_phone_number": phoneNumber,
        },
        "status": statusString,
        "how_much_used": howMuchUsedString,
        "quantity": int.parse(quantityController.text),
        "product_order_status": "Not requested yet",
        "deleted_at": null
      };
      final docRef = FirebaseFirestore.instance.collection("products").doc();
      await docRef.set(productInfo);

      // Close loading indicator
      Navigator.pop(context);

      showToastrMessage("Your product has been posted successfully.");

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (ctx) => const HomeScreen(),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading indicator if an error occurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create product: $e')),
      );
    }
  }

  // Helper method to create a bullet point
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(fontSize: 30.sp),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16.sp),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        title: const Text('Product Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SizedBox(height: 16.h),
              Text(
                'Add Images',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 30.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBulletPoint(
                      'The first image you take is the image that will appear in the main page.'),
                ],
              ),
              SizedBox(height: 30.h),
              // Display selected images
              if (_selectedImages.isNotEmpty)
                SizedBox(
                  height: 130.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Stack(
                          children: [
                            Image.file(
                              _selectedImages[index],
                              width: 130.w,
                              height: 130.h,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _selectedImages
                                        .removeAt(index); // Remove the image
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              SizedBox(height: 18.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImageFromCamera,
                    icon: const Icon(Icons.camera),
                    label: const Text('Camera'),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo),
                    label: const Text('Gallery'),
                  ),
                ],
              ),
              SizedBox(height: 30.h),
              TextFormField(
                controller: productNameController,
                decoration: const InputDecoration(labelText: 'Main Title'),
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This section is required.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 40.h),
              TextFormField(
                controller: productDescriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Write the description of your product',
                  alignLabelWithHint: true,
                  border:
                      const OutlineInputBorder(), // Add a border for better visibility

                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      productDescriptionController.clear();
                    },
                  ),
                ),
                maxLines: null, // Allows the field to expand as needed
                minLines: 3, // Starts with 3 lines
                keyboardType: TextInputType.multiline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This section is required.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 25.h),

              // Dropdown for ProductStatus with hint text
              DropdownButtonFormField<ProductStatus?>(
                value: _selectedProductStatus, // Nullable value
                decoration: const InputDecoration(
                  labelText: 'Product Status',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Select Product Status'), // Hint text
                items: ProductStatus.values.map((status) {
                  return DropdownMenuItem<ProductStatus>(
                    value: status,
                    child: Text(status.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProductStatus = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a product status.';
                  }
                  return null;
                },
              ),

              SizedBox(height: 25.h),
              // Conditionally display HowMuchUsed dropdown
              if (_selectedProductStatus == ProductStatus.Used)
                DropdownButtonFormField<HowMuchUsed?>(
                  value: _selectedHowMuchUsed,
                  decoration: const InputDecoration(
                    labelText: 'How Much Used',
                    border: OutlineInputBorder(),
                  ),
                  hint: Text('Select how much the product has been used',
                      style: TextStyle(fontSize: 12.sp)),
                  items: HowMuchUsed.values.map((usage) {
                    return DropdownMenuItem<HowMuchUsed>(
                      value: usage,
                      child: Text(usage.toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedHowMuchUsed = value;
                    });
                  },
                  validator: (value) {
                    if (_selectedProductStatus == ProductStatus.Used &&
                        value == null) {
                      return 'Please select how much the product has been used.';
                    }
                    return null;
                  },
                ),

              if (_selectedProductStatus == ProductStatus.Used)
                SizedBox(height: 25.h),

              TextFormField(
                controller: quantityController, // Add a controller if needed
                decoration: const InputDecoration(
                  labelText: 'Number of Products',
                  hintText: 'Enter the number of products to sell',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the number of products.';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid number greater than zero.';
                  }
                  return null;
                },
              ),

              SizedBox(height: 25.h),

              // Searchable Dropdown for Pick Up Location
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pick up location',
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  SizedBox(height: 8.h),
                  InkWell(
                    onTap: () => _showSearchableDropdown(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      child: Text(
                        _selectedPickUpLocation ?? 'Select pick up location',
                        style: TextStyle(
                          color: _selectedPickUpLocation != null
                              ? Colors.black
                              : const Color.fromARGB(255, 97, 81, 73),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Add Card Input Field
              SizedBox(height: 25.h),
              stripe.CardField(
                onCardChanged: (card) {
                  // Handle card changes if needed
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Card Details',
                ),
              ),

              SizedBox(height: 25.h),

              TextFormField(
                controller: productPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This section is required';
                  }
                  if (double.parse(value) <= 0) {
                    return 'The value must be greater than zero.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity.w,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2.w,
                      ),
                    ),
                  ),
                  onPressed: () {
                    _createProduct();
                  },
                  child: _isUpdating
                      ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Post'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
