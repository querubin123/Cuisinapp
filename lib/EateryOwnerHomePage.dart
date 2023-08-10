import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
// import 'package:firebase_storage/firebase_storage.dart';
import 'EateryOwnerMapPage.dart';
import 'EateryOwnerSettingsPage.dart';
import 'EateryOwnerWeatherPage.dart';
import 'HomePage.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class EateryOwnerHomePage extends StatefulWidget {
  const EateryOwnerHomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EateryOwnerHomePageState createState() => _EateryOwnerHomePageState();
}

class _EateryOwnerHomePageState extends State<EateryOwnerHomePage> {
  String eateryOwnerName = '';
  IconData? selectedIcon;
  List<File> selectedImages = [];
  String? selectedType;
  bool showPriceField = false;
  final TextEditingController priceController = TextEditingController();
  final TextEditingController eateryNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController foodNameController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final places = GoogleMapsPlaces(apiKey: '');
  final dialogKey = GlobalKey<State>();

  String? selectedCategory;
  Widget submittedDetails = Container();
  bool dataSubmitted = false;
  Map<String, dynamic>? retrievedData;

  @override
  void initState() {
    super.initState();
  }

  void navigateToWeatherPage() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EateryOwnerWeatherPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  void selectImages() async {
    List<XFile>? pickedImages = await ImagePicker().pickMultiImage(
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedImages.isNotEmpty) {
      List<File> images =
          pickedImages.map((image) => File(image.path)).toList();

      int remainingSlots = 5 - selectedImages.length;
      int allowedImagesCount =
          images.length <= remainingSlots ? images.length : remainingSlots;

      setState(() {
        if (selectedImages.length < 5) {
          selectedImages.addAll(images.sublist(0, allowedImagesCount));
        }
      });

      if (selectedImages.length >= 5) {
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('You can only select up to 5 images.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  void captureImageFromCamera() async {
    XFile? pickedImage = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedImage != null) {
      File image = File(pickedImage.path);

      setState(() {
        if (selectedImages.length < 5) {
          selectedImages.add(image);
        }
      });
    }
  }

  void removeImage(File image) {
    setState(() {
      selectedImages.remove(image);
    });
  }

  void onCategoryChanged(String? newValue) {
    setState(() {
      selectedCategory = newValue;
    });
  }

  void onTypeChanged(String? newValue) {
    setState(() {
      selectedType = newValue;
      if (selectedType == 'Free') {
        priceController.clear();
        showPriceField = false;
      } else {
        showPriceField = true;
      }
    });
  }

  Future<void> saveDataToFirestore(
    String eateryName,
    String address,
    String description,
    String foodName,
    String category,
    String type,
    double? price,
    List<File> images,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;

      List<String> imageUrls = [];

      // Upload images to Firebase Storage and retrieve their download URLs
      for (var i = 0; i < images.length; i++) {
        final imageFile = images[i];
        final storageRef = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('eateryImages')
            .child(uid)
            .child('${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        final uploadTask = storageRef.putFile(imageFile);
        final snapshot = await uploadTask.whenComplete(() => null);
        final downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      final Map<String, dynamic> data = {
        'eateryName': eateryName,
        'address': address,
        'description': description,
        'foodName': foodName,
        'category': category,
        'type': type,
        'price': price,
        'imageUrls': imageUrls,
      };

      // Save marker details to Firestore
      final CollectionReference markerRef = FirebaseFirestore.instance
          .collection('eateryOwners')
          .doc(uid)
          .collection('eaterySubmittedDetails');
      await markerRef.add(data);

      // Retrieve eatery details and pass them to EateryOwnerMapPage
      retrieveEateryDetails(
        eateryName,
        address,
        description,
        foodName,
        category,
        type,
        price!,
        imageUrls,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 25.0),
                child: Text(
                  'Submit Eatery Details',
                  style: TextStyle(
                    fontSize:
                        28.0, // Increase the font size for a more prominent heading
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing:
                        1.2, // Add a slight letter spacing for better readability
                    shadows: [
                      Shadow(
                        color: Colors.grey
                            .withOpacity(0.4), // Add a subtle shadow effect
                        offset: const Offset(2, 2),
                        blurRadius: 3.0,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: TextFormField(
                  controller: eateryNameController,
                  style: const TextStyle(
                    fontSize: 16.0,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Eatery Name',
                    labelStyle: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12.0),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.blue),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    errorStyle: const TextStyle(color: Colors.red),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter the eatery name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 8.0),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: addressController,
                        style: const TextStyle(
                          fontSize: 16.0,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Address',
                          labelStyle: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(12.0),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.blue),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.red),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          errorStyle: const TextStyle(color: Colors.red),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter the address';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        showAddressSuggestions(context);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8.0),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: TextFormField(
                  controller: descriptionController,
                  maxLength: 200, // Add max length counter
                  maxLines: null, // Allow multiple lines
                  style: const TextStyle(
                    fontSize: 16.0,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12.0),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.blue),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    errorStyle: const TextStyle(color: Colors.red),
                    counterText: '', // Hide the default character counter
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter the description';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 8.0),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: TextFormField(
                  controller: foodNameController,
                  decoration: InputDecoration(
                    labelText: 'Food Name',
                    labelStyle: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12.0),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.blue),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    errorStyle: const TextStyle(color: Colors.red),
                    prefixIcon: const Icon(
                      Icons.food_bank, // Add an appropriate icon
                      color: Colors.grey,
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter the food name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 8.0),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedType,
                  onChanged: onTypeChanged,
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'Free',
                      child: Text(
                        'Free',
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Paid',
                      child: Text(
                        'Paid',
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Type',
                    labelStyle: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(8.0),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.blue),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    errorStyle: const TextStyle(color: Colors.red),
                    prefixIcon: const Icon(
                      Icons.category,
                      color: Colors.grey,
                    ),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey,
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please select a type';
                    }
                    return null;
                  },
                  dropdownColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8.0),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedCategory,
                  onChanged: onCategoryChanged,
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'Best Seller',
                      child: Text(
                        'Best Seller',
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Sale',
                      child: Text(
                        'Sale',
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'New',
                      child: Text(
                        'New',
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Cheap',
                      child: Text(
                        'Cheap',
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(8.0),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.blue),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    errorStyle: const TextStyle(color: Colors.red),
                    prefixIcon: const Icon(
                      Icons.category,
                      color: Colors.grey,
                    ),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey,
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                  dropdownColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8.0),
              if (showPriceField)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Price',
                      labelStyle: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(8.0),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.blue),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      errorStyle: const TextStyle(color: Colors.red),
                      prefixIcon: const Icon(
                        Icons.attach_money,
                        color: Colors.grey,
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter the price';
                      }
                      return null;
                    },
                  ),
                ),
              const SizedBox(height: 8.0),
              SizedBox(
                width: double.infinity, // Make the container full width
                child: OutlinedButton.icon(
                  onPressed: () {
                    selectImages();
                  },
                  icon: const Icon(Icons.image),
                  label: const Text(
                    'Select Images',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 24.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: const BorderSide(
                        color: Colors.black,
                      ), // Add a border around the button
                    ),
                    backgroundColor:
                        Colors.grey[200], // Set the background color
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              SizedBox(
                width: double.infinity, // Make the container full width
                child: OutlinedButton.icon(
                  onPressed: () {
                    captureImageFromCamera();
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text(
                    'Capture Image',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 24.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: const BorderSide(
                        color: Colors.black,
                      ), // Add a border around the button
                    ),
                    backgroundColor:
                        Colors.grey[200], // Set the background color
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    bottom: 16.0), // Adjust the bottom margin value as desired
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: selectedImages.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing:
                        12.0, // Increase spacing between grid items horizontally
                    mainAxisSpacing:
                        12.0, // Increase spacing between grid items vertically
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                              8.0), // Add rounded corners to images
                          child: Image.file(
                            selectedImages[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8.0,
                          right: 8.0,
                          child: GestureDetector(
                            onTap: () {
                              removeImage(selectedImages[index]);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(
                                    0.5), // Add a semi-transparent background to the cancel button
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(
                                  4.0), // Adjust the padding as desired
                              child: const Icon(
                                Icons.cancel,
                                color: Colors.white,
                                size: 18.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(
                height: 48.0, // Set the desired height
                child: ElevatedButton(
                  onPressed: () {
                    String eateryName = eateryNameController.text;
                    String address = addressController.text;
                    String description = descriptionController.text;
                    String foodName = foodNameController.text;
                    String category = selectedCategory ?? '';
                    String type = selectedType ?? '';
                    double price = showPriceField
                        ? double.tryParse(priceController.text) ?? 0.0
                        : 0.0;

                    if (eateryName.isEmpty ||
                        address.isEmpty ||
                        description.isEmpty ||
                        foodName.isEmpty) {
                      Fluttertoast.showToast(
                        msg: 'Please fill in all necessary fields.',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      );
                      return;
                    } else {
                      saveDataToFirestore(
                        eateryName,
                        address,
                        description,
                        foodName,
                        category,
                        type,
                        price,
                        selectedImages,
                      );

                      // Reset the input fields after submission
                      eateryNameController.clear();
                      addressController.clear();
                      descriptionController.clear();
                      foodNameController.clear();
                      priceController.clear();

                      selectedCategory = null;
                      selectedType = null;
                      showPriceField = false;
                      selectedImages = [];

                      Fluttertoast.showToast(
                        msg: 'Submitted successfully!',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.green,
                        textColor: Colors.white,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.indigo, // Change the button background color
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 24.0), // Adjust the padding as needed
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          12.0), // Adjust the border radius as desired
                    ),
                    elevation: 6.0, // Add a more pronounced elevation effect
                    shadowColor: Colors.black
                        .withOpacity(0.4), // Add a darker shadow color
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              if (dataSubmitted) submittedDetails,
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EateryOwnerMapPage(
                eateryName: '',
                address: '',
                description: '',
                category: '',
                foodName: '',
                imageUrls: const [],
                type: '',
                price: 0.0, // Assign a default price value
              ),
            ),
          );
        },
        child: const Icon(Icons.map),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        EateryOwnerMapPage(
                      address: '',
                      category: '',
                      description: '',
                      eateryName: '',
                      foodName: '',
                      imageUrls: const [],
                      price: 0.0,
                      type: '',
                    ),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
              },
              icon: const Icon(Icons.home, size: 23.0),
            ),
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.yellow,
              ),
              padding: const EdgeInsets.all(7.0),
              child: IconButton(
                onPressed: () => navigateToWeatherPage(),
                icon: const Icon(
                  Icons.wb_sunny,
                  color: Colors.white,
                  size: 30.0,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const EateryOwnerSettingsPage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
              },
              icon: const Icon(Icons.settings, size: 23.0),
            ),
          ],
        ),
      ),
    );
  }

