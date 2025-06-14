import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:test_project/loading_screen.dart';
import 'package:test_project/screens/HomeScreen.dart';
import 'package:test_project/screens/admin/admin_tabs.dart';
import 'package:test_project/screens/delivery/delivery_home_screen.dart';
import 'package:test_project/widgets/location_input.dart';
import 'package:test_project/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_project/constants/colors.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }
}


enum UserRole {customer , admin}


class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();

  var defaultRole = {UserRole.customer};

  var _isLogin = true;
  var _enteredEmail = '';
  var _enteredPassword = '';
  var _enteredUsername = '';
  var _enteredPhoneNumber = '';
  var _enteredFullName = '';
  File? _selectedImage;
  var _isAuthenticating = false;
  final TextEditingController _passwordController = TextEditingController();

  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

   void showToastrMessage(String message)
  {
    Fluttertoast.showToast(
  msg: message,
  toastLength: Toast.LENGTH_LONG,
  gravity: ToastGravity.TOP,
  timeInSecForIosWeb: 3,
  backgroundColor: Colors.green[700], // Changed to a beautiful, compatible green
  textColor: kWhite,
  fontSize: 16.0.sp,
  webPosition: "right",
);
  }

  void _saveLocation(double latitude, double longitude) {
    setState(() {
      _latitude = latitude;
      _longitude = longitude;
    });
  }

