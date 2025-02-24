import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:test_project/screens/admin/vehichle_infos.dart';
import 'package:test_project/widgets/user_image_picker.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;



class CreatingDeliveryAccountScreen extends StatefulWidget {
  const CreatingDeliveryAccountScreen({super.key});

  @override
  State<CreatingDeliveryAccountScreen> createState() {
    return _CreatingDeliveryAccountScreenState();
  }
}

class _CreatingDeliveryAccountScreenState extends State<CreatingDeliveryAccountScreen> {
  final _form = GlobalKey<FormState>();
  

  var _enteredEmail = '';
  var _enteredPassword = '';
  var _enteredNationalID = '';
  var _enteredPhoneNumber = '';
  var _enteredFullName = '';
  var _enteredLocation = '';
  DateTime? _enteredDateOfBirth;
  DateTime? _enteredDate ;
  File? _selectedImage;
  var _isAuthenticating = false;
  final formatter = DateFormat.yMd();

// Add a variable to store card details
stripe.CardFieldInputDetails? _cardDetails;

  String get formattedDate
  {
    return formatter.format(_enteredDate!);
  }



    void dateOfBirth() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 60, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate,
      lastDate: now,
    );
    setState(() {
      _enteredDateOfBirth = pickedDate;
    });
  }





    void _presentDatePicker() async {
    final now = DateTime.now();
    final lastDate = DateTime(now.year + 2, now.month, now.day);
    final firstDate = DateTime(now.year, now.month - 3, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    setState(() {
      _enteredDate = pickedDate;
    });
  }



    void showToastrMessage(String message)
  {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
       timeInSecForIosWeb: 3,
        backgroundColor: const Color.fromARGB(255, 106, 179, 116),
        textColor: const Color.fromARGB(255, 255, 255, 255),
        fontSize: 16.0,
        webPosition: "right",
    );
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
          .collection('delivery')
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


 Future<void> moveToVehicleInfosScreen() async {
  final isValid = _form.currentState!.validate();

  if (!isValid) {
    return;
  }

  if (_selectedImage == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select an image.')),
    );
    return;
  }

  if (_enteredDate == null || _enteredDateOfBirth == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter both dates.')),
    );
    return;
  }

  _form.currentState!.save();

  try {
    setState(() {
      _isAuthenticating = true;
    });

    // Pass card details to the next screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => VehichleInfosScreen(
          userData: {
            'email': _enteredEmail,
            'password': _enteredPassword,
            'national_id': _enteredNationalID,
            'name': _enteredFullName,
            'phone_number': _enteredPhoneNumber,
            'location': _enteredLocation,
            'D.O.B': _enteredDateOfBirth,
            'Joining_Date': _enteredDate,
            'image': _selectedImage,
          },
          cardDetails: _cardDetails, // Pass card details
        ),
      ),
    );
  } on FirebaseAuthException catch (error) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.message ?? 'Authentication failed.'),
      ),
    );
  } finally {
    setState(() {
      _isAuthenticating = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 223, 214),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [             
              Card(            
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [                         
                            UserImagePicker(
                              onPickImage: (pickedImage) {
                                _selectedImage = pickedImage;
                              },
                            ),                         
                            TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'Full Name'),
                            keyboardType: TextInputType.name,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.sentences,
                            validator: (value) {
                              if (value == null ||value.trim().isEmpty ||value.contains('@') || value.contains('_') || value.contains('-') || value.trim().length<=2) {
                                return 'Please enter a valid name.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredFullName = value!;
                            },
                          ),
                           const SizedBox(height: 20),

                             TextFormField(
                              decoration:
                                  const InputDecoration(labelText: 'National ID'),
                              enableSuggestions: false,
                              keyboardType: const TextInputType.numberWithOptions(),
                              maxLength: 10,
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    value.trim().length != 10) {
                                  return 'ID number must be 10 charectars';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredNationalID = value!;
                              },
                            ),
                          const SizedBox(height: 10),
                       Container(
                        margin: const EdgeInsets.symmetric(vertical: 30),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onPrimaryContainer, 
                          ), 
                          borderRadius: BorderRadius.circular(8), 
                        ),
                         child: Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 8 , vertical: 30),
                           child: Column(                           
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Joining Date Label
                                     Text('Joining Date'),
                                    // D.O.B Label
                                     Text('D.O.B'),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Calendar Icon and Text (under Joining Date)
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: _presentDatePicker,
                                          icon: const Icon(Icons.calendar_month),
                                        ),
                                        Text(
                                          _enteredDate == null
                                              ? 'No date selected'
                                              : formatter.format(_enteredDate!),
                                        ),
                                      ],
                                    ),
                                    // Cake Icon and Text (under D.O.B)
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: dateOfBirth,
                                          icon: const Icon(Icons.cake_rounded),
                                        ),
                                        Text(
                                          _enteredDateOfBirth == null
                                              ? 'No D.O.B selected'
                                              : formatter.format(_enteredDateOfBirth!),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                         ),
                       ),

                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'Email'),
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

                            const SizedBox(height: 20),
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'Password'),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.trim().length < 6) {
                                return 'Password must be at least 6 characters long.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredPassword = value!;
                            },
                          ),
                          
                            const SizedBox(height: 20,),

                           TextFormField(
                              decoration: const InputDecoration(labelText: 'Phone Number'),
                              enableSuggestions: false,
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
                              onSaved: (value) {
                                _enteredPhoneNumber = value!;
                              },
                            ),
                            const SizedBox(height: 20),

                              TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'Location'),
                            keyboardType: TextInputType.name,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.sentences,
                            validator: (value) {
                              if (value == null ||value.trim().isEmpty) {
                                return 'Please enter your location.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredLocation = value!;
                            },
                          ),


                           const SizedBox(height: 20),

                           // Add Card Input Field
                          const SizedBox(height: 25),
                          stripe.CardField(
                          onCardChanged: (card) {
                            setState(() {
                              _cardDetails = card;
                            });
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Card Details',
                          ),
                        ),

                          const SizedBox(height: 25),
                          if (_isAuthenticating)
                            const CircularProgressIndicator(),
                          if (!_isAuthenticating)
                            ElevatedButton(
                              onPressed: moveToVehicleInfosScreen,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                              ),
                              child: const Text('Next'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}