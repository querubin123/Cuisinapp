import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataLogsPage extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String eateryName;
  final Function(double latitude, double longitude, String eateryName)
      onEateryNameTap;

  const DataLogsPage({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.eateryName,
    required this.onEateryNameTap,
  });

  @override
  // ignore: library_private_types_in_public_api
  _DataLogsPageState createState() => _DataLogsPageState();
}

class _DataLogsPageState extends State<DataLogsPage> {
  List<Map<String, dynamic>> selectedEateryData = [];

  @override
  void initState() {
    super.initState();
    _loadSelectedEateryData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 0.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Data Logs',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  onPressed: () {
                    if (selectedEateryData.isNotEmpty) {
                      _showDeleteConfirmationDialog();
                    } else {
                      _showEmptyLogToast();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height,
              ),
              child: ListView.builder(
                itemCount: selectedEateryData.length,
                itemBuilder: (context, index) {
                  final eateryData = selectedEateryData[index];
                  final latitude = eateryData['latitude'];
                  final longitude = eateryData['longitude'];
                  final eateryName = eateryData['eateryName'];

                  return Dismissible(
                    key: UniqueKey(),
                    onDismissed: (_) {
                      setState(() {
                        selectedEateryData.removeAt(index);
                      });
                      _saveSelectedEateryData();
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    child: FutureBuilder<String>(
                      future: _getAddressFromLatLng(latitude, longitude),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final address = snapshot.data!;
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 3.0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.fastfood,
                                      size: 24.0,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 8.0),
                                    Text(
                                      eateryName,
                                      style: const TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  'Address: $address',
                                  style: const TextStyle(fontSize: 16.0),
                                ),
                              ],
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return const Text('Error retrieving address');
                        } else {
                          return const Text('Loading address');
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSelectedEateryData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? storedData = prefs.getStringList('selectedEateryData');

    if (storedData != null) {
      setState(() {
        selectedEateryData = storedData
            .map((data) => Map<String, dynamic>.from(jsonDecode(data)))
            .toList();
      });
    }
  }

  Future<String> _getAddressFromLatLng(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        String address = placemark.street ?? '';
        if (placemark.subLocality != null) {
          address += ', ${placemark.subLocality!}';
        }
        if (placemark.locality != null) {
          address += ', ${placemark.locality!}';
        }
        if (placemark.administrativeArea != null) {
          address += ', ${placemark.administrativeArea!}';
        }
        if (placemark.postalCode != null) {
          address += ', ${placemark.postalCode!}';
        }
        if (placemark.country != null) {
          address += ', ${placemark.country!}';
        }
        return address;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error retrieving address: $e');
    }
    return 'Address not found';
  }

  Future<void> _saveSelectedEateryData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> encodedData =
        selectedEateryData.map((data) => jsonEncode(data)).toList();

    await prefs.setStringList('selectedEateryData', encodedData);
  }

  void _deleteAllLogs() async {
    if (selectedEateryData.isEmpty) {
      _showEmptyLogToast();
      return;
    }

    setState(() {
      selectedEateryData.clear();
    });
    await _saveSelectedEateryData();

    Fluttertoast.showToast(
      msg: 'All logs deleted successfully.',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black.withOpacity(0.8),
      textColor: Colors.white,
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete All Logs',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to delete all logs?',
                style: TextStyle(fontSize: 16.0),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.black54,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 10.0),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _deleteAllLogs();
                    },
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.red),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                ],
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
        );
      },
    );
  }

  void _showEmptyLogToast() {
    Fluttertoast.showToast(
      msg: 'Log is empty.',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black.withOpacity(0.8),
      textColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _saveSelectedEateryData(); // Save the data when the widget is disposed
    super.dispose();
  }
}
