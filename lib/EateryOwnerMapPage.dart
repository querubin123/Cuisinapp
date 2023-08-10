// ignore: file_names
// ignore_for_file: use_build_context_synchronously

import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'EateryOwnerHomePage.dart';
import 'EateryOwnerSettingsPage.dart';
import 'EateryOwnerWeatherPage.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

Map<PolylineId, Polyline> _polylines = {};

class EateryOwnerMapPage extends StatefulWidget {
  late final String eateryName;
  late final String address;
  late final String description;
  late final String foodName;
  late final String category;
  late final String type;
  late final double price;
  late final List<String> imageUrls;

  EateryOwnerMapPage({
    super.key,
    required this.eateryName,
    required this.address,
    required this.description,
    required this.foodName,
    required this.category,
    required this.type,
    required this.price,
    required this.imageUrls,
  });
  @override
  // ignore: library_private_types_in_public_api
  _EateryOwnerMapPageState createState() => _EateryOwnerMapPageState();
}

class Eatery {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  Eatery({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class _EateryOwnerMapPageState extends State<EateryOwnerMapPage> {
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  // LatLng? _markerPosition;
  late GoogleMapController _controller;

  final places = GoogleMapsPlaces(
    apiKey: '',
  );

  List<Prediction> _suggestions = [];
  PlaceDetails? _selectedPlaceDetails;

  @override
  void dispose() {
    _mapController?.dispose(); // Dispose the GoogleMapController
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _addMarker();
    _retrieveSavedMarkerLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final Map<String, String>? routeArguments =
          ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
      if (routeArguments != null) {
        final String selectedAddress = routeArguments['address'] ?? '';
        _displayAddressOnMap(selectedAddress);
      }
    });

    // Reset all activity in Google Maps when the page is refreshed
    _markers.clear();
    _suggestions.clear();
    _selectedPlaceDetails = null;
    _searchController.clear();
    _polylines.clear();
  }

  void _addMarker() async {
    try {
      List<geocoding.Location> locations =
          await geocoding.locationFromAddress(widget.address);
      if (locations.isNotEmpty) {
        geocoding.Location location = locations.first;
        double latitude = location.latitude;
        double longitude = location.longitude;

        String markerId =
            'marker_${_markers.length}'; // Generate unique markerId

        // Store the marker in Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final uid = user.uid;

          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('markers')
              .doc(markerId)
              .set({
            'eateryName': widget.eateryName,
            'address': widget.address,
            'description': widget.description,
            'foodName': widget.foodName,
            'category': widget.category,
            'type': widget.type,
            'price': widget.price.toString(),
            'imageUrls': widget.imageUrls,
            'latitude': latitude,
            'longitude': longitude,
          });
        }

        // Create the marker object
        Marker newMarker = Marker(
          markerId: MarkerId(markerId),
          position: LatLng(latitude, longitude),
          onTap: () {
            _showMarkerDetailsEateryOwner(
              widget.eateryName,
              widget.address,
              widget.description,
              widget.foodName,
              widget.category,
              widget.type,
              widget.price.toString(),
              widget.imageUrls,
              markerId,
            );
          },
        );

        setState(() {
          _markers.add(newMarker);
          isValidAddress =
              true; // Set isValidAddress to true when a marker is added
        });

        _moveCameraToMarkerEatery(newMarker.position);
        _moveCameraToMarkerNavigator(latitude, longitude);
      } else {
        _showInvalidAddressError();
      }
    } catch (e) {
      _showInvalidAddressError();
    }
  }

  void _moveCameraToMarkerEatery(LatLng position) {
    _mapController?.animateCamera(CameraUpdate.newLatLng(position));
  }

  void _moveCameraToMarkerNavigator(double latitude, double longitude) {
    LatLng position = LatLng(latitude, longitude);
    _mapController?.animateCamera(CameraUpdate.newLatLng(position));
  }

  Future<void> _retrieveSavedMarkerLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;

      final QuerySnapshot markerSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('markers')
          .get();

