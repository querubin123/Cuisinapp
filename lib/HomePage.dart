// ignore: file_names
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:geolocator/geolocator.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'FavoritesPage.dart';
import 'SettingsPage.dart';
import 'WeatherPage.dart';
import 'dart:convert';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'dart:math' show sin, cos, sqrt, atan2, pi;

class HomePage extends StatefulWidget {
  late final String eateryName;
  late final String address;
  late final String description;
  late final String foodName;
  late final String category;
  late final String type;
  late final double submittedPrice;
  late final List<String> imageUrls;

  // ignore: prefer_const_constructors_in_immutables
  HomePage({
    super.key,
    required this.eateryName,
    required this.address,
    required this.description,
    required this.foodName,
    required this.category,
    required this.type,
    required this.submittedPrice,
    required this.imageUrls,
  });

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

// Map<PolylineId, Polyline> _polylines = {};
PolylinePoints polylinePoints = PolylinePoints();
List<Polyline> _polylines = [];

FavoritesPage favoritesPage = const FavoritesPage();

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  final places = GoogleMapsPlaces(
    apiKey: 'AIzaSyCy_6nXlu1udc4QyLb0fp4aWkr9reo6Nr8',
  );

  // Other members and methods

  double degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  double calculateHaversineDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const int earthRadius = 6371000; // in meters
    final double dLat = degreesToRadians(lat2 - lat1);
    final double dLon = degreesToRadians(lon2 - lon1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(degreesToRadians(lat1)) *
            cos(degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  List<Prediction> _suggestions = [];

  @override
  void dispose() {
    _mapController?.dispose(); // Dispose the GoogleMapController
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchMarkerDetails();
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
            'price': widget.submittedPrice.toString(),
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
              widget.submittedPrice.toString(),
              widget.imageUrls.join(', '),
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
      // ignore: avoid_print
      print('Error geocoding address: $e');
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
                    widget.submittedPrice.toString(),
                    savedImageUrls.join(', '),
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

  Future<List<String>> getImageUrls(dynamic imageUrls) async {
    List<String> savedImageUrls = [];

    if (imageUrls != null) {
      if (imageUrls is String) {
        // Handle single image URL
        String imageUrl = imageUrls;
        if (imageUrl.startsWith('gs://') || imageUrl.startsWith('https://')) {
          try {
            final downloadUrl = await firebase_storage.FirebaseStorage.instance
                .refFromURL(imageUrl)
                .getDownloadURL();

            savedImageUrls.add(downloadUrl);
          } catch (e) {
            // ignore: avoid_print
            print('Error retrieving image URL: $e');
          }
        }
      } else if (imageUrls is List<dynamic>) {
        // Handle list of image URLs
        for (var imageUrl in imageUrls) {
          if (imageUrl != null &&
              (imageUrl.toString().startsWith('gs://') ||
                  imageUrl.toString().startsWith('https://'))) {
            try {
              final downloadUrl = await firebase_storage
                  .FirebaseStorage.instance
                  .refFromURL(imageUrl.toString())
                  .getDownloadURL();

              savedImageUrls.add(downloadUrl);
            } catch (e) {
              // ignore: avoid_print
              print('Error retrieving image URL: $e');
            }
          }
        }
      }
    }

    return savedImageUrls;
  }

  void _showMarkerDetailsEateryOwner(
    String eateryName,
    String address,
    String description,
    String foodName,
    String category,
    String type,
    String price,
    String? imageURL,
    String markerId,
  ) async {
    double rating = 0.0;
    TextEditingController reviewController = TextEditingController();
    TextEditingController fullNameController = TextEditingController();

    List<String> imageUrls = await getImageUrls(imageURL);

    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      if (imageUrls.isNotEmpty)
                        SizedBox(
                          height: double.infinity,
                          width: double.infinity,
                          child: PageView.builder(
                            itemCount: imageUrls.length,
                            itemBuilder: (context, index) {
                              return Image.network(
                                imageUrls[index],
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
                      Positioned(
                        top: 10,
                        left: 50,
                        child: IntrinsicWidth(
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.favorite_border),
                                onPressed: () {
                                  String place = '$eateryName;$address';

                                  if (!FavoritesPage.favoritePlaces
                                      .contains(place)) {
                                    FavoritesPage.addFavoritePlace(place);

                                    Fluttertoast.showToast(
                                      msg: 'Added to favorites',
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.BOTTOM,
                                      timeInSecForIosWeb: 2,
                                      backgroundColor: Colors.grey[900],
                                      textColor: Colors.white,
                                    );
                                  } else {
                                    Fluttertoast.showToast(
                                      msg: 'Already added to favorites',
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.BOTTOM,
                                      timeInSecForIosWeb: 2,
                                      backgroundColor: Colors.grey[900],
                                      textColor: Colors.white,
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.directions),
                                onPressed: () async {
                                  Position position =
                                      await Geolocator.getCurrentPosition();
                                  double currentLatitude = position.latitude;
                                  double currentLongitude = position.longitude;
                                  _createPolylineEatery(currentLatitude,
                                      currentLongitude, address);
                                  // ignore: use_build_context_synchronously
                                  Navigator.pop(
                                      context); // Exit the container after creating the polyline
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.wb_sunny),
                                onPressed: _showWeatherDialog,
                              ),
                            ],
                          ),
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
                      Text(
                        eateryName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Address: $address',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Description: $description',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Food Name: $foodName',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Category: $category',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Type: $type',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Price: $price',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        height: 40,
                        child: RatingBar.builder(
                          initialRating: rating,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemPadding:
                              const EdgeInsets.symmetric(horizontal: 4.0),
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (newRating) {
                            setState(() {
                              rating = newRating;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: reviewController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Review',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          String review = reviewController.text;
                          String fullName = fullNameController.text;
                          DateTime now = DateTime.now();
                          String formattedDate =
                              "${now.year}-${now.month}-${now.day}";

                          String? userEmail =
                              FirebaseAuth.instance.currentUser?.email;

                          if (review.isNotEmpty) {
                            FirebaseFirestore.instance
                                .collection('reviews')
                                .add({
                              'eateryName': eateryName,
                              'rating': rating,
                              'review': review,
                              'date': formattedDate,
                              'userEmail': userEmail,
                              'fullName': fullName,
                              'address': address
                            }).then((_) {
                              Fluttertoast.showToast(
                                msg: 'Review submitted',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.green,
                                textColor: Colors.white,
                              );

                              Navigator.of(context).pop();
                            }).catchError((error) {
                              Fluttertoast.showToast(
                                msg: 'Error submitting review',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                              );
                            });
                          } else {
                            Fluttertoast.showToast(
                              msg: 'Review cannot be empty',
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                            );
                          }
                        },
                        child: const Text('Submit Review'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWeatherDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StreamBuilder<DataSnapshot>(
          stream: _fetchWeatherDataStream(),
          builder:
              (BuildContext context, AsyncSnapshot<DataSnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                title: Text('Loading'),
                content: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Error'),
                content: const Text('Failed to retrieve weather data.'),
                actions: [
                  TextButton(
                    child: const Text('Close'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            } else if (!snapshot.hasData || snapshot.data == null) {
              return AlertDialog(
                title: const Text('No Data'),
                content: const Text('No weather data available.'),
                actions: [
                  TextButton(
                    child: const Text('Close'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            } else {
              // Retrieve weather data from snapshot
              dynamic weatherData = snapshot.data?.value;
              double temperature =
                  double.parse(weatherData['temperature'].toString());
              double humidity =
                  double.parse(weatherData['humidity'].toString());
              double pressure =
                  double.parse(weatherData['pressure'].toString());
              double altitude =
                  double.parse(weatherData['altitude'].toString());
              String rainIntensity = weatherData['rainIntensity'].toString();

              return Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Weather Data',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Temperature: $temperature'),
                      Text('Humidity: $humidity'),
                      Text('Pressure: $pressure'),
                      Text('Altitude: $altitude'),
                      Text('Rain Intensity: $rainIntensity'),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Stream<DataSnapshot> _fetchWeatherDataStream() {
    DatabaseReference weatherRef =
        // ignore: deprecated_member_use
        FirebaseDatabase.instance.reference().child('weatherdata');
    return weatherRef.onValue.map((event) => event.snapshot);
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

  void _createPolylineEatery(
    double currentLatitude,
    double currentLongitude,
    String address,
  ) async {
    // Use geocoding service to convert the address to coordinates
    List<geocoding.Location> locations =
        await geocoding.locationFromAddress(address);
    if (locations.isEmpty) {
      // Handle the case when the address is not valid
      return;
    }

    // Get the coordinates of the destination location
    double eateryLatitude = locations.first.latitude;
    double eateryLongitude = locations.first.longitude;

    // Prepare the request URL for the Directions API
    String apiKey =
        'AIzaSyCy_6nXlu1udc4QyLb0fp4aWkr9reo6Nr8'; // Replace with your Google Maps API key
    String baseUrl = 'https://maps.googleapis.com/maps/api/directions/json?';
    String origin = '$currentLatitude,$currentLongitude';
    String destination = '$eateryLatitude,$eateryLongitude';
    String url = '$baseUrl&origin=$origin&destination=$destination&key=$apiKey';

    // Send the HTTP request to the Directions API
    http.Response response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      // Parse the JSON response
      Map<String, dynamic> data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        // Extract the polyline points from the response
        List<LatLng> polylinePoints = [];
        List<dynamic> steps = data['routes'][0]['legs'][0]['steps'];
        for (var step in steps) {
          String encodedPolyline = step['polyline']['points'];
          polylinePoints.addAll(_decodePolyline(encodedPolyline));
        }

        // Remove existing polylines from the map
        setState(() {
          _polylines.removeWhere((Polyline polyline) =>
              polyline.polylineId.value == 'eatery_polyline');
        });

        // Create a Polyline instance
        Polyline polyline = Polyline(
          polylineId: const PolylineId('eatery_polyline'),
          points: polylinePoints,
          color: const Color.fromARGB(255, 243, 33, 229),
          width: 3,
        );

        // Add the polyline to the map
        setState(() {
          _polylines.add(polyline);
        });

        // Extract the directions from the response
        List<dynamic> routeSteps = data['routes'][0]['legs'][0]['steps'];
        List<String> directions = [];
        for (var step in routeSteps) {
          String instruction = _stripHTMLTags(step['html_instructions']);
          directions.add(instruction);
        }
// Display the dialog box
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Polyline Created'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Polylines have been added to the map.',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  const Text('Directions:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: directions.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Text('${index + 1}. ${directions[index]}');
                      },
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  String _stripHTMLTags(String htmlText) {
    RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    return htmlText.replaceAll(exp, '');
  }

  List<LatLng> _decodePolyline(String encodedPolyline) {
    List<LatLng> polylinePoints = [];
    int index = 0, len = encodedPolyline.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int shift = 0, result = 0;
      int byte;
      do {
        byte = encodedPolyline.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      int deltaLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += deltaLat;

      shift = 0;
      result = 0;
      do {
        byte = encodedPolyline.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      int deltaLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += deltaLng;

      double latitude = lat / 1e5;
      double longitude = lng / 1e5;
      LatLng point = LatLng(latitude, longitude);
      polylinePoints.add(point);
    }

    return polylinePoints;
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
    // _showMarkerDetails(result);
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

  void _onMapCreated(GoogleMapController controller) {}
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

  void _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      // Location service is disabled, prompt the user to enable it
      // ignore: use_build_context_synchronously
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
        _getCurrentLocation(position.latitude, position.longitude);
      } catch (e) {
        // Handle any other exceptions if necessary
      }
    }
  }

  void _getCurrentLocation(double latitude, double longitude) async {
    _updateCameraPosition(latitude, longitude);
  }

  void navigateToWeatherPage() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const WeatherPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
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

  bool showFilterContainer = false;
  bool showDistanceOptions = false;
  int? selectedOption;
  int? selectedDistance;
  String? selectedCity;

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Filter Options',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text(
                          'Popular Eateries (Top 5)',
                          style: TextStyle(fontSize: 16),
                        ),
                        leading: Radio<int>(
                          value: 0,
                          groupValue: selectedOption,
                          onChanged: (value) {
                            setState(() {
                              selectedOption = value;
                              showFilterContainer = false;
                              showDistanceOptions = false;
                              selectedCity =
                                  null; // Reset selectedCity to default
                              selectedDistance =
                                  null; // Reset selectedDistance to default
                            });
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (selectedOption == 0) {
                                applyFiltersAndSearch();
                                Navigator.pop(context);
                                Fluttertoast.showToast(
                                  msg: 'Filters applied!',
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  backgroundColor: Colors.black87,
                                  textColor: Colors.white,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              resetFilters();
                              Fluttertoast.showToast(
                                msg: 'Filters reset!',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.black87,
                                textColor: Colors.white,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text('Reset'),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context); // Close the bottom sheet
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static const apiKey = 'AIzaSyCy_6nXlu1udc4QyLb0fp4aWkr9reo6Nr8';

  Future<double?> getLatitudeForCity(String city) async {
    final encodedCity = Uri.encodeQueryComponent(city);
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedCity&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'];
      if (results != null && results.isNotEmpty) {
        final location = results[0]['geometry']['location'];
        final latitude = location['lat'];
        return latitude;
      }
    }

    return null;
  }

  Future<double?> getLongitudeForCity(String city) async {
    final encodedCity = Uri.encodeQueryComponent(city);
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedCity&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'];
      if (results != null && results.isNotEmpty) {
        final location = results[0]['geometry']['location'];
        final longitude = location['lng'];
        return longitude;
      }
    }

    return null;
  }

  void resetFilters() {
    setState(() {
      selectedOption = 0;
      selectedCity = null;
      selectedDistance = null;
      showFilterContainer = false;
      showDistanceOptions = false;
      dataLogs.clear(); // Clear the dataLogs map
    });
  }

  Future<List<Map<String, dynamic>>> getPopularEateries() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .orderBy('rating', descending: true)
        .limit(5)
        .get();

    List<Map<String, dynamic>> popularEateries = querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .where((data) => data['eateryName'] != null)
        .toList();

    return popularEateries;
  }

  List<Map<String, dynamic>> searchResult = [];
  List<Marker> markers = [];
  String query = '';
  bool popularEateriesSelected = false;
  bool showSuggestionsContainer = false;
  List<Marker> filteredMarkers = [];

  void searchFromFirebase(String newQuery, bool filterByPopular) async {
    setState(() {
      query = newQuery;
      showSuggestionsContainer = true;
    });

    if (query.isEmpty) {
      setState(() {
        searchResult = [];
        markers = [];
        showSuggestionsContainer = false;
      });
      return;
    }

    final querySnapshot =
        await FirebaseFirestore.instance.collectionGroup('markers').get();

    setState(() {
      if (query.length == 1) {
        searchResult =
            querySnapshot.docs.map((doc) => doc.data()).where((data) {
          String eateryName = data['eateryName'] ?? '';
          return eateryName.toLowerCase().startsWith(query.toLowerCase());
        }).toList();
      } else {
        searchResult = querySnapshot.docs
            .map((doc) => doc.data())
            .where((data) =>
                data['eateryName'] != null &&
                    data['eateryName']
                        .toLowerCase()
                        .contains(query.toLowerCase()) ||
                data['latitude'] != null &&
                    data['latitude'].toString().contains(query) ||
                data['longitude'] != null &&
                    data['longitude'].toString().contains(query))
            .toList();
      }

      if (filterByPopular) {
        getPopularEateries().then((popularEateries) {
          searchResult.retainWhere((data) => popularEateries
              .any((popular) => popular['eateryName'] == data['eateryName']));
        });
      }

      if (searchResult.isNotEmpty) {
        if (selectedOption == 1) {
          filterByCityAndDistance(selectedCity!, selectedDistance!.toDouble())
              .then((filteredEateryNames) {
            // Update the markers on the map
            updateMarkers(filteredEateryNames);
          });
        } else {
          markers = searchResult.map((data) {
            double latitude = data['latitude'] ?? 0.0;
            double longitude = data['longitude'] ?? 0.0;
            String eateryName = data['eateryName'] ?? '';
            String address = data['address'] ?? '';
            String description = data['description'] ?? '';
            String foodName = data['foodName'] ?? '';
            String category = data['category'] ?? '';
            String type = data['type'] ?? '';
            double submittedPrice = data['submittedPrice']?.toDouble() ?? 0.0;
            List<String> imageUrls =
                (data['imageUrls'] as List<dynamic>).cast<String>();

            return Marker(
              markerId: MarkerId(eateryName),
              position: LatLng(latitude, longitude),
              infoWindow: InfoWindow(title: eateryName),
              onTap: () {
                _showMarkerDetailsEateryOwner(
                  eateryName,
                  address,
                  description,
                  foodName,
                  category,
                  type,
                  submittedPrice.toString(),
                  imageUrls.join(', '),
                  eateryName,
                );
              },
            );
          }).toList();

          // Retrieve the highest rating from the "reviews" collection
          FirebaseFirestore.instance
              .collection('reviews')
              .orderBy('rating', descending: true)
              .limit(1)
              .get()
              .then((reviewsSnapshot) {
            if (reviewsSnapshot.docs.isNotEmpty) {
              // Use the highest rating as needed
              // Here you can update your UI or perform any other actions
            }
          });
        }
      } else {
        markers = [];
      }
    });
  }

// Declare the list of markers as a class variable
  void applyFiltersAndSearch() {
    if (selectedOption == 0) {
      // Apply filter for popular eateries
      getPopularEateries().then((popularEateries) {
        setState(() {
          dataLogs = {for (var e in popularEateries) e['eateryName']: true};
        });

        // Perform the search based on the selected filters
        searchFromFirebase(query, true);
      });
    } else if (selectedOption == 1) {
      // Apply filter based on selected city and distance
      if (selectedCity != null && selectedDistance != null) {
        double distanceInKilometers = 0.0; // Default value

        if (selectedDistance == 0) {
          distanceInKilometers = 0.5; // 500 meters
        } else if (selectedDistance == 1) {
          distanceInKilometers = 2.0; // 2 kilometers
        }

        filterByCityAndDistance(selectedCity!, distanceInKilometers)
            .then((filteredEateries) {
          setState(() {
            dataLogs = {for (var e in filteredEateries) e['eateryName']: true};
          });
          // Update the markers on the map
          updateMarkers(filteredEateries);
          // Filter markers based on the selected city
          filterMarkersByCity(selectedCity!);
        });
      } else {}
    }
  }

  void filterMarkersByCity(String selectedCity) {
    filteredMarkers = markers.where((marker) {
      String markerAddress = marker.infoWindow.snippet ?? '';
      String cityName = getCityNameFromAddress(markerAddress);

      return cityName.toLowerCase().contains(selectedCity.toLowerCase());
    }).toList();

    setState(() {});
  }

  Future<List<Map<String, dynamic>>> filterByCityAndDistance(
      String selectedCity, double selectedDistance) async {
    // Get the user's current location
    Position currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Fetch eateries from Firestore based on the selected city
    List<Map<String, dynamic>> eateries =
        await fetchEateriesByCity(selectedCity);

    // Filter eateries based on selected city and distance
    List<Map<String, dynamic>> filteredEateries = eateries.where((eatery) {
      double eateryLatitude = eatery['latitude'].toDouble();
      double eateryLongitude = eatery['longitude'].toDouble();

      // Calculate the distance between the user's current location and the eatery
      double distanceInMeters = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        eateryLatitude,
        eateryLongitude,
      );

      // Convert the distance from meters to kilometers
      double distanceInKilometers = distanceInMeters / 1000;

      // Check if the eatery is within the selected city or distance
      return distanceInKilometers <= selectedDistance;
    }).toList();

    return filteredEateries;
  }

  Future<List<Map<String, dynamic>>> fetchEateriesByCity(
      String selectedCity) async {
    // Fetch eateries from Firestore
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('markers').get();

    // Convert the fetched documents to a list of maps
    List<Map<String, dynamic>> eateries = querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    // Filter eateries based on selected city
    List<Map<String, dynamic>> filteredEateries = eateries.where((eatery) {
      // Perform reverse geocoding to extract the city name from the address
      String address = eatery['address'].toString();
      String cityName = getCityNameFromAddress(address);

      return cityName.toLowerCase().contains(selectedCity.toLowerCase());
    }).toList();

    return filteredEateries;
  }

  String getCityNameFromAddress(String address) {
    List<String> addressParts = address.split(',');

    for (String part in addressParts) {
      String trimmedPart = part.trim().toLowerCase();
      if (trimmedPart.contains(selectedCity!.toLowerCase())) {
        return part.trim();
      }
    }

    return '';
  }

// Update the markers on the map
  void updateMarkers(List<dynamic> eateries) {
    List<Marker> newMarkers = eateries.map((eatery) {
      double latitude = eatery['latitude'] ?? 0.0;
      double longitude = eatery['longitude'] ?? 0.0;
      String eateryName = eatery['eateryName'] ?? '';

      return Marker(
        markerId: MarkerId(eateryName),
        position: LatLng(latitude, longitude),
        // Add other properties like icon, info window, etc. if needed
      );
    }).toList();

    setState(() {
      markers = newMarkers;
    });
  }

// Define a global variable to store the data
  Map<String, dynamic> dataLogs = {};
  Widget _buildSuggestionsContainer() {
    if (query.isEmpty || searchResult.isEmpty || !showSuggestionsContainer) {
      return Container();
    } else {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
        ),
        height: 200,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: searchResult.length > 5 ? 5 : searchResult.length,
          itemBuilder: (BuildContext context, int index) {
            Map<String, dynamic> data = searchResult[index];
            double latitude = data['latitude'] ?? 0.0;
            double longitude = data['longitude'] ?? 0.0;
            String eateryName = data['eateryName'] ?? '';
            String markerId = 'marker_$index';
            String city = data['address'] ?? '';

            bool isPopular =
                dataLogs.containsKey(eateryName) && dataLogs[eateryName];

            // Check if the eatery is within the selected city and distance
            bool isWithinCityAndDistance = selectedOption ==
                    0 || // Always true for "Popular Eateries" filter
                (selectedOption == 1 &&
                    filteredMarkers.any(
                        (marker) => marker.infoWindow.title == eateryName));

            if (selectedOption == 1 && !isWithinCityAndDistance) {
              return Container(); // Skip displaying this eatery in the list
            }

            return ListTile(
              visualDensity: VisualDensity.compact,
              leading: isPopular
                  ? const Icon(
                      Icons.star,
                      color: Colors.orange,
                    )
                  : const Icon(
                      Icons.fastfood,
                      color: Colors.red,
                    ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eateryName,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'location: $city',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              onTap: () async {
                _addMarkerRetrieveEatery(
                  LatLng(latitude, longitude),
                  eateryName,
                  markerId,
                );
                setState(() {
                  query = '';
                  showSuggestionsContainer = false;
                });

                _handleEateryNameTap(eateryName, latitude, longitude);
              },
            );
          },
        ),
      );
    }
  }

  Future<String> fetchUserEmail(String eateryName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Check if the email is already stored in SharedPreferences
    String? storedEmail = prefs.getString(eateryName);
    if (storedEmail != null && storedEmail.isNotEmpty) {
      print('Email found in SharedPreferences: $storedEmail');
      return storedEmail;
    }

    // Fetch the email from Firestore
    // Example implementation using Firebase Firestore
    QuerySnapshot markersSnapshot = await FirebaseFirestore.instance
        .collection('markers')
        .where('eateryName', isEqualTo: eateryName)
        .limit(1)
        .get();

    if (markersSnapshot.docs.isNotEmpty) {
      // Fetch all documents from the 'users' collection
      QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      for (QueryDocumentSnapshot userDoc in usersSnapshot.docs) {
        // Check if the 'userId' field of the user document matches the 'userId' from the 'markers' collection
        if (userDoc.get('userId').toString() ==
            // ignore: duplicate_ignore
            markersSnapshot.docs[0].get('userId').toString()) {
          String userEmail = userDoc.get('email').toString();

          // Store the fetched email in SharedPreferences
          prefs.setString(eateryName, userEmail);
          // ignore: avoid_print
          print('Fetched email from Firestore: $userEmail');

          return userEmail;
        }
      }
    }

    print('Email not found');
    return ''; // Return an empty string or handle the case when the email is not found
  }

  void onEmailTap(String email) async {
    // Fetch the user's email based on the selected email
    String userEmailAddress = await fetchUserEmail(email);

    // Perform any desired actions with the retrieved userEmailAddress
    print('User email address: $userEmailAddress');

    // Pass the user's email to the UserLogsPage without navigation

    // Use the userLogsPage instance as desired, without automatically navigating
  }

  Future<void> _addSelectedEateryData({
    required double latitude,
    required double longitude,
    required String eateryName,
    required String markerId,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? storedData = prefs.getStringList('selectedEateryData');

    storedData ??= [];

    Map<String, dynamic> newData = {
      'latitude': latitude,
      'longitude': longitude,
      'eateryName': eateryName,
      'markerId': markerId,
    };

    storedData.add(jsonEncode(newData));

    await prefs.setStringList('selectedEateryData', storedData);
  }

  void _handleEateryNameTap(
    String eateryName,
    double latitude,
    double longitude,
  ) async {
    // Perform the desired action with the tapped eateryName, latitude, and longitude
    print('Tapped eateryName: $eateryName');
    print('Latitude: $latitude');
    print('Longitude: $longitude');

    // Save the data to shared preferences
    await _addSelectedEateryData(
      latitude: latitude,
      longitude: longitude,
      eateryName: eateryName,
      markerId: '', // Provide the markerId if needed
    );

    // Define the desired action to be performed when an eatery name is tapped in the DataLogsPage
    // You can pass the tapped data to another method or perform any other logic here
    print('Tapped eatery name in DataLogsPage: $eateryName');
    print('Tapped latitude in DataLogsPage: $latitude');
    print('Tapped longitude in DataLogsPage: $longitude');
  }

  void _addMarkerRetrieveEatery(
      LatLng position, String eateryName, String markerId) {
    Marker newMarker = Marker(
      markerId: MarkerId(markerId), // Use markerId directly as the markerId
      position: position,
      infoWindow: InfoWindow(title: eateryName),
      onTap: () {
        _showMarkerDetailsEateryOwner(
          eateryName,
          widget.address,
          widget.description,
          widget.foodName,
          widget.category,
          widget.type,
          widget.submittedPrice.toString(),
          widget.imageUrls.join(', '),
          markerId,
        );
      },
    );

    setState(() {
      markers.add(newMarker);
    });

    // Animate the camera to the marker's position
    _mapController?.animateCamera(CameraUpdate.newLatLng(position));
  }

  bool filterByPopular = false;
  List<String> metroManilaCities = [
    'Caloocan City',
    'Cavite City',
    'Las Piñas City',
    'Makati City',
    'Malabon City',
    'Mandaluyong City',
    'Manila City',
    'Marikina City',
    'Muntinlupa City',
    'Navotas City',
    'Parañaque City',
    'Pasay City',
    'Pasig City',
    'Pateros City',
    'Quezon City',
    'San Juan City',
    'Taguig City',
    'Valenzuela City',
  ];

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
              polylines: _polylines.toSet(),
              markers: Set<Marker>.of(markers),
              initialCameraPosition: const CameraPosition(
                target: LatLng(
                  14.4064,
                  120.9405,
                ),
                zoom: 12,
              ),
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
              child: Row(
                children: [
                  const SizedBox(width: 10.0),
                  GestureDetector(
                    onTap: () {
                      showGPSUbloxModule(context);
                    },
                    child: const Icon(Icons.gps_fixed),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 16.0),
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        border: InputBorder.none,
                      ),
                      onChanged: (query) {
                        setState(() {
                          searchFromFirebase(query, filterByPopular);
                        });
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        showFilterContainer = !showFilterContainer;
                        if (showFilterContainer) {
                          _showFilterDialog(context);
                        }
                      });
                    },
                    icon: const Icon(Icons.filter_list, color: Colors.grey),
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
            bottom: 10.0, // Move the row to the bottom
            left: 16.0,
            right: 16.0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start, // Adjust alignment
                children: [
                  SizedBox(width: 16.0), // Add initial spacing

                  // Updated filter buttons for cities
                  ...metroManilaCities.map((city) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (selectedCity == city) {
                              selectedCity =
                                  ''; // Deselect the city if already selected
                            } else {
                              selectedCity = city; // Select the city
                            }
                            filterByCity(selectedCity!);
                          });
                        },
                        child: Text(
                          city,
                          style: TextStyle(
                            fontSize: 14.0,
                            color: selectedCity == city
                                ? Colors.white
                                : Colors
                                    .black, // Change text color based on selection
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          primary: selectedCity == city
                              ? Colors.green
                              : Colors
                                  .blue, // Change primary color based on selection
                          onPrimary: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 16.0,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  SizedBox(width: 16.0), // Add final spacing
                ],
              ),
            ),
          ),
          // ... (other Positioned elements)
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _checkLocationPermission,
            child: const Icon(Icons.gps_fixed),
            backgroundColor: const Color(0xFFCDE990),
          ),
          Hero(
            tag: 'mapToggleFab',
            child: Container(
              margin: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton(
                onPressed: _toggleMapType,
                style: ElevatedButton.styleFrom(
                  primary: const Color(0xFFCDE990),
                  shape: const CircleBorder(),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(
                    _isSatelliteMap ? Icons.map : Icons.satellite,
                    size: 24.0,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
                        HomePage(
                            address: '',
                            description: '',
                            foodName: '',
                            imageUrls: const [],
                            type: '',
                            submittedPrice: 0.0,
                            category: '',
                            eateryName: ''),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) =>
                            FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.home, size: 23.0),
            ),
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFCDE990),
              ),
              padding: const EdgeInsets.all(7.0),
              child: IconButton(
                onPressed: navigateToWeatherPage,
                icon: const Icon(Icons.cloud, size: 30.0, color: Colors.white),
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const SettingsPage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) =>
                            FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
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

  List<Map<String, dynamic>> markerDetails = [];

  Future<void> fetchMarkerDetails() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('markers').get();
    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      markerDetails.add(data);
    }
  }

  void filterByCity(String selectedCity) async {
    filteredMarkers.clear();

    // Fetch the coordinates of the selected city using geocoding
    List<geo.Location> cityCoordinates =
        await geo.locationFromAddress(selectedCity);

    // Define the radius (in meters) within which markers should be displayed
    double maxRadius = 5000; // 5 kilometers

    print('Selected City: $selectedCity');
    print('City Coordinates: ${cityCoordinates[0]}');

    for (var markerData in markerDetails) {
      double markerLatitude = markerData['latitude'];
      double markerLongitude = markerData['longitude'];

      // Calculate distance between city and marker using Haversine formula
      double distance = calculateHaversineDistance(
        cityCoordinates[0].latitude,
        cityCoordinates[0].longitude,
        markerLatitude,
        markerLongitude,
      );

      print('Marker Coordinates: $markerLatitude, $markerLongitude');

      if (distance <= maxRadius) {
        Marker marker = Marker(
          markerId: MarkerId(
              '$markerLatitude,$markerLongitude'), // Use lat/lng as the marker ID
          position: LatLng(markerLatitude, markerLongitude),
          infoWindow: InfoWindow(title: markerData['foodName']),
        );

        filteredMarkers.add(marker);
      }
    }

    setState(() {
      markers = filteredMarkers.toList();
    });
  }

  void showGPSUbloxModule(BuildContext context) async {
    DatabaseReference gpsDataRef =
        // ignore: deprecated_member_use
        FirebaseDatabase.instance.reference().child('gpsData');

    DatabaseEvent event = await gpsDataRef.once();
    DataSnapshot dataSnapshot = event.snapshot;

    if (dataSnapshot.value != null) {
      Map<Object?, Object?> data = dataSnapshot.value as Map<Object?, Object?>;
      double? latitude = data['latitude'] as double?;
      double? longitude = data['longitude'] as double?;

      String address = 'Loading address...';

      if (latitude != null && longitude != null) {
        try {
          List<Placemark> placemarks =
              await placemarkFromCoordinates(latitude, longitude);
          if (placemarks.isNotEmpty) {
            Placemark placemark = placemarks.first;
            address =
                '${placemark.thoroughfare ?? ''}, ${placemark.locality ?? ''}, ${placemark.administrativeArea ?? ''}';
          }
        } catch (e) {
          print('Error retrieving address: $e');
        }
      }

      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GPS Ublox Module Search',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Address',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    address,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        child: const Text('Close'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }
}
