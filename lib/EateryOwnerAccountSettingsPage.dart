import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'EaterySignInPage.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cached_network_image/cached_network_image.dart';

class EateryOwnerAccountSettingsPage extends StatefulWidget {
  const EateryOwnerAccountSettingsPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EateryOwnerAccountSettingsPage createState() =>
      _EateryOwnerAccountSettingsPage();
}

class _EateryOwnerAccountSettingsPage
    extends State<EateryOwnerAccountSettingsPage> {
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
              .collection('eateryOwners')
              .doc(user.uid)
              .update({'profilePicture': profilePictureURL}).then((value) {
            setState(() {
              _profilePicture = profilePictureURL;
            });
            // Display Snackbar after successful update
            Fluttertoast.showToast(
              msg: 'Profile picture updated.',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.green,
              textColor: Colors.white,
            );
          }).catchError((error) {
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
          .collection('eateryOwners')
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
      FirebaseFirestore.instance.collection('eateryOwners').doc(user.uid).set({
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
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text('Are you sure you want to delete your account?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteAccount();
              },
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
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Delete profile picture if it exists
        String? profilePictureURL = await _getProfilePictureURL();
        if (profilePictureURL != null && profilePictureURL.isNotEmpty) {
          await firebase_storage.FirebaseStorage.instance
              .refFromURL(profilePictureURL)
              .delete();
        }

        // Delete user document from Firestore
        await FirebaseFirestore.instance
            .collection('eateryOwners')
            .doc(user.uid)
            .delete();

        // Delete user account
        await user.delete();

        // Display a toast message after successful deletion
        Fluttertoast.showToast(
          msg: 'Account deleted successfully.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        // Navigate back to sign-in page
        // ignore: use_build_context_synchronously
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => EaterySignInPage()),
          (Route<dynamic> route) => false,
        );
      } catch (error) {
        // Display a toast message for failed deletion
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

  Future<String?> _getProfilePictureURL() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('eateryOwners')
          .doc(user.uid)
          .get();
      Map<String, dynamic>? userData = snapshot.data();

      if (userData != null && userData.containsKey('profilePicture')) {
        dynamic profilePictureData = userData['profilePicture'];

        if (profilePictureData is String && profilePictureData.isNotEmpty) {
          return profilePictureData;
        } else if (profilePictureData is Map &&
            profilePictureData.containsKey('path')) {
          return null; // Return null if the profile picture is a File
        }
      }
    }
    return null;
  }

  String _getInitials() {
    if (_userName.isNotEmpty) {
      List<String> nameParts = _userName.split(' ');
      String firstNameInitial = nameParts[0][0];
      if (nameParts.length > 1) {
        String lastNameInitial = nameParts[nameParts.length - 1][0];
        return '$firstNameInitial$lastNameInitial';
      }
      return firstNameInitial;
    }
    return '';
  }
}
