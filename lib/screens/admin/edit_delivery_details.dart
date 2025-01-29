
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class EditDeliveryDetailsScreen extends StatefulWidget {
  final String userId;
  final String initialName;
  final String initialEmail;
  final String initialNationalID;
  final String initialPhoneNumber;
  final String? initialImageUrl;
  final DateTime? initialJoiningDate;
  final DateTime? initialDateOfBirth;
  final String initialVehicleModel;
  final String initialLocation;
  final String initialVehicleNumber;
  final String initialVehicleColor;
  final String initialVehicleType;
  const EditDeliveryDetailsScreen({
    Key? key,
    required this.userId,
    required this.initialName,
    required this.initialEmail,
    required this.initialNationalID,
    required this.initialPhoneNumber,
    this.initialImageUrl,
    required this.initialJoiningDate,
    required this.initialDateOfBirth,
    required this.initialVehicleModel,
    required this.initialLocation,
    required this.initialVehicleNumber,
    required this.initialVehicleColor,
    required this.initialVehicleType,
  }) : super(key: key);

  @override
  State<EditDeliveryDetailsScreen> createState() => _EditDeliveryDetailsScreenState();
}

  final Map<String , Color> vehichle_color = {
  'Black': Colors.black,
  'White': Colors.white,
  'Yellow' : Colors.yellow,
  'Green' : Colors.green,
  'Blue' : Colors.blue,
  'Silver' : Colors.white38,
  'Red' : Colors.red,
  'Pink' : Colors.pink,
  'Orange' : Colors.orange,
};


class _EditDeliveryDetailsScreenState extends State<EditDeliveryDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController emailController;
  late TextEditingController fullNameController;
  late TextEditingController nationalIDController;
  late TextEditingController phoneNumberController;
  late TextEditingController locationController;
  late TextEditingController vehicleModelController;
  late TextEditingController vehicleNumberController;

  String? _selectedVehicleType;
  String? _selectedVehicleColor;
  File? _selectedImage;
  String? _imageUrl;
  var _isUpdating = false;
   final formatter = DateFormat.yMd();
