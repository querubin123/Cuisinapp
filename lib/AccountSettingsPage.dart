import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'SignInUserPage.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cached_network_image/cached_network_image.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final ImagePicker _imagePicker = ImagePicker();
  dynamic _profilePicture;
  String _userName = "";

  Future<void> _pickImage() async {
    final pickedImage =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _profilePicture = File(pickedImage.path);
      });
    } else {
      Fluttertoast.showToast(
        msg: 'Unable to access the device\'s gallery.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _saveChanges() async {
    // Save profile picture to Firebase Storage if it's a File
    if (_profilePicture is File) {
      File imageFile = _profilePicture;
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      firebase_storage.Reference ref =
          firebase_storage.FirebaseStorage.instance.ref().child(fileName);

      try {
        await ref.putFile(imageFile);
        String profilePictureURL = await ref.getDownloadURL();

        // Update user profile picture URL in Firestore
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'profilePicture': profilePictureURL}).then((value) {
            setState(() {
              _profilePicture = profilePictureURL;
            });
            // Display a toast message after successful update
            Fluttertoast.showToast(
              msg: 'Profile picture updated.',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.blue,
              textColor: Colors.white,
            );
          }).catchError((error) {
            // Display a toast message for the error
            Fluttertoast.showToast(
              msg: 'Failed to update profile picture.',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
          });
        }
      } catch (error) {
        // Display a toast message for the error
        Fluttertoast.showToast(
          msg: 'Failed to upload profile picture.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.email ?? "";
      });

      // Retrieve user data from Firestore
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .get();
      Map<String, dynamic>? userData = snapshot.data();

      if (userData != null && userData.containsKey('profilePicture')) {
        dynamic profilePictureData = userData['profilePicture'];

        if (profilePictureData is String && profilePictureData.isNotEmpty) {
          setState(() {
            _profilePicture = profilePictureData;
          });
        } else if (profilePictureData is Map &&
            profilePictureData.containsKey('path')) {
          setState(() {
            _profilePicture = File(profilePictureData['path']);
          });
        }
      }

      // Store user email in Firestore
      FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': _userName,
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24.0),
              _buildProfilePicture(),
              const SizedBox(height: 16.0),
              _buildSettingItem(
                Icons.delete,
                'Delete Account',
                _showDeleteConfirmationDialog,
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ElevatedButton.icon(
                      onPressed: _saveChanges,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCDE990),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0),
                        textStyle: const TextStyle(fontSize: 18.0),
                        elevation: 2.0,
                        shadowColor: Colors.green.withOpacity(0.3),
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

  Widget _buildProfilePicture() {
    if (_profilePicture != null) {
      if (_profilePicture is File) {
        return _buildEditableProfilePicture(
          CircleAvatar(
            radius: 64.0,
            backgroundImage: FileImage(_profilePicture),
          ),
        );
      } else if (_profilePicture is String) {
        return _buildEditableProfilePicture(
          CircleAvatar(
            radius: 64.0,
            backgroundImage: CachedNetworkImageProvider(_profilePicture),
          ),
        );
      } else {
        return Container(); // Handle unsupported type or show a placeholder
      }
    } else {
      return GestureDetector(
        onTap: _pickImage,
        child: AvatarGlow(
          glowColor: Theme.of(context).primaryColor,
          endRadius: 64.0,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[200],
                radius: 64.0,
                child: Text(
                  _getInitials(),
                  style: const TextStyle(fontSize: 32.0),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 16.0,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.edit,
                    size: 16.0,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildEditableProfilePicture(Widget profilePicture) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: profilePicture,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: CircleAvatar(
            radius: 16.0,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.edit,
              size: 16.0,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials() {
    List<String> names = _userName.split(" ");
    String initials = "";
    int numWords = names.length > 2 ? 2 : names.length;
    for (int i = 0; i < numWords; i++) {
      initials += names[i][0].toUpperCase();
    }
    return initials;
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[300]!,
              width: 1.0,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 16.0),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text('Are you sure you want to delete your account?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              onPressed: _deleteAccount,
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteAccount() async {
    // Delete the user's account and associated data
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Example: Delete Firestore document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      // Example: Delete profile picture from Firebase Storage
      if (user.photoURL != null) {
        firebase_storage.Reference ref = firebase_storage
            .FirebaseStorage.instance
            .refFromURL(user.photoURL!);
        await ref.delete();
      }

// Delete user account
      try {
        await user.delete();
        // Display a toast message after successful deletion
        Fluttertoast.showToast(
          msg: 'Account deleted successfully.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
        );

        // Redirect to the sign-in page
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => SignInUserPage()),
        );
      } catch (error) {
        // Display a toast message for the error
        Fluttertoast.showToast(
          msg: 'Failed to delete account.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }
}
