// ignore: file_names
import 'package:flutter/material.dart';
import 'package:cuisinapp/HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesPage extends StatefulWidget {
  static List<String> favoritePlaces = [];

  const FavoritesPage({Key? key}) : super(key: key);

  static void addFavoritePlace(String place) {
    favoritePlaces.add(place);
    saveFavoritePlaces(); // Save the updated favorite places
  }

  static void addFavoritePlaces(List<String> places) {
    favoritePlaces.addAll(places);
    saveFavoritePlaces(); // Save the updated favorite places
  }

  static Future<void> saveFavoritePlaces() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoritePlaces', favoritePlaces);
  }

  static Future<void> loadFavoritePlaces() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    favoritePlaces = prefs.getStringList('favoritePlaces') ?? [];
  }

  void navigateToHomePage(BuildContext context, String address, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(
          address: address,
          description: '',
          eateryName: name,
          imageUrls: const [],
          type: '',
          submittedPrice: 0.0,
          category: '',
          foodName: '',
        ),
      ),
    );
  }

  @override
  // ignore: library_private_types_in_public_api
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    FavoritesPage.loadFavoritePlaces(); // Load the saved favorite places
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FavoritesPage
        .loadFavoritePlaces(); // Reload the favorite places when dependencies change
  }

  void deleteCard(int index) {
    setState(() {
      if (index >= 0 && index < FavoritesPage.favoritePlaces.length) {
        FavoritesPage.favoritePlaces.removeAt(index);
        FavoritesPage.saveFavoritePlaces(); // Save the updated favorite places
      }
    });
  }

  Widget _buildPlaceDetailsCard(String name, String address) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          name,
          style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          address,
          style: const TextStyle(fontSize: 16.0),
        ),
        onTap: () {
          widget.navigateToHomePage(context, address, name);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: FavoritesPage.loadFavoritePlaces(), // Load the favorite places
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (FavoritesPage.favoritePlaces.isEmpty) {
              return const Center(
                child: Text(
                  'No favorite places',
                  style: TextStyle(fontSize: 18.0),
                ),
              );
            } else {
              return ListView.builder(
                itemCount: FavoritesPage.favoritePlaces.length,
                itemBuilder: (context, index) {
                  final place = FavoritesPage.favoritePlaces[index];
                  final List<String> placeDetails = place.split(';');
                  final name = placeDetails[0];
                  final address = placeDetails[1];

                  return Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.horizontal,
                    onDismissed: (direction) {
                      deleteCard(index);
                    },
                    background: Container(
                      color: Colors.red,
                      child: const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 16.0),
                          child: Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    secondaryBackground: Container(
                      color: Colors.red,
                      child: const Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: 16.0),
                          child: Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    child: _buildPlaceDetailsCard(name, address),
                  );
                },
              );
            }
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