@override
void initState() {
  super.initState();
  emailController = TextEditingController(text: widget.initialEmail);
  fullNameController = TextEditingController(text: widget.initialName);
  nationalIDController = TextEditingController(text: widget.initialNationalID);
  phoneNumberController = TextEditingController(text: widget.initialPhoneNumber);
  locationController = TextEditingController(text: widget.initialLocation);
  vehicleModelController = TextEditingController(text: widget.initialVehicleModel);
  vehicleNumberController = TextEditingController(text: widget.initialVehicleNumber);
  _imageUrl = widget.initialImageUrl;

  // Normalize color from the database to match the vehichle_color keys
  String normalizedColor = widget.initialVehicleColor.trim();
  normalizedColor = '${normalizedColor[0].toUpperCase()}${normalizedColor.substring(1).toLowerCase()}';

  // Check if the normalized color exists in the vehichle_color map
  _selectedVehicleColor = vehichle_color.keys.contains(normalizedColor)
      ? normalizedColor
      : null; // Default to null if not matched

  _selectedVehicleType = widget.initialVehicleType;
}




  @override
  void dispose() {
    emailController.dispose();
    fullNameController.dispose();
    nationalIDController.dispose();
    phoneNumberController.dispose();
    locationController.dispose();
    vehicleModelController.dispose();
    vehicleNumberController.dispose();
    _selectedVehicleColor = widget.initialVehicleColor;
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

Future<void> updateDeliveryDetail(String id, Map<String, dynamic> updateInfo) async {
  final deliveryDoc = FirebaseFirestore.instance.collection("delivery").doc(id);

  // Separate updates for main document fields and Vehicle_Infos
  Map<String, dynamic> vehicleUpdates = {};
  Map<String, dynamic> mainUpdates = {};

  // Extract vehicle-related updates
  if (updateInfo.containsKey("vehicle_type")) {
    vehicleUpdates["Vehicle_Infos.vehicle_type"] = updateInfo["vehicle_type"];
  }
  if (updateInfo.containsKey("vehicle_model")) {
    vehicleUpdates["Vehicle_Infos.vehicle_model"] = updateInfo["vehicle_model"];
  }
  if (updateInfo.containsKey("vehicle_number")) {
    vehicleUpdates["Vehicle_Infos.vehicle_number"] = updateInfo["vehicle_number"];
  }
  if (updateInfo.containsKey("Vehicle_Color")) {
    vehicleUpdates["Vehicle_Infos.Vehicle_Color"] = updateInfo["Vehicle_Color"];
  }

  // Filter out vehicle-related keys for the main document update
  for (String key in updateInfo.keys) {
    if (!["vehicle_type", "vehicle_model", "vehicle_number", "Vehicle_Color"].contains(key)) {
      mainUpdates[key] = updateInfo[key];
    }
  }

  // Update main document fields
  if (mainUpdates.isNotEmpty) {
    await deliveryDoc.update(mainUpdates);
  }

  // Update nested Vehicle_Infos fields
  if (vehicleUpdates.isNotEmpty) {
    await deliveryDoc.update(vehicleUpdates);
  }
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

   String get formattedDate
  {
    return formatter.format(widget.initialJoiningDate!);
  }

  @override
  Widget build(BuildContext context) {
    // String _selectedVehicleType = widget.initialVehicleType;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Delivey Details'),
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
                  ElevatedButton.icon(
                    onPressed: _pickImageFromCamera,
                    icon: const Icon(Icons.camera),
                    label: const Text('Camera'),
                  ),
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
                controller: fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nationalIDController,
                decoration: const InputDecoration(labelText: 'National ID'),
                readOnly: true,
              ),
              const SizedBox(height: 30),

             Row(
              children: [
                const Text('Joining Date : ', style: TextStyle(fontSize: 16),),
                Text(
                   widget.initialJoiningDate == null ? 'No date selected'
                    : formatter.format(widget.initialJoiningDate!), style: const TextStyle(fontSize: 16),
                 ),
              ],
             ),
              const SizedBox(height: 30),

              Row(
              children: [
                const Text('Date Of Birth : ', style: TextStyle(fontSize: 16),),
                Text(
                   widget.initialDateOfBirth == null ? 'No date selected'
                    : formatter.format(widget.initialDateOfBirth!), style: const TextStyle(fontSize: 16),
                 ),
              ],
             ),
              const SizedBox(height: 16),

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
              const SizedBox(height: 16),
              
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

              const SizedBox(height: 16),

                TextFormField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the location.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: vehicleModelController,
                decoration: const InputDecoration(labelText: 'Vehicle Model'),
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the vehicle model.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),


              TextFormField(
                controller: vehicleNumberController,
                decoration: const InputDecoration(labelText: 'Vehicle Number'),
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
              ),
              const SizedBox(height: 16),

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
                            title: const Text('Truck'),
                            leading: Radio<String>(
                              value: 'truck',
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

                        const SizedBox(height: 50,),

                         Row(
                            children: [
                              const Text(
                                'Vehicle Color: ',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 15),
                              // Dropdown for vehicle colors
                                 Row(
                                   children: [
                                     DropdownButton<String>(
                                     value: _selectedVehicleColor, // Ensure this matches one of the items or is null
                                     dropdownColor: Theme.of(context).colorScheme.errorContainer,
                                     onChanged: (newValue) {
                                      setState(() {
                                        _selectedVehicleColor = newValue!;
                                       });
                                     },
                                     items: vehichle_color.keys.map<DropdownMenuItem<String>>((String key) {
                                      return DropdownMenuItem<String>(
                                         value: key,
                                         child: Row(
                                      children: [
                                        Container(
                                          width: 16,
                                          height: 16,
                                          color: vehichle_color[key],
                                        ),
                                        const SizedBox(width: 15,),
                                        Text(key),
                                      ],
                                    ),
                                       );
                                     }).toList(),
                                     hint: const Text('Select Vehicle Color'),
                                      ),
                                   ],
                                 ),
                            ],
                          ),



                         



              const SizedBox(height: 24),
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
                      setState(() {
                          _isUpdating = true; // Start updating
                         });
                      String? uploadedImageUrl;
                      if (_selectedImage != null) {
                        uploadedImageUrl = await _uploadImage(_selectedImage!);
                      }
                
                      Map<String, dynamic> updateInfo = {
                        "name": fullNameController.text,
                        "email": emailController.text,
                        "phone_number": phoneNumberController.text,
                        "location": locationController.text,
                        "vehicle_model" : vehicleModelController.text,
                        "vehicle_number" : vehicleNumberController.text,
                        "vehicle_type" : _selectedVehicleType,
                        "Vehicle_Color": _selectedVehicleColor,
                        if (uploadedImageUrl != null) "image_url": uploadedImageUrl,

                      };
                
                      await updateDeliveryDetail(widget.userId, updateInfo).then((value) {
                        Navigator.of(context).pop();    
                      }).then((value) {
                        showToastrMessage("Delivery user has been updated successfully.");
                      }).whenComplete(() {
                        setState(() {
                          _isUpdating = false;
                         });
                      });
                    }
                  },
                  child: _isUpdating ? const SizedBox(
                    height: 18, // Adjust the height for the spinner
                    width: 18,  // Adjust the width for the spinner
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ) : const Text('Update'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

