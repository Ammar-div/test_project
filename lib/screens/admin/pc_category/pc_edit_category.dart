import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PcEditCategory extends StatefulWidget {
  final String userId;
  final String initialName;
  final String? initialImageUrl;

  const PcEditCategory({
    Key? key,
    required this.userId,
    required this.initialName,
    this.initialImageUrl,
  }) : super(key: key);

  @override
  State<PcEditCategory> createState() => _PcEditCategoryState();
}

class _PcEditCategoryState extends State<PcEditCategory> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  File? _selectedImage;
  String? _imageUrl;
  var _isUpdating = false;





  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName);
    _imageUrl = widget.initialImageUrl;
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

  Future<String> _uploadImage(File image, String categoryName) async {
  // Sanitize the category name to create a valid file name
  final sanitizedCategoryName = categoryName.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
  
  // Reference to the storage path for the category image
  final ref = FirebaseStorage.instance.ref().child('category_images/$sanitizedCategoryName');
  
  try {
    // Upload the file
    await ref.putFile(image);
    
    // Return the download URL of the uploaded image
    return await ref.getDownloadURL();
  } catch (e) {
    throw Exception('Failed to upload image: $e');
  }
}


  Future<void> updateUserDetail(String id, Map<String, dynamic> updateInfo) async {
    setState(() {
      _isUpdating = true;
    });
    await FirebaseFirestore.instance.collection("categories").doc(id).update(updateInfo);
    setState(() {
      _isUpdating = false;
    });
  }

  void showToastrMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: const Color.fromARGB(255, 106, 179, 116),
      textColor: const Color.fromARGB(255, 255, 255, 255),
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Category'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo),
                    label: const Text('Gallery'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter category name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40,),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton( 
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  onPressed: _isUpdating ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      String? uploadedImageUrl;
                      if (_selectedImage != null) {
                      uploadedImageUrl = await _uploadImage(_selectedImage!, nameController.text);                      }
                
                      Map<String, dynamic> updateInfo = {
                        "name": nameController.text,
                        if (uploadedImageUrl != null) "imageUrl": uploadedImageUrl,
                      };
                
                      await updateUserDetail(widget.userId, updateInfo).then((value) {
                        Navigator.of(context).pop();    
                      }).then((value) {
                        showToastrMessage("The user has been updated successfully.");
                      });
                    }
                  },
                  child: _isUpdating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            //color: Colors.white,
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