  void showAddressSuggestions(BuildContext context) async {
    // Implement the logic to show address suggestions here
    // You can use a dropdown or autocomplete widget to display the suggestions

    String inputText = addressController.text.trim();

    if (inputText.isNotEmpty) {
      PlacesAutocompleteResponse response = await places.autocomplete(
        inputText,
        language: "en",
        components: [Component(Component.country, "PH")],
      );

      List<Prediction> predictions = response.predictions;

      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Address Suggestions'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: predictions.length,
                itemBuilder: (context, index) {
                  Prediction prediction = predictions[index];
                  return ListTile(
                    title: Text(prediction.description!),
                    onTap: () {
                      // Handle the selection of a suggested address
                      String selectedAddress = prediction.description!;
                      // Do something with the selected address
                      addressController.text = selectedAddress;
                      Navigator.pop(dialogContext); // Close the dialog
                    },
                  );
                },
              ),
            ),
          );
        },
      );
    }
  }

  void retrieveEateryDetails(
    String eateryName,
    String address,
    String description,
    String foodName,
    String category,
    String type,
    double submittedPrice,
    List<String> imageUrls, // Rename 'imageUrls' to 'imageURLs'
  ) {
    // ...

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EateryOwnerMapPage(
          eateryName: eateryName,
          address: address,
          description: description,
          foodName: foodName,
          category: category,
          type: type,
          price: submittedPrice,
          imageUrls: imageUrls, // Change 'imageURLs' to 'imageURL'
        ),
      ),
    ).then((returnedData) {
      if (returnedData != null) {
        String updatedEateryName = returnedData['eateryName'];
        String updatedAddress = returnedData['address'];
        String updatedDescription = returnedData['description'];
        String updatedFoodName = returnedData['foodName'];
        String updatedCategory = returnedData['category'];
        String updatedType = returnedData['type'];
        double updatedSubmittedPrice = returnedData['submittedPrice'];
        List<String> updatedImageURLs =
            returnedData['imageURLs']; // Rename 'imageUrls' to 'imageURLs'

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              eateryName: updatedEateryName,
              address: updatedAddress,
              description: updatedDescription,
              foodName: updatedFoodName,
              category: updatedCategory,
              type: updatedType,
              submittedPrice: updatedSubmittedPrice,
              imageUrls: updatedImageURLs, // Rename 'imageUrls' to 'imageURLs'
            ),
          ),
        );
      }
    });
  }

  void main() {
    runApp(const MaterialApp(
      home: EateryOwnerHomePage(),
    ));
  }
}
