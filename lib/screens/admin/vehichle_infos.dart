
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:test_project/screens/admin/crud_operations.dart';


final _firebase = FirebaseAuth.instance;

class VehichleInfosScreen extends StatefulWidget {
  const VehichleInfosScreen( {super.key , required this.userData,
  this.cardDetails,});

  final Map<String , dynamic > userData;
  final stripe.CardFieldInputDetails? cardDetails;

  @override
  State<VehichleInfosScreen> createState() {
    return _VehichleInfosScreenState();
  }
}


final Map<String , dynamic> vehichle_color = {
  'White': Colors.white,
  'Black': Colors.black,
  'Yellow' : Colors.yellow,
  'Green' : Colors.green,
  'Blue' : Colors.blue,
  'Silver' : Colors.white38,
  'Red' : Colors.red,
  'Pink' : Colors.pink,
  'Orange' : Colors.orange,
};

class _VehichleInfosScreenState extends State<VehichleInfosScreen> {
  final _form = GlobalKey<FormState>();
  
  var _enteredVehicleModel = '';
  var _enteredVehicleNumber = '';
  String _selectedVehicleType = 'car';
  var _isAuthenticating = false;
  var _selectedVehicleColor = 'Black';
  


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


Future<void> _submit() async {
  final userData = widget.userData;
  final isValid = _form.currentState!.validate();

  if (!isValid) {
    return;
  }

  _form.currentState!.save();

  try {
    setState(() {
      _isAuthenticating = true;
    });

    

    // Sign Up New User
    final userCredentials = await _firebase.createUserWithEmailAndPassword(
      email: userData['email'],
      password: userData['password'],
    );

    final ref = FirebaseStorage.instance
        .ref()
        .child('user_images')
        .child('${userCredentials.user!.uid}.jpg');  // You can use the user's email or ID to name the image

    await ref.putFile(userData['image']);  // Upload the selected image
    final imageUrl = await ref.getDownloadURL();

    // Save all data to Firestore
    await FirebaseFirestore.instance
        .collection('delivery')
        .doc(userCredentials.user!.uid)
        .set({
      'email': userData['email'],
      'name': userData['name'],
      'national_id': userData['national_id'],
      'phone_number': userData['phone_number'],
      'location': userData['location'],
      'date_of_birth': userData['D.O.B'],
      'joining_date': userData['Joining_Date'],
     'image_url': imageUrl,
      'role': 'delivery',
      'Vehicle_Infos': {
        'vehicle_type': _selectedVehicleType,
      'vehicle_model': _enteredVehicleModel,
      'vehicle_number': _enteredVehicleNumber,
      'Vehicle_Color': _selectedVehicleColor,
      }
    });

     // Save card information if available
      if (widget.cardDetails != null) {
        final paymentMethod = await stripe.Stripe.instance.createPaymentMethod(
          params: stripe.PaymentMethodParams.card(
            paymentMethodData: stripe.PaymentMethodData(
              billingDetails: stripe.BillingDetails(
                email: widget.userData['email'],
              ),
            ),
          ),
        );

        await FirebaseFirestore.instance
            .collection('delivery')
            .doc(userCredentials.user!.uid)
            .update({
          'stripePaymentMethodId': paymentMethod.id,
        });
      }

    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const CrudOperationsScreen(),));
    showToastrMessage("User and vehicle information saved successfully.");
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
      appBar: AppBar(
        title: const Text('Vehicle Informations'),
      ),
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
                            const Text(
                            'Select Vehicle Type',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          ListTile(
                            title: const Text('Car'),
                            leading: Radio<String>(
                              value: 'car',
                              groupValue: _selectedVehicleType,
                              onChanged: (value) {
                                setState(() {
                                  _selectedVehicleType = value!;
                                });
                              },
                            ),
                          ),
                          ListTile(
                            title: const Text('Motorcycle'),
                            leading: Radio<String>(
                              value: 'motorcycle',
                              groupValue: _selectedVehicleType,
                              onChanged: (value) {
                                setState(() {
                                  _selectedVehicleType = value!;
                                });
                              },
                            ),
                          ),


                           const SizedBox(height: 20),

                             TextFormField(
                              decoration:
                                  const InputDecoration(labelText: 'Vehicle Number'),
                              enableSuggestions: false,
                              keyboardType: const TextInputType.numberWithOptions(),
                              maxLength: 8,
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    !value.trim().contains('-')) {
                                  return 'Vehicle number must have the symbol "-" ';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredVehicleNumber = value!;
                              },
                            ),
                          const SizedBox(height: 10),

                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'Vehicle Model'),
                            keyboardType: TextInputType.name,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.sentences,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'This Field is required.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredVehicleModel = value!;
                            },
                          ),

                           
                          
                            const SizedBox(height: 40,),

                            DropdownButtonFormField(
                              value: _selectedVehicleColor,
                              decoration: const InputDecoration(
                                labelText: 'Select Vehicle Color',
                              ),
                               dropdownColor: Theme.of(context).colorScheme.errorContainer,
                              items: [
                                for(final oneVehicleColorObj in vehichle_color.entries)
                                  DropdownMenuItem(
                                    value: oneVehicleColorObj.key,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 16,
                                          height: 16,
                                          color: oneVehicleColorObj.value,
                                        ),
                                        const SizedBox(width: 8,),
                                        Text(oneVehicleColorObj.key),
                                      ],
                                    ),),
                              ],
                               onChanged: (value) {
                                _selectedVehicleColor = value!;
                               } ),

                             


                          const SizedBox(height: 80),
                          if (_isAuthenticating)
                            const CircularProgressIndicator(),
                          if (!_isAuthenticating)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                  ),
                                  child: const Text('Back'),
                                ),

                                ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                  ),
                                  child: const Text('Create Delivery User'),
                                ),
                              ],
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