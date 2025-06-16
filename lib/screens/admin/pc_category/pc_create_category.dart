import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PcCreateCategory extends StatefulWidget {
  const PcCreateCategory({super.key});

  @override
  State<PcCreateCategory> createState() => _PcCreateCategoryState();
}

class _PcCreateCategoryState extends State<PcCreateCategory> {
  final _formKey = GlobalKey<FormState>();
  File? _selectedImage;
  String? _imageUrl;
  late TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(); // Initialize the controller
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  // Future<String> _uploadImageToStorage(File image) async {
  //   final fileName = DateTime.now().millisecondsSinceEpoch.toString();
  //   final ref = FirebaseStorage.instance.ref().child('category_images/$fileName');
  //   final uploadTask = await ref.putFile(image);
  //   return await ref.getDownloadURL(); // Return the uploaded image URL
  // }


  Future<String> _uploadImageToStorage(File image, String categoryName) async {
  final sanitizedCategoryName = categoryName.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
  final ref = FirebaseStorage.instance.ref().child('category_images/$sanitizedCategoryName');
  
  try {
    // Upload the file
    final uploadTask = await ref.putFile(image);
    // Get the download URL
    return await ref.getDownloadURL();
  } catch (e) {
    throw Exception('Failed to upload image: $e');
  }
}


  Future<void> _createCategory() async {
    if (_formKey.currentState?.validate() != true || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a name and select an image.')),
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

      // Upload image and get its URL
      final imageUrl = await _uploadImageToStorage(_selectedImage!, nameController.text);

      // Save category details in Firestore
      final categoryInfo = {
        "name": nameController.text,
        "imageUrl": imageUrl,
        "deleted_at":null,
      };
      final docRef = FirebaseFirestore.instance.collection("categories").doc();
      await docRef.set(categoryInfo);

      // Close loading indicator
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category created successfully!')),
      );

      // Clear fields
      setState(() {
        _selectedImage = null;
        nameController.clear();
      });
    } catch (e) {
      Navigator.pop(context); // Close loading indicator if an error occurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create category: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      color: Theme.of(context).colorScheme.onPrimaryContainer,
      padding: const EdgeInsets.only(top: 34),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Category'),
          elevation: 0, // Remove AppBar shadow
          backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer, // Match container color
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.only(left: 23, right: 23, top: 33),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImageFromGallery,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : _imageUrl != null
                              ? NetworkImage(_imageUrl!)
                              : null,
                      child: _selectedImage == null && _imageUrl == null
                          ? const Icon(Icons.camera_alt, size: 40)
                          : null,
                    ),
                  ),
                   SizedBox(height: 18.h),
                  ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo),
                    label: const Text('Gallery'),
                  ),
                   SizedBox(height: 16.h),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    enableSuggestions: false,
                    keyboardType: TextInputType.name,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a category name.';
                      }
                      return null;
                    },
                  ),
                   SizedBox(height: 40.h),
                  SizedBox(
                    width: screenWidth * 0.75.w,
                    child: ElevatedButton(
                      onPressed: _createCategory,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2.w,
                          ),
                        ),
                      ),
                      child: const Text('Create'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
