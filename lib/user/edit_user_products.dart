import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';



final List<String> pickUpLocation = [
  "Al Yasmin",
  "Nazal",
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
];


enum ProductStatus {Used , New}


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


class EditUserProducts extends StatefulWidget {
  EditUserProducts({super.key , required this.productPriceController,
  required this.productNameController,
  required this.productDescriptionController,
  required this.quantityController,
  required this.categoryId,
  required this.initialImageUrls,
  required this.productId,
  });

  
  late TextEditingController productPriceController;
  late TextEditingController productNameController;
  late TextEditingController productDescriptionController;
  late TextEditingController quantityController;
  final String categoryId;
  final List<String> initialImageUrls; 
  final String productId;

  @override
  State<EditUserProducts> createState() => _EditUserProductsState();
}

class _EditUserProductsState extends State<EditUserProducts> {
final _formKey = GlobalKey<FormState>();
  var _isUpdating = false;
  List<File> _selectedImages = []; // Store newly added images
  List<String> _imageUrls = []; // Store image URLs (initial + newly uploaded)
  ProductStatus? _selectedProductStatus;
  HowMuchUsed? _selectedHowMuchUsed;
     String? _selectedPickUpLocation;

  @override
void initState() {
  super.initState();
  _imageUrls = widget.initialImageUrls; // Initialize with passed images
}

Future<void> _pickImageFromCamera() async {
  final pickedImage = await ImagePicker().pickImage(source: ImageSource.camera);
  if (pickedImage != null) {
    setState(() {
      _selectedImages.add(File(pickedImage.path)); // Add the image to the list
    });
  }
}

Future<void> _pickImageFromGallery() async {
  final pickedImages = await ImagePicker().pickMultiImage(); // Allow multiple image selection
  if (pickedImages != null) {
    setState(() {
      _selectedImages.addAll(pickedImages.map((image) => File(image.path))); // Add all images to the list
    });
  }
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

 Future<void> _editProduct() async {
  if (_formKey.currentState?.validate() != true) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please provide valid information')),
    );
    return;
  }

  // Validate price input
  double? productPrice;
  try {
    productPrice = double.parse(widget.productPriceController.text);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid price format')),
    );
    return;
  }

  // Check if at least one image is selected
  if (_imageUrls.isEmpty && _selectedImages.isEmpty) {
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
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Upload new images and get their URLs
    List<String> newImageUrls = [];
    if (_selectedImages.isNotEmpty) {
      newImageUrls = await _uploadImages(_selectedImages);
    }

    // Combine initial and new image URLs
    final allImageUrls = [..._imageUrls, ...newImageUrls];

    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final sellerName = userDoc['name'];

    // Save product details in Firestore
    final productInfo = {
    "name": widget.productNameController.text,
    "price": productPrice,
    "categoryId": widget.categoryId,
    "description": widget.productDescriptionController.text,
    "publishDate": DateTime.now(),
    "imageUrls": allImageUrls,
    "seller_ifos": {
      "seller_id": FirebaseAuth.instance.currentUser!.uid,
      "seller_name": sellerName,
      "seller_email": FirebaseAuth.instance.currentUser!.email ?? 'N/A',
      "seller_pick_up_location": _selectedPickUpLocation, // Add the selected pick-up location
    },
    "status": _selectedProductStatus?.toString().split('.').last ?? 'New', // Default to New
    "how_much_used": _selectedProductStatus == ProductStatus.Used
        ? _selectedHowMuchUsed?.toString() ?? '1 week' // Default to 1 week
        : null,
    "quantity": int.parse(widget.quantityController.text),
    "product_order_status": "Not requested yet",
  };

    // Update the existing document
    final docRef = FirebaseFirestore.instance
        .collection("products")
        .doc(widget.productId); // Use the product ID
    await docRef.update(productInfo); // Use update() instead of set()

    // Close loading indicator
    Navigator.pop(context);

    showToastrMessage("Your product has been updated successfully.");

    Navigator.of(context).pop();
  } catch (e) {
    Navigator.pop(context); // Close loading indicator if an error occurs
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to update product: $e')),
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
          style: TextStyle(fontSize: 30.h),
        ),
        Expanded(
          child: Text(
            text,
            style:  TextStyle(fontSize: 16.h),
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
      title: const Text('Edit Your Product'),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
             SizedBox(height: 16.h),
             Text('Add Images',
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
                _buildBulletPoint('The first image you take is the image that will appear in the main page.'),
              ],
            ),
             SizedBox(height: 30.h),
            if (_imageUrls.isNotEmpty || _selectedImages.isNotEmpty)
              SizedBox(
                height: 130.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageUrls.length + _selectedImages.length,
                  itemBuilder: (context, index) {
                    if (index < _imageUrls.length) {
                      // Display initial images
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: Image.network(
                                _imageUrls[index],
                                width: 130.w,
                                height: 130.h,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _imageUrls.removeAt(index); // Remove the image
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Display newly added images
                      final fileIndex = index - _imageUrls.length;
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: Image.file(
                                _selectedImages[fileIndex],
                                width: 130.w,
                                height: 130.h,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _selectedImages.removeAt(fileIndex); // Remove the image
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
             SizedBox(height: 18.h),

            // Buttons to add more images
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
              controller: widget.productNameController,
              decoration: const InputDecoration(labelText: 'Main Title'),
              keyboardType: TextInputType.name,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'This section is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: 40),
            TextFormField(
              controller: widget.productDescriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Write the description of your product',
                alignLabelWithHint: true,
                border: OutlineInputBorder(), // Add a border for better visibility
                 
                 suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    widget.productDescriptionController.clear();
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
            const SizedBox(height: 25),

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

            const SizedBox(height: 25),
              // Conditionally display HowMuchUsed dropdown
              if (_selectedProductStatus == ProductStatus.Used)
                DropdownButtonFormField<HowMuchUsed?>(
                  value: _selectedHowMuchUsed,
                  decoration: const InputDecoration(
                    labelText: 'How Much Used',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Select how much the product has been used'),
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
                    if (_selectedProductStatus == ProductStatus.Used && value == null) {
                      return 'Please select how much the product has been used.';
                    }
                    return null;
                  },
                ),
              if (_selectedProductStatus == ProductStatus.Used)
            const SizedBox(height: 25),

                 TextFormField(
                controller: widget.quantityController, // Use the quantity controller
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
                
              
            const SizedBox(height: 25),

              //pick up places
                 // Dropdown for Pick Up Location
                DropdownButtonFormField<String>(
                  value: _selectedPickUpLocation, // Selected value
                  decoration: const InputDecoration(
                    labelText: 'Pick up location',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Enter a location'), // Hint text
                  items: pickUpLocation.map((location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text(location), // Display the location name
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPickUpLocation = value; // Update the selected value
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a pick-up location.';
                    }
                    return null;
                  },
                ),
                
              
            const SizedBox(height: 25),

            TextFormField(
              controller: widget.productPriceController,
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
                  _editProduct();
                },
                child: _isUpdating
                    ?  SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Update'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}