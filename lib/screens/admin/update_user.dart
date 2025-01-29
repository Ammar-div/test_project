// import 'dart:io';
// import 'package:test_project/widgets/location_input.dart';
// import 'package:test_project/widgets/user_image_picker.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// final _firebase = FirebaseAuth.instance;

// class UpdateUser extends StatefulWidget {
//   const UpdateUser({super.key});
  

//   @override
//   State<UpdateUser> createState() {
//     return _UpdateUserState();
//   }
// }

// enum UserRole {customer , delivery , admin}

// class _UpdateUserState extends State<UpdateUser> {
//   final _form = GlobalKey<FormState>();
  
//   UserRole defaultRole = UserRole.customer;
//   TextEditingController emailController = TextEditingController();
//   TextEditingController fullNameController = TextEditingController();
//   TextEditingController userNameController = TextEditingController();

//   File? _selectedImage;
  
//   final TextEditingController _passwordController = TextEditingController();

//   double? _latitude;
//   double? _longitude;

//   @override
//   void dispose() {
//     _passwordController.dispose();
//     super.dispose();
//   }

//   void _saveLocation(double latitude, double longitude) {
//     setState(() {
//       _latitude = latitude;
//       _longitude = longitude;
//     });
//   }

//   Future<void> _submit() async {
//     final isValid = _form.currentState!.validate();

//     if (!isValid) {
//       return;
//     }

    
//       if (_selectedImage == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please select an image.')),
//         );
//         return;
//       }
//       if (_latitude == null || _longitude == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please select your location.')),
//         );
//         return;
//       }
    

//     _form.currentState!.save();

//     try {
//       setState(() {
//         _isAuthenticating = true;
//       });

      
//         // Sign Up New User
//         final userCredentials = await _firebase.createUserWithEmailAndPassword(
//           email: _enteredEmail,
//           password: _enteredPassword,
//         );

//         final storageRef = FirebaseStorage.instance
//             .ref()
//             .child('user_images')
//             .child('${userCredentials.user!.uid}.jpg');

//         await storageRef.putFile(_selectedImage!);
//         final imageUrl = await storageRef.getDownloadURL();

//         await FirebaseFirestore.instance
//             .collection('users')
//             .doc(userCredentials.user!.uid)
//             .set({
//           'username': _enteredUsername,
//           'email': _enteredEmail,
//           'name': _enteredFullName,
//           'phone_number': _enteredPhoneNumber,
//           'image_url': imageUrl,
//           'role': defaultRole.name, // Default role for new users
//           'location': {
//             'latitude': _latitude,
//             'longitude': _longitude,
//           },
//         }).then((value) {
//             Navigator.of(context).pop();
//         });
      
//     } on FirebaseAuthException catch (error) {
//       ScaffoldMessenger.of(context).clearSnackBars();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(error.message ?? 'Authentication failed.'),
//         ),
//       );
//     } finally {
//       setState(() {
//         _isAuthenticating = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color.fromARGB(255, 242, 223, 214),
//       body: Center(
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
              
//               Container(
//                 margin: const EdgeInsets.only(
//                   top: 30,
//                   bottom: 20,
//                   left: 20,
//                   right: 20,
//                 ),
//                 width: 200,
//                 child: Image.asset('assets/images/logo.png'),
//               ),
//               Card(
//                 color: Theme.of(context).colorScheme.onPrimary,
//                 margin: const EdgeInsets.all(20),
//                 child: SingleChildScrollView(

//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Form(
//                       key: _form,
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.start,
//                             children: [
//                               IconButton(
//                                   icon: const Icon(Icons.keyboard_backspace_outlined),
//                                   color: Theme.of(context).colorScheme.primary,
//                                   iconSize: 60,
//                                   onPressed: () {
//                                       Navigator.of(context).pop();
//                                   },
//                                   ),
//                             ],
//                           ),
//                             UserImagePicker(
//                               onPickImage: (pickedImage) {
//                                 _selectedImage = pickedImage;
//                               },
//                             ),
//                            const SizedBox(height: 20),
                          