      if (markerSnapshot.docs.isNotEmpty) {
        for (DocumentSnapshot doc in markerSnapshot.docs) {
          final Map<String, dynamic>? data =
              doc.data() as Map<String, dynamic>?;
          if (data != null) {
            double? markerLatitude = data['latitude'] as double?;
            double? markerLongitude = data['longitude'] as double?;
            String markerId = doc.id;

            if (markerLatitude != null && markerLongitude != null) {
              LatLng position = LatLng(markerLatitude, markerLongitude);
              List<dynamic> imageUrls = data['imageUrls'] as List<dynamic>;
              List<String> savedImageUrls = await getImageUrls(imageUrls);

              Marker savedMarker = Marker(
                markerId: MarkerId(markerId),
                position: position,
                onTap: () {
                  _showMarkerDetailsEateryOwner(
                    widget.eateryName,
                    widget.address,
                    widget.description,
                    widget.foodName,
                    widget.category,
                    widget.type,
                    widget.price.toString(),
                    savedImageUrls, // Pass the retrieved image URLs
                    markerId,
                  );
                },
              );

              setState(() {
                _markers.add(savedMarker);
                isValidAddress = true;
              });

              _moveCameraToMarkerEatery(savedMarker.position);
              _moveCameraToMarkerNavigator(markerLatitude, markerLongitude);
            }
          }
        }
      }
    }
  }

  Future<List<String>> getImageUrls(List<dynamic> inputUrls) async {
    List<String> imageUrls = [];

    for (var imageURL in inputUrls) {
      if (imageURL != null && imageURL is String) {
        if (imageURL.startsWith('gs://') || imageURL.startsWith('https://')) {
          // Image URL is already a download URL
          imageUrls.add(imageURL);
        } else {
          // Image URL is a Firebase Storage path, retrieve download URL
          final downloadUrl = await firebase_storage.FirebaseStorage.instance
              .ref(imageURL)
              .getDownloadURL();
          imageUrls.add(downloadUrl);
        }
      }
    }

    return imageUrls;
  }

  void _showMarkerDetailsEateryOwner(
    String eateryName,
    String address,
    String description,
    String foodName,
    String category,
    String type,
    String price,
    List<String> imageUrls,
    String markerId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;

      final DocumentSnapshot markerSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('markers')
          .doc(markerId)
          .get();

      if (markerSnapshot.exists) {
        final Map<String, dynamic>? data =
            markerSnapshot.data() as Map<String, dynamic>?;
        if (data != null) {
          String savedEateryName = data['eateryName'];
          String savedAddress = data['address'];
          String savedDescription = data['description'];
          String savedFoodName = data['foodName'];
          String savedCategory = data['category'];
          String savedType = data['type'];
          String savedPrice = data['price'];
          List<String> savedImageUrls = await getImageUrls(imageUrls);

          final formKey = GlobalKey<FormState>();
          TextEditingController eateryNameController =
              TextEditingController(text: savedEateryName);
          TextEditingController addressController =
              TextEditingController(text: savedAddress);
          TextEditingController descriptionController =
              TextEditingController(text: savedDescription);
          TextEditingController foodNameController =
              TextEditingController(text: savedFoodName);
          TextEditingController categoryController =
              TextEditingController(text: savedCategory);
          TextEditingController typeController =
              TextEditingController(text: savedType);
          TextEditingController priceController =
              TextEditingController(text: savedPrice);

          bool isPaid = savedType == 'Paid';

          showDialog(
            context: context,
            builder: (_) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: Stack(
                            children: [
                              if (savedImageUrls.isNotEmpty)
                                SizedBox(
                                  height: double.infinity,
                                  width: double.infinity,
                                  child: PageView.builder(
                                    itemCount: savedImageUrls.length,
                                    itemBuilder: (_, index) {
                                      final imageUrl = savedImageUrls[index];
                                      return Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                              Positioned(
                                top: 10,
                                left: 10,
                                child: IconButton(
                                  icon: const Icon(Icons.share),
                                  onPressed: () {
                                    _showShareOptions(
                                        eateryName, description, imageUrls);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Eatery Name:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              TextFormField(
                                controller: eateryNameController,
                                enabled: true,
                                style: const TextStyle(fontSize: 16),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Address:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              TextFormField(
                                controller: addressController,
                                enabled: false,
                                style: const TextStyle(fontSize: 16),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Description:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              TextFormField(
                                controller: descriptionController,
                                enabled: true,
                                style: const TextStyle(fontSize: 16),
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Food Name:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              TextFormField(
                                controller: foodNameController,
                                enabled: true,
                                style: const TextStyle(fontSize: 16),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Category:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              DropdownButtonFormField<String>(
                                value: savedCategory,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Best Seller',
                                    child: Text('Best Seller'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Sale',
                                    child: Text('Sale'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'New',
                                    child: Text('New'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Cheap',
                                    child: Text('Cheap'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    savedCategory = value!;
                                  });
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Type:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              DropdownButtonFormField<String>(
                                value: savedType,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Free',
                                    child: Text('Free'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Paid',
                                    child: Text('Paid'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    savedType = value!;
                                    if (value == 'Free') {
                                      isPaid = false;
                                      priceController.clear();
                                    } else {
                                      isPaid = true;
                                    }
                                  });
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Price:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              TextFormField(
                                controller: priceController,
                                enabled: isPaid,
                                style: const TextStyle(fontSize: 16),
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  hintText: isPaid ? 'Enter price' : 'Free',
                                ),
                                validator: (value) {
                                  if (isPaid &&
                                      (value == null || value.isEmpty)) {
                                    return 'Please enter a price.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (formKey.currentState!.validate()) {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text('Confirmation'),
                                              content: const Text(
                                                'Are you sure you want to update the marker?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    Navigator.of(context).pop();
                                                    final updatedData = {
                                                      'eateryName':
                                                          eateryNameController
                                                              .text,
                                                      'address':
                                                          addressController
                                                              .text,
                                                      'description':
                                                          descriptionController
                                                              .text,
                                                      'foodName':
                                                          foodNameController
                                                              .text,
                                                      'category':
                                                          categoryController
                                                              .text,
                                                      'type':
                                                          typeController.text,
                                                      'price':
                                                          priceController.text,
                                                      'imageUrls': imageUrls,
                                                    };

                                                    try {
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection('users')
                                                          .doc(uid)
                                                          .collection('markers')
                                                          .doc(markerId)
                                                          .update(updatedData);

                                                      Fluttertoast.showToast(
                                                        msg:
                                                            'Marker updated successfully',
                                                        toastLength:
                                                            Toast.LENGTH_SHORT,
                                                        gravity:
                                                            ToastGravity.BOTTOM,
                                                        timeInSecForIosWeb: 1,
                                                        backgroundColor:
                                                            Colors.green,
                                                        textColor: Colors.white,
                                                      );

                                                      Navigator.of(context)
                                                          .pop();
                                                    } catch (e) {
                                                      Fluttertoast.showToast(
                                                        msg:
                                                            'Failed to update marker: $e',
                                                        toastLength:
                                                            Toast.LENGTH_SHORT,
                                                        gravity:
                                                            ToastGravity.BOTTOM,
                                                        timeInSecForIosWeb: 1,
                                                        backgroundColor:
                                                            Colors.red,
                                                        textColor: Colors.white,
                                                      );
                                                    }
                                                  },
                                                  child: const Text('Update'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                    },
                                    child: const Text('Update'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      showDialog(
                                        context: context,
                                        builder: (_) {
                                          return AlertDialog(
                                            title: const Text('Delete Marker'),
                                            content: const Text(
                                              'Are you sure you want to delete this marker?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text('Cancel'),
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: const Color.fromARGB(
                                                      255, 199, 234, 159),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                height: 36.0,
                                                child: TextButton(
                                                  onPressed: () async {
                                                    try {
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection('users')
                                                          .doc(uid)
                                                          .collection('markers')
                                                          .doc(markerId)
                                                          .delete();

                                                      Fluttertoast.showToast(
                                                        msg:
                                                            'Marker deleted successfully',
                                                        toastLength:
                                                            Toast.LENGTH_SHORT,
                                                        gravity:
                                                            ToastGravity.BOTTOM,
                                                        timeInSecForIosWeb: 1,
                                                        backgroundColor:
                                                            Colors.green,
                                                        textColor: Colors.white,
                                                      );

                                                      Navigator.of(context)
                                                          .pop();
                                                    } catch (e) {
                                                      Fluttertoast.showToast(
                                                        msg:
                                                            'Failed to delete marker: $e',
                                                        toastLength:
                                                            Toast.LENGTH_SHORT,
                                                        gravity:
                                                            ToastGravity.BOTTOM,
                                                        timeInSecForIosWeb: 1,
                                                        backgroundColor:
                                                            Colors.red,
                                                        textColor: Colors.white,
                                                      );
                                                    }
                                                  },
                                                  child: const Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
      }
    }
  }

  void _showShareOptions(
      String eateryName, String description, List<String> imageUrls) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Share'),
              onTap: () {
                _shareContent(eateryName, description, imageUrls);
              },
            ),
          ],
        );
      },
    );
  }

  void _shareContent(
      String eateryName, String description, List<String> imageUrls) {
    // Implement your share functionality here
    // You can use the share package or any other preferred method for sharing content
    // Example using the share package:
    const baseUrl =
        'https://www.cuisinap.tech'; // Replace with your actual website domain
    final eateryUrl = '$baseUrl/eateries/$eateryName';

    String message = 'Check out $eateryName: $description\n\n$eateryUrl';
    Share.share(message);
  }

  void _moveCameraToMarker(MarkerId markerId) {
    // Find the marker with the provided markerId
    Marker marker =
        _markers.firstWhere((marker) => marker.markerId == markerId);

    // Animate the camera position to the marker's position
    _controller.animateCamera(
      CameraUpdate.newLatLng(marker.position),
    );
  }

  String? _selectedPlaceId;
  MarkerId searchedLocationMarkerId = const MarkerId('searchedLocation');
  MarkerId currentLocationMarkerId = const MarkerId('currentLocation');
  PlacesAutocompleteResponse? _autocompleteResponse;
  Timer? _typingTimer;
  Marker? selectedMarker;
  bool isValidAddress = false; // Initialize the isValidAddress field

  void searchLocation(String? searchText, {int radius = 5000}) async {
    if (searchText != null && searchText.isNotEmpty) {
      if (isValidCoordinates(searchText)) {
        final coordinates = searchText.split(',');
        final latitude = double.tryParse(coordinates[0].trim());
        final longitude = double.tryParse(coordinates[1].trim());

        if (latitude != null && longitude != null) {
          _updateCameraPosition(latitude, longitude);
          _clearMarkers();
          _addSearchedLocationMarker(latitude, longitude);
          _clearSuggestions();
          return;
        }
      }

      PlacesAutocompleteResponse autocompleteResponse =
          await places.autocomplete(
        searchText,
        components: [
          Component(Component.country, "ph"),
        ],
      );

      if (autocompleteResponse.isOkay &&
          autocompleteResponse.predictions.isNotEmpty) {
        setState(() {
          _autocompleteResponse = autocompleteResponse;
          _suggestions = _autocompleteResponse!.predictions;
        });

        List<Marker> updatedMarkers = [];

        for (Prediction prediction in _suggestions) {
          PlacesDetailsResponse? detailsResponse =
              await places.getDetailsByPlaceId(prediction.placeId!);

          if (detailsResponse.isOkay) {
            double? latitude = detailsResponse.result.geometry?.location.lat;
            double? longitude = detailsResponse.result.geometry?.location.lng;

            if (latitude != null && longitude != null) {
              String country =
                  await _getCountryFromCoordinates(latitude, longitude);
              if (country == 'Philippines') {
                Marker? marker;
                marker = Marker(
                  markerId: MarkerId(prediction.placeId!),
                  position: LatLng(latitude, longitude),
                  infoWindow: InfoWindow(title: prediction.description),
                  visible: true,
                  onTap: () =>
                      _handleMarkerTap(marker!, detailsResponse.result),
                );

                updatedMarkers.add(marker);

                if (_selectedPlaceId == prediction.placeId) {
                  _clearMarkers();
                  _updateCameraPosition(latitude, longitude);
                  _markers.addAll(updatedMarkers);
                  setState(() {});
                }
              }
            }
          }
        }

        if (updatedMarkers.isEmpty) {
          _clearMarkers();
          _showInvalidAddressError();
          isValidAddress = false; // Set isValidAddress to false
        } else {
          _clearMarkers();
          setState(() {
            _markers.addAll(updatedMarkers);
          });
          isValidAddress = true; // Set isValidAddress to true
        }

        _startTypingTimer(); // Start the typing timer
      } else {
        setState(() {
          _autocompleteResponse = autocompleteResponse;
          _suggestions = _autocompleteResponse!.predictions;
        });
      }
    } else {
      _clearMarkers();
      _clearSuggestions();

      _startTypingTimer(); // Start the typing timer
    }
  }

  void _handleMarkerTap(Marker marker, PlaceDetails result) {
    _showMarkerDetails(result);
    _clearSuggestions();
    _clearMarkers();
    _markers.clear();
    _markers.add(marker);
    selectedMarker = marker;
    setState(() {});
  }

  Future<String> _getCountryFromCoordinates(
      double latitude, double longitude) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isNotEmpty) {
      String country = placemarks.first.country ?? '';
      return country;
    }
    return '';
  }

  void _showInvalidAddressError() {
    if (!isValidAddress && _autocompleteResponse != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid address or not in the Philippines',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _startTypingTimer() {
    // Cancel any existing typing timer
    _cancelTypingTimer();

    // Start a new typing timer with a delay of 1500 milliseconds (1.5 seconds)
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      _clearSuggestions();
    });
  }

  void _cancelTypingTimer() {
    if (_typingTimer != null && _typingTimer!.isActive) {
      _typingTimer!.cancel();
    }
  }

  void _clearSuggestions() {
    setState(() {
      _suggestions = [];
    });
  }

  void _clearMarkers() {
    setState(() {
      _markers.removeWhere(
        (marker) =>
            marker.markerId != currentLocationMarkerId &&
            marker.markerId != searchedLocationMarkerId,
      );
    });
  }

  void _addSearchedLocationMarker(double latitude, double longitude) {
    setState(() {
      _markers.add(
        Marker(
          markerId: searchedLocationMarkerId,
          position: LatLng(latitude, longitude),
          infoWindow: const InfoWindow(title: 'Searched Location'),
        ),
      );
    });
  }

  void _showMarkerDetails(PlaceDetails result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(result.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Address: ${result.formattedAddress ?? ''}'),
                Row(
                  children: [
                    const Text(
                      'Rating: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    RatingBarIndicator(
                      rating: (result.rating ?? 0.0).toDouble(),
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: Colors.yellow,
                      ),
                      itemCount: 5,
                      itemSize: 20.0,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Adding a horizontal ListView.builder to display images
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: result.photos.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${result.photos[index].photoReference}&key=',
                            width: 400,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Reviews:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                // Adding a ListView.builder to display reviews
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: result.reviews.length,
                  itemBuilder: (context, index) {
                    final review = result.reviews[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reviewer: ${review.authorName}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        RatingBarIndicator(
                          rating: review.rating.toDouble(),
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Colors.yellow,
                          ),
                          itemCount: 5,
                          itemSize: 20.0,
                        ),
                        Text(review.text),
                        const SizedBox(height: 10),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                const Text(
                  'Opening Hours:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                // Displaying the opening hours
                Text(result.openingHours?.weekdayText.join('\n') ??
                    'Not available'),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.directions),
                  onPressed: () {
                    // Set _selectedPlaceDetails to the selected place details
                    _selectedPlaceDetails = result;

                    // Call _createPolyline to create the polyline
                    _createPolyline();
                  },
                ),
                // IconButton(
                //   icon: Icon(
                //     Icons.favorite,
                //     color: Colors.red,
                //   ),
                //   onPressed: () {
                //     _saveAsFavorite(result.formattedAddress!, result.name);
                //   },
                // ),
                TextButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<double> calculateDistance(double latitude, double longitude) async {
    const double earthRadius = 6371; // Earth's radius in kilometers

    try {
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      double lat1 = currentPosition.latitude;
      double lon1 = currentPosition.longitude;

      double lat2 = latitude;
      double lon2 = longitude;

      double dLat = _toRadians(lat2 - lat1);
      double dLon = _toRadians(lon2 - lon1);

      double a = pow(sin(dLat / 2), 2) +
          cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * pow(sin(dLon / 2), 2);

      double c = 2 * atan2(sqrt(a), sqrt(1 - a));

      double distance = earthRadius * c * 1000; // Convert to meters

      return distance;
    } catch (e) {
      // Handle any errors that occur during location retrieval
      return 0.0; // Return a default distance of 0 in case of an error
    }
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  void selectPlace(Prediction prediction) async {
    PlacesDetailsResponse? detailsResponse =
        await places.getDetailsByPlaceId(prediction.placeId!);

    double? latitude = detailsResponse.result.geometry?.location.lat;
    double? longitude = detailsResponse.result.geometry?.location.lng;

    if (latitude != null && longitude != null) {
      _updateCameraPosition(latitude, longitude);
      setState(() {
        _clearMarkers();
        _markers.add(
          Marker(
            markerId: searchedLocationMarkerId,
            position: LatLng(latitude, longitude),
            infoWindow: InfoWindow(title: prediction.description),
            visible: true,
          ),
        );
        _selectedPlaceId = prediction.placeId;
        _suggestions.clear();
      });
    }
  }

  bool isValidCoordinates(String input) {
    const pattern =
        r'^[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)$';
    final regExp = RegExp(pattern);
    return regExp.hasMatch(input);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _updateCameraPosition(double latitude, double longitude) async {
    // Remove previous marker from previous location
    if (mounted) {
      setState(() {
        _markers.removeWhere(
            (marker) => marker.markerId == searchedLocationMarkerId);
      });
    }

    CameraPosition cameraPosition = CameraPosition(
      target: LatLng(latitude, longitude),
      zoom: 12,
    );

    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(cameraPosition),
    );

    // Add a delay of 500 milliseconds before adding the marker
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        // Add new marker to the new search location
        _markers.add(
          Marker(
            markerId: searchedLocationMarkerId,
            position: LatLng(latitude, longitude),
            infoWindow: const InfoWindow(title: 'Searched Location'),
          ),
        );
      });
    }
  }

  // ignore: unused_element
  void _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      // Location service is disabled, prompt the user to enable it
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Enable Location Service',
                style: TextStyle(color: Colors.black)),
            content: const Text(
                'Please enable the location service to proceed.',
                style: TextStyle(color: Colors.black)),
            actions: [
              TextButton(
                child: const Text('No thanks',
                    style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Open Settings',
                    style: TextStyle(color: Colors.blue)),
                onPressed: () {
                  Navigator.of(context).pop();
                  Geolocator.openLocationSettings();
                },
              ),
            ],
          );
        },
      );
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Handle denied or denied forever case
        // Show a dialog or snackbar informing the user
        return;
      }
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      try {
        Position position = await Geolocator.getCurrentPosition();
        _updateCameraPosition(position.latitude, position.longitude);
      } catch (e) {
        // Handle any other exceptions if necessary
      }
    }
  }

  // ignore: unused_element
  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition();

    _updateCameraPosition(position.latitude, position.longitude);
  }

  void _onSuggestionSelected(Prediction suggestion) async {
    PlacesDetailsResponse detailsResponse =
        await places.getDetailsByPlaceId(suggestion.placeId!);

    double? latitude = detailsResponse.result.geometry?.location.lat;
    double? longitude = detailsResponse.result.geometry?.location.lng;

    if (latitude != null && longitude != null) {
      _updateCameraPosition(latitude, longitude);
      setState(() {
        _selectedPlaceId = suggestion.placeId;
        _selectedPlaceDetails = detailsResponse.result;
        _suggestions = []; // Clear the suggestions list
      });

      // Clear the text field
      _searchController.clear();

      // Clear the markers and update the UI
      setState(() {
        _clearMarkers();
      });

      // Perform a new search based on the selected keyword
      searchLocation(suggestion.description);
    }
  }

  Widget _buildSuggestionItem(Prediction prediction) {
    return GestureDetector(
      onTap: () {
        _onSuggestionSelected(prediction);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.grey),
            const SizedBox(width: 10.0),
            Expanded(
              child: Text(
                prediction.description!,
                style: const TextStyle(fontSize: 16.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsContainer() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _suggestions.isNotEmpty ? 200.0 : 0.0,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
          bottomLeft: Radius.circular(20.0),
          bottomRight: Radius.circular(20.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8.0), // Add padding to the top
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          return _buildSuggestionItem(_suggestions[index]);
        },
      ),
    );
  }

  Future<Uint8List?> getPlacePhoto(String? photoReference) async {
    if (photoReference == null) return null;

    String apiKey = '';
    String url =
        'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$apiKey';

    http.Response response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }

    return null;
  }

  Widget _buildPlaceDetailsCard() {
    if (_selectedPlaceDetails == null) {
      return Container(); // Return an empty container if no place details are selected
    }

    String formattedAddress = _selectedPlaceDetails!.formattedAddress ?? '';
    // final String name = _selectedPlaceDetails?.name ?? '';

    num rating = _selectedPlaceDetails!.rating ?? 0.0;
    String photoReference = _selectedPlaceDetails!.photos.isNotEmpty
        ? _selectedPlaceDetails!.photos[0].photoReference
        : '';

    return Dismissible(
      key: Key(_selectedPlaceDetails!.placeId), // Added null check here
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {
        setState(() {
          _selectedPlaceDetails = null;
        });
      },
      child: GestureDetector(
        onTap:
            _showPlaceDetails, // Open the details dialog when the card is tapped
        child: Container(
          margin: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4.0, // Add elevation to create a floating effect
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 80.0,
                      decoration: BoxDecoration(
                        image: photoReference.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(
                                  'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=',
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4.0)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formattedAddress,
                            style: const TextStyle(
                                fontSize: 16.0, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4.0),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 12.0),
                              const SizedBox(width: 2.0),
                              Text(
                                rating.toString(),
                                style: const TextStyle(fontSize: 12.0),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.directions),
                      onPressed: () {
                        _createPolyline();
                      },
                    ),
                  ],
                ),
                // Positioned(
                //   top: 8.0,
                //   right: 8.0,
                //   child: IconButton(
                //     icon: Icon(
                //       Icons.favorite,
                //       color: Colors.red,
                //     ),
                //     onPressed: () {
                //       _saveAsFavorite(formattedAddress,
                //           name); // Save the place as a favorite
                //     },
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  final List<String> _distanceTexts = [];
  final List<String> _durationTexts = [];
  // ignore: unused_field
  String _destinationPlace = "";
  String _currentLocation = "";

  void _createPolyline() async {
    Position currentPosition = await Geolocator.getCurrentPosition();
    LatLng sourceLatLng = LatLng(
      currentPosition.latitude,
      currentPosition.longitude,
    );
    LatLng destinationLatLng = LatLng(
      _selectedPlaceDetails!.geometry!.location.lat,
      _selectedPlaceDetails!.geometry!.location.lng,
    );
    _updateCurrentLocation(currentPosition); // Update current location
    String apiUrl =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${sourceLatLng.latitude},${sourceLatLng.longitude}&destination=${destinationLatLng.latitude},${destinationLatLng.longitude}&key=';

    var response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      List<LatLng> points = [];

      if (data['routes'] != null && data['routes'].length > 0) {
        var routes = data['routes'];

        for (var route in routes) {
          var legs = route['legs'];

          for (var leg in legs) {
            var distanceText = leg['distance']['text'];
            var durationText = leg['duration']['text'];
            var steps = leg['steps'];

            List<String> instructions = [];

            for (var step in steps) {
              var pointsEncoded = step['polyline']['points'];
              var decodedPoints = decodePolyline(pointsEncoded);

              for (var decodedPoint in decodedPoints) {
                points.add(LatLng(decodedPoint[0], decodedPoint[1]));
              }

              var instructionText = step['html_instructions'];
              var plainTextInstruction = _stripHtmlTags(instructionText);
              instructions.add(plainTextInstruction);
            }

            showDirectionsGuide(
              distanceText,
              durationText,
              _currentLocation,
              instructions,
            );

            _distanceTexts.add(distanceText);
            _durationTexts.add(durationText);
          }
        }
      }

      PolylineId polylineId = const PolylineId("polyline");
      Polyline polyline = Polyline(
        polylineId: polylineId,
        color: const Color.fromARGB(255, 195, 8, 142),
        width: 3,
        points: points,
        onTap: () {},
      );

      List<Marker> markers = [];

      IconData icon = Icons.directions_car;

      Marker marker = Marker(
        markerId: const MarkerId('Car'),
        position: destinationLatLng,
        onTap: () {},
        icon: icon == Icons.directions_car
            ? BitmapDescriptor.defaultMarker
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );

      markers.add(marker);

      setState(() {
        _polylines.clear();
        _polylines[polylineId] = polyline;
        _markers.clear();
        _markers.addAll(markers);
        _destinationPlace = _selectedPlaceDetails!.name;
      });
    } else {
      // ignore: avoid_print
      print('Error: ${response.statusCode}');
    }
  }

  void showDirectionsGuide(
    String distanceText,
    String durationText,
    String currentLocation,
    List<String> instructions,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Directions Guide'),
          content: LimitedBox(
            maxHeight: MediaQuery.of(context).size.height *
                0.5, // Adjust the maxHeight value as needed
            child: SingleChildScrollView(
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Transportation Mode: Car'),
                    Text('Distance: $distanceText'),
                    Text('Duration: $durationText'),
                    Text('Current Location: $currentLocation'),
                    const SizedBox(height: 10),
                    const Text('Instructions:'),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: instructions.map((instruction) {
                        return Text(instruction);
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _stripHtmlTags(String htmlText) {
    final regex = RegExp(r'<[^>]+>');
    return htmlText.replaceAll(regex, '');
  }

  void _updateCurrentLocation(Position position) {
    setState(() {
      _currentLocation =
          'Lat: ${position.latitude}, Lng: ${position.longitude}';
    });
  }

  List<List<double>> decodePolyline(String polyline) {
    List<List<double>> polyPoints = [];
    int index = 0, len = polyline.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;

      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      double latitude = lat / 1E5;
      double longitude = lng / 1E5;

      polyPoints.add([latitude, longitude]);
    }

    return polyPoints;
  }

  String submittedReview = ''; // New variable to store the submitted review
  double submittedRating = 0.0; // New variable to store the submitted rating

  void _showPlaceDetails() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String review = '';
        // ignore: unused_local_variable
        double rating = 0.0;

        return Dialog(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedPlaceDetails?.name ?? 'Unknown Place',
                        style: const TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        _selectedPlaceDetails?.formattedAddress ??
                            'Address not available',
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.normal,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      FutureBuilder<String?>(
                        future:
                            _getPlaceDetails(_selectedPlaceDetails?.placeId),
                        builder: (BuildContext context,
                            AsyncSnapshot<String?> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (snapshot.hasError || snapshot.data == null) {
                            return const Text(
                              'Description not available',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.normal,
                                color: Colors.black54,
                              ),
                            );
                          }
                          return Text(
                            'Description:\n${snapshot.data}',
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.normal,
                              color: Colors.black54,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16.0),
                      if (_selectedPlaceDetails?.photos != null &&
                          _selectedPlaceDetails!.photos.isNotEmpty)
                        SizedBox(
                          height: 200.0,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedPlaceDetails!.photos.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8.0),
                                child: Image.network(
                                  _buildPhotoUrl(
                                    _selectedPlaceDetails!
                                        .photos[index].photoReference,
                                  ),
                                  fit: BoxFit.cover,
                                  width: 400,
                                  height: 200,
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 16.0),
                      if (_selectedPlaceDetails?.website != null)
                        GestureDetector(
                          onTap: () =>
                              _launchWebsite(_selectedPlaceDetails!.website!),
                          child: Text(
                            'Website: ${_selectedPlaceDetails!.website!}',
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.normal,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16.0),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            review =
                                value; // Update the review as the user types
                          });
                        },
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Enter your review...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      RatingBar.builder(
                        initialRating: 0,
                        minRating: 0,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemSize: 24.0,
                        itemBuilder: (context, _) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        onRatingUpdate: (value) {
                          setState(() {
                            rating = value; // Update the rating value
                          });
                        },
                      ),
                      const SizedBox(height: 16.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Review: ${submittedReview.isNotEmpty ? submittedReview : review}',
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.normal,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          if (submittedRating != 0.0)
                            Row(
                              children: [
                                const Text(
                                  'My Rating:',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(width: 4.0),
                                Row(
                                  children: List.generate(
                                    5,
                                    (index) => Icon(
                                      index < submittedRating.toInt()
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _launchWebsite(String url) async {
    // ignore: deprecated_member_use
    if (await canLaunch(url)) {
      // ignore: deprecated_member_use
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<String?> _getPlaceDetails(String? placeId) async {
    if (placeId == null) return null;

    const apiKey = ''; // Replace with your actual API key
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResult = json.decode(response.body);
        if (jsonResult['status'] == 'OK') {
          final result = jsonResult['result'];
          final name = result['name'];
          final address = result['formatted_address'];
          final phoneNumber = result['formatted_phone_number'];
          final website = result['website'];
          final description = result['description'];

          String openingHours = '';
          if (result['opening_hours'] != null &&
              result['opening_hours']['weekday_text'] != null) {
            final weekdayText =
                result['opening_hours']['weekday_text'] as List<dynamic>;
            openingHours = weekdayText.join('\n');
          } else {
            openingHours = 'Opening hours not available';
          }

          String reviews = '';
          if (result['reviews'] != null) {
            final reviewList = result['reviews'] as List<dynamic>;
            reviews = _buildReviewsList(reviewList).replaceAll('\n', '\n\n');
          } else {
            reviews = 'No reviews available';
          }

          final details =
              'Name: $name\nAddress: $address\nPhone Number: $phoneNumber\nWebsite: $website\nDescription: $description\nOpening Hours:\n$openingHours\n\nReviews:\n$reviews';
          return details;
        }
      }
    } catch (e) {
      print('Error retrieving place details: $e');
    }

    return null;
  }

  String _buildReviewsList(List<dynamic> reviewList) {
    return reviewList.map((review) {
      final authorName = review['author_name'];
      final rating = review['rating'];
      final comment = review['text'];

      // Replace the rating number with a star icon
      final starRating =
          '★' * rating.toInt(); // Use ★ for filled star, ☆ for empty star

      return '''
Author: $authorName
Rating: $starRating
Comment: $comment
''';
    }).join('\n');
  }

  String _buildPhotoUrl(String photoReference) {
    const apiKey = ''; // Replace with your actual API key
    const maxWidth = 400;
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/photo?maxwidth=$maxWidth&photoreference=$photoReference&key=$apiKey',
    );

    return url.toString();
  }

  void _displayAddressOnMap(String address) async {
    PlacesAutocompleteResponse response = await places.autocomplete(
      address,
      components: [
        Component(Component.country, "ph"),
      ],
    );

    if (response.isOkay && response.predictions.isNotEmpty) {
      Prediction selectedPrediction = response.predictions.first;

      PlacesDetailsResponse detailsResponse =
          await places.getDetailsByPlaceId(selectedPrediction.placeId!);

      double? latitude = detailsResponse.result.geometry?.location.lat;
      double? longitude = detailsResponse.result.geometry?.location.lng;

      if (latitude != null && longitude != null) {
        _updateCameraPosition(latitude, longitude);
        setState(() {
          _suggestions = [];
          _selectedPlaceDetails = detailsResponse.result;
        });
      }
    }
  }

  bool _isSatelliteMap = false;

  void _toggleMapType() {
    setState(() {
      _isSatelliteMap = !_isSatelliteMap;
    });
  }

  void navigateToWeatherPage(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height,
            child: GoogleMap(
              mapType: _isSatelliteMap ? MapType.satellite : MapType.normal,
              onMapCreated: _onMapCreated,
              polylines: Set<Polyline>.of(_polylines.values),
              initialCameraPosition: const CameraPosition(
                target: LatLng(
                  14.4064,
                  120.9405,
                ),
                zoom: 12,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
          Positioned(
            top: 60.0,
            left: 16.0,
            right: 16.0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 6.0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 120.0,
            left: 16.0,
            right: 16.0,
            child: _buildSuggestionsContainer(),
          ),
          Positioned(
            bottom: 16.0,
            left: 16.0,
            right: 16.0,
            child: Hero(
              tag: 'placeDetailsCard',
              child: _buildPlaceDetailsCard(),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _toggleMapType,
            backgroundColor: const Color(0xFFCDE990),
            child: Icon(
              _isSatelliteMap ? Icons.map : Icons.satellite,
              size: 24.0,
            ),
          ),
          const SizedBox(height: 16.0),
          Container(
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.all(3.0), // Adjust the padding as desired
              child: IconButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EateryOwnerHomePage(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.fastfood,
                  size: 24.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
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
                onPressed: () =>
                    navigateToWeatherPage(context), // Pass the context here
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
}