Future<void> _submit() async {
  final isValid = _form.currentState!.validate();

  if (!isValid) {
    return;
  }

  if (!_isLogin) {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image.')),
      );
      return;
    }
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your location.')),
      );
      return;
  }
}

  _form.currentState!.save();

  try {
    setState(() {
      _isAuthenticating = true;
    });

    // Display loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return const Center(
          child: LoadingScreen(),
        );
      },
    );

    if (_isLogin) {
      // Admin Login
      const adminEmail = "admin@example.com";
      const adminPassword = "admin123";

      if (_enteredEmail == adminEmail && _enteredPassword == adminPassword) {
        Navigator.of(context).pop(); // Close spinner
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin login successful.')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => const AdminTabsScreen(),
          ),
        );
        return;
      }

      // Regular User Login
      final userCredential = await _firebase.signInWithEmailAndPassword(
        email: _enteredEmail,
        password: _enteredPassword,
      );

      final userId = userCredential.user!.uid;

      // Fetch the user's role from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final deliveryDoc = await FirebaseFirestore.instance
          .collection('delivery')
          .doc(userId)
          .get();

      String role = 'customer'; // Default role

      if (userDoc.exists) {
        role = userDoc['role'] ?? 'customer';
      } else if (deliveryDoc.exists) {
        role = deliveryDoc['role'] ?? 'delivery';
      }

      Navigator.of(context).pop(); // Close spinner

      // Navigate based on the user's role
      if (role == 'delivery') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => DeliveryHomeScreen(
              deliveryData: deliveryDoc.data(), // Pass delivery data to the screen
              deliveryDoc.id,
            ),
          ),
        );
      } else {
        final status = userDoc['status'] ?? 'active';
        if (status == 'blocked') {
          Navigator.of(context).pop(); // Close spinner
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your account has been blocked. Please contact support.'),
              backgroundColor: Colors.red,
            ),
          );
          await _firebase.signOut();
          return;
        }

        Navigator.of(context).pop(); // Close spinner

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => const HomeScreen(),
          ),
        );
        showToastrMessage("Logged In Successfully.");
      }
    } else {
      // Sign Up New User
      final userCredentials = await _firebase.createUserWithEmailAndPassword(
        email: _enteredEmail,
        password: _enteredPassword,
      );

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${userCredentials.user!.uid}.jpg');

      await storageRef.putFile(_selectedImage!);
      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredentials.user!.uid)
          .set({
        'username': _enteredUsername,
        'email': _enteredEmail,
        'name': _enteredFullName,
        'phone_number': _enteredPhoneNumber,
        'image_url': imageUrl,
        'role': 'customer', // Default role for new users
        'location': {
          'latitude': _latitude,
          'longitude': _longitude,
        },
        'status': 'active'
      });

      Navigator.of(context).pop(); // Close spinner
      showToastrMessage("Signed Up Successfully.");
      
      // Navigate to HomeScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (ctx) => const HomeScreen(),
        ),
      );
    }
  } on FirebaseAuthException catch (error) {
    Navigator.of(context).pop(); // Close spinner on error
    ScaffoldMessenger.of(context).clearSnackBars();
    if (error.code == 'user-not-found') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect email or password, please try again.'),
        ),
      );
    } else if (error.code == 'wrong-password') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect email or password, please try again.'),
        ),
      );
    } else if (error.code == 'invalid-credential') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid credentials. Please try again.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Authentication failed.'),
        ),
      );
    }
  } finally {
    setState(() {
      _isAuthenticating = false;
    });
  }
}




 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: kBackgroundGrey,
    body: Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),
                Image.asset(
                  'assets/images/logo-removebg-preview.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                if (!_isLogin)
                  UserImagePicker(
                    onPickImage: (pickedImage) {
                      _selectedImage = pickedImage;
                    },
                  ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: TextStyle(color: kPrimaryBlue),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kPrimaryBlue),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kPrimaryBlue, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty ||
                        !value.contains('@')) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _enteredEmail = value!;
                  },
                ),
                const SizedBox(height: 8),
                if (!_isLogin)
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: TextStyle(color: kPrimaryBlue),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: kPrimaryBlue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: kPrimaryBlue, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.name,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty ||
                          value.contains('@') ||
                          value.contains('_') ||
                          value.contains('-') ||
                          value.trim().length <= 2) {
                        return 'Please enter a valid name.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _enteredFullName = value!;
                    },
                  ),
                const SizedBox(height: 8),
                if (!_isLogin)
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: kPrimaryBlue),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: kPrimaryBlue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: kPrimaryBlue, width: 2),
                      ),
                    ),
                    enableSuggestions: false,
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          value.trim().length < 4) {
                        return 'Please enter at least 4 characters.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _enteredUsername = value!;
                    },
                  ),
                const SizedBox(height: 8),
                if (!_isLogin)
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: TextStyle(color: kPrimaryBlue),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: kPrimaryBlue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: kPrimaryBlue, width: 2),
                      ),
                    ),
                    enableSuggestions: false,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Phone number is required.';
                      }
                      if (value.trim().length <= 9) {
                        return 'Phone number must be max 10 characters.';
                      }
                      if (value.trim().length != 10 &&
                          value.trim().length != 13) {
                        return 'Phone number must be 10 characters or starting with +962';
                      }
                      if (!value.startsWith('077') &&
                          !value.startsWith('078') &&
                          !value.startsWith('079') &&
                          !value.startsWith('+96277') &&
                          !value.startsWith('+96278') &&
                          !value.startsWith('+96279')) {
                        return 'Phone number must be "077" or "078" or "079" or "+962".';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _enteredPhoneNumber = value!;
                    },
                  ),
                const SizedBox(height: 8),
                if (!_isLogin)
                  LocationInput(
                    onSelectLocation: _saveLocation,
                  ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: kPrimaryBlue),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kPrimaryBlue),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kPrimaryBlue, width: 2),
                    ),
                  ),
                  controller: _passwordController,
                  obscureText: true,
                  validator: (value) {
                    if (value == null ||
                        value.trim().length < 6) {
                      return 'Password must be at least 6 characters long.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _enteredPassword = value!;
                  },
                ),
                const SizedBox(height: 8),
                if (!_isLogin)
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      labelStyle: TextStyle(color: kPrimaryBlue),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: kPrimaryBlue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: kPrimaryBlue, width: 2),
                      ),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          value != _passwordController.text) {
                        return 'Password and confirm password are not the same.';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 16),
                if (_isAuthenticating)
                  CircularProgressIndicator(color: kPrimaryBlue)
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBlue,
                          foregroundColor: kWhite,
                        ),
                        child: Text(_isLogin ? 'Login' : 'Signup'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(
                          _isLogin
                              ? 'Create an account'
                              : 'I already have an account',
                          style: TextStyle(color: kPrimaryBlue),
                        ),
                      ),
                    ],
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