//                             LocationInput(
//                               onSelectLocation: _saveLocation,
//                             ),
//                            const SizedBox(height: 20),
//                           TextFormField(
//                             decoration:
//                                 const InputDecoration(labelText: 'Email Address'),
//                             keyboardType: TextInputType.emailAddress,
//                             autocorrect: false,
//                             textCapitalization: TextCapitalization.none,
//                             validator: (value) {
//                               if (value == null ||
//                                   value.trim().isEmpty ||
//                                   !value.contains('@')) {
//                                 return 'Please enter a valid email address.';
//                               }
//                               return null;
//                             },
//                             onSaved: (value) {
//                               _enteredEmail = value!;
//                             },
//                           ),

                          
//                           TextFormField(
//                             decoration:
//                                 const InputDecoration(labelText: 'Full Name'),
//                             keyboardType: TextInputType.name,
//                             autocorrect: false,
//                             textCapitalization: TextCapitalization.characters,
//                             validator: (value) {
//                               if (value == null ||value.trim().isEmpty ||value.contains('@') || value.contains('_') || value.contains('-') || value.trim().length<=2) {
//                                 return 'Please enter a valid name.';
//                               }
//                               return null;
//                             },
//                             onSaved: (value) {
//                               _enteredFullName = value!;
//                             },
//                           ),

                          
//                             TextFormField(
//                               decoration:
//                                   const InputDecoration(labelText: 'Username'),
//                               enableSuggestions: false,
//                               validator: (value) {
//                                 if (value == null ||
//                                     value.isEmpty ||
//                                     value.trim().length < 4) {
//                                   return 'Please enter at least 4 characters.';
//                                 }
//                                 return null;
//                               },
//                               onSaved: (value) {
//                                 _enteredUsername = value!;
//                               },
//                             ),
                          
//                             TextFormField(
//                               decoration:
//                                   const InputDecoration(labelText: 'Phone Number'),
//                               enableSuggestions: false,
//                               keyboardType: TextInputType.phone,
//                               validator: (value) {
//                                 if (value == null ||
//                                     value.isEmpty ||
//                                     value.trim().length < 9 ||
//                                     value.trim().length > 10) {
//                                   return 'Phone number must be max 10 characters.';
//                                 }
//                                 return null;
//                               },
//                               onSaved: (value) {
//                                 _enteredPhoneNumber = value!;
//                               },
//                             ),
//                           TextFormField(
//                             decoration:
//                                 const InputDecoration(labelText: 'Password'),
//                             controller: _passwordController,
//                             obscureText: true,
//                             validator: (value) {
//                               if (value == null || value.trim().length < 6) {
//                                 return 'Password must be at least 6 characters long.';
//                               }
//                               return null;
//                             },
//                             onSaved: (value) {
//                               _enteredPassword = value!;
//                             },
//                           ),
                          
//                             TextFormField(
//                               decoration: const InputDecoration(
//                                   labelText: 'Confirm Password'),
//                               obscureText: true,
//                               validator: (value) {
//                                 if (value == null ||
//                                     value.isEmpty ||
//                                     value != _passwordController.text) {
//                                   return 'Password and confirm password are not the same.';
//                                 }
//                                 return null;
//                               },
//                             ),
//                             const SizedBox(height: 20,),
//                             Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            
//                               child: DropdownButton(
//                                 value: defaultRole,
//                                 items: UserRole.values
//                                     .map(
//                                       (oneSingleRole) => DropdownMenuItem(
//                                         value: oneSingleRole,
//                                         child: Text(
//                                           oneSingleRole.name.toUpperCase(),
//                                         ),
//                                       ),
//                                     )
//                                     .toList(),
//                                 onChanged: (value) {
//                                   if (value == null) {
//                                     return;
//                                   }
//                                   setState(() {
//                                     defaultRole = value;
//                                   });
//                                 },
//                                 dropdownColor:  Theme.of(context).colorScheme.primaryContainer,
//                               ),
//                             ),


//                           const SizedBox(height: 20),
//                           if (_isAuthenticating)
//                             const CircularProgressIndicator(),
//                           if (!_isAuthenticating)
//                             ElevatedButton(
//                               onPressed: _submit,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Theme.of(context)
//                                     .colorScheme
//                                     .primaryContainer,
//                               ),
//                               child: const Text('Signup'),
//                             ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }