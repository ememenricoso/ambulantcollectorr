import 'dart:io';
import 'package:ambulantcollector/STALLHOLDER/mainscaffold.dart';
import 'package:ambulantcollector/components/my_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _barangayController = TextEditingController();
  final _cityController = TextEditingController();
  final _primaryContactNumberController = TextEditingController();

  User? user;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user!.email ?? '';
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('approvedVendors')
          .doc(user!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _fullNameController.text =
              '${userDoc['firstName']} ${userDoc['lastName']}';
          _barangayController.text = userDoc['barangay'] ?? '';
          _cityController.text = userDoc['city'] ?? '';
          _primaryContactNumberController.text = userDoc['contactNumber'] ?? '';
          _uploadedImageUrl = userDoc['photoURL'];
        });
      } else {
        _showDialog('Error', 'User document does not exist.');
      }
    } catch (e) {
      _showDialog('Error', 'Failed to load user data: ${e.toString()}');
    }
  }

  Future<void> updateProfile() async {
    try {
      if (_imageFile != null) {
        await _uploadImage();
      }

      String? photoURL = _uploadedImageUrl ?? user!.photoURL;
      List<String> fullNameParts = _fullNameController.text.split(' ');
      String firstName = fullNameParts.first;
      String lastName = fullNameParts.sublist(1).join(' ');

      await FirebaseFirestore.instance
          .collection('approvedVendors')
          .doc(user!.uid)
          .update({
        'firstName': firstName,
        'lastName': lastName,
        'barangay': _barangayController.text,
        'city': _cityController.text,
        'contactNumber': _primaryContactNumberController.text,
        'photoURL': photoURL,
      });

      _showDialog('Success', 'Profile updated successfully.');
    } catch (e) {
      _showDialog('Error', 'Failed to update profile: ${e.toString()}');
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile != null) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${user!.uid}.jpg');
        final uploadTask = kIsWeb
            ? ref.putData(await _imageFile!.readAsBytes())
            : ref.putFile(File(_imageFile!.path));
        final snapshot = await uploadTask.whenComplete(() {});
        _uploadedImageUrl = await snapshot.ref.getDownloadURL();
      } catch (e) {
        _showDialog('Error', 'Failed to upload image: ${e.toString()}');
      }
    }
  }

  void _showImageSourceSelection() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Image Source'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final pickedFile =
                    await _picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                  setState(() {
                    _imageFile = pickedFile;
                  });
                }
              },
              child: Text('Camera'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final pickedFile =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    _imageFile = pickedFile;
                  });
                }
              },
              child: Text('Gallery'),
            ),
          ],
        );
      },
    );
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 3,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    GestureDetector(
                      onTap: _showImageSourceSelection,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color.fromARGB(255, 129, 49, 49),
                        backgroundImage: _imageFile != null
                            ? FileImage(File(_imageFile!.path))
                            : (_uploadedImageUrl != null &&
                                    _uploadedImageUrl!.isNotEmpty
                                ? NetworkImage(_uploadedImageUrl!)
                                    as ImageProvider<Object>
                                : null),
                        child: _imageFile == null && _uploadedImageUrl == null
                            ? Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.camera_alt, color: Colors.green),
                      onPressed: _showImageSourceSelection,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  "Profile Information",
                  style: GoogleFonts.roboto(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _buildProfileField("Full Name", _fullNameController, true),
                _buildProfileField("Barangay", _barangayController),
                _buildProfileField("City", _cityController),
                _buildProfileField(
                    "Primary Contact Number", _primaryContactNumberController),
                _buildProfileField("Email Address", _emailController, true),
                const SizedBox(height: 24),
                MyButton(
                  onTap: updateProfile,
                  buttonText: "Update Profile",
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, TextEditingController controller,
      [bool readOnly = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: label == "Full Name"
              ? Icon(Icons.person)
              : label == "Barangay"
                  ? Icon(Icons.home)
                  : label == "City"
                      ? Icon(Icons.location_city)
                      : label == "Primary Contact Number"
                          ? Icon(Icons.phone)
                          : Icon(Icons.email),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
        ),
      ),
    );
  }
}
