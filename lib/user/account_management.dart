import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:test_project/screens/HomeScreen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AccountManagementScreen extends StatefulWidget {
  final String userId;
  final String initialName;
  final String initialEmail;
  final String initialUsername;
  final String initialPhoneNumber;
  final String? initialImageUrl;

  const AccountManagementScreen({
    Key? key,
    required this.userId,
    required this.initialName,
    required this.initialEmail,
    required this.initialUsername,
    required this.initialPhoneNumber,
    this.initialImageUrl,
  }) : super(key: key);

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController emailController;
  late TextEditingController fullNameController;
  late TextEditingController userNameController;
  late TextEditingController phoneNumberController;
  File? _selectedImage;
  String? _imageUrl;
  var _isUpdating = false;





  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.initialEmail);
    fullNameController = TextEditingController(text: widget.initialName);
    userNameController = TextEditingController(text: widget.initialUsername);
    phoneNumberController = TextEditingController(text: widget.initialPhoneNumber);
    _imageUrl = widget.initialImageUrl;
  }

  @override
  void dispose() {
    emailController.dispose();
    fullNameController.dispose();
    userNameController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  Future<String> _uploadImage(File image) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('user_images')
        .child('${widget.userId}.jpg');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<void> updateUserDetail(String id, Map<String, dynamic> updateInfo) async {
    setState(() {
      _isUpdating = true;
    });
    await FirebaseFirestore.instance.collection("users").doc(id).update(updateInfo);
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
      fontSize: 16.0.sp,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Details'),
        leading: IconButton(
           icon: const Icon(Icons.arrow_back),
            onPressed: () {
               Navigator.pushReplacement( context, MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
                 }, 
                 ),
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
               SizedBox(height: 16.h),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty || !value.contains('@')) {
                    return 'Please enter a valid email address.';
                  }
                  return null;
                },
              ),
               SizedBox(height: 16.h),
              TextFormField(
                controller: fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty || value.trim().length <= 2) {
                    return 'Please enter a valid name.';
                  }
                  return null;
                },
              ),
               SizedBox(height: 16.h),
              TextFormField(
                controller: userNameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty || value.trim().length < 4) {
                    return 'Please enter at least 4 characters.';
                  }
                  return null;
                },
              ),
               SizedBox(height: 16.h),
              TextFormField(
                controller: phoneNumberController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                   if (value == null || value.isEmpty) {
                      return 'Phone number is required.';
                    }
                    if (value.trim().length <= 9) {
                       return 'Phone number must be max 10 characters.';
                    }
                    if(value.trim().length != 10 && value.trim().length != 13)
                    {
                       return 'Phone number must be 10 characters or starting with +962';
                    }
                    if (!value.startsWith('077') && !value.startsWith('078') && !value.startsWith('079') && !value.startsWith('+96277') && !value.startsWith('+96278') && !value.startsWith('+96279')) {
                      return 'Phone number must be "077" or "078" or "079" or "+962" .';
                    }
                    return null;
                },
              ),

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
                  onPressed: _isUpdating ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      String? uploadedImageUrl;
                      if (_selectedImage != null) {
                        uploadedImageUrl = await _uploadImage(_selectedImage!);
                      }
                
                      Map<String, dynamic> updateInfo = {
                        "name": fullNameController.text,
                        "email": emailController.text,
                        "phone_number": phoneNumberController.text,
                        "username": userNameController.text,
                        if (uploadedImageUrl != null) "image_url": uploadedImageUrl,
                      };
                
                      await updateUserDetail(widget.userId, updateInfo).then((value) {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ctx) => const HomeScreen()));    
                      }).then((value) {
                        showToastrMessage("Information updated successfully.");
                      });
                    }
                  },
                  child: _isUpdating
                      ?  SizedBox(
                          height: 20.h,
                          width: 20.w,
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


