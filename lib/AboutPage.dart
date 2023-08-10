// ignore: file_names
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: true,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          constraints: const BoxConstraints(maxWidth: 600.0),
          child: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuisinap',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 24.0),
                Text(
                  'Cuisinap is the ultimate food finder app designed to help you discover new restaurants, explore diverse cuisines, and satisfy your food cravings. With its intuitive interface and comprehensive features, Cuisinap transforms your dining experience into a delightful culinary journey.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 24.0),
                Text(
                  'Discover New Restaurants',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 16.0),
                Text(
                  'Cuisinap provides an extensive database of restaurants in your area, ranging from local hidden gems to popular dining destinations. Explore the vibrant food scene and uncover new culinary treasures with just a few taps.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 24.0),
                Text(
                  'Explore Diverse Cuisines',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 16.0),
                Text(
                  'With Cuisinap, you can embark on a gastronomic adventure by exploring a wide range of cuisines from around the world. Whether you crave authentic Italian pasta, spicy Indian curries, or sushi rolls from Japan, Cuisinap has you covered.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 24.0),
                Text(
                  'Satisfy Your Food Cravings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 16.0),
                Text(
                  'Hungry and not sure what to eat? Cuisinap is here to rescue your taste buds. Simply browse through the app to find delicious dishes that match your cravings. From juicy burgers to mouthwatering pizzas, Cuisinap helps you satisfy your appetite like never before.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 24.0),
                Text(
                  'Discover Local Carinderias',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 16.0),
                Text(
                  'In addition to restaurants, Cuisinap also features local carinderias, offering authentic Filipino dishes. Experience the rich flavors of traditional Filipino cuisine and support local food businesses.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 24.0),
                Text(
                  'User-Friendly Features',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 16.0),
                Text(
                  'Cuisinap offers a range of user-friendly features to enhance your dining experience. Search for restaurants based on your preferences, view detailed menus, ratings, and reviews, and filter results by cuisine, location, and price range. Additionally, save your favorite restaurants for easy access and discover exciting offers and discounts.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 24.0),
                Text(
                  'Your Go-To App for Dining',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 16.0),
                Text(
                  'Whether you are a food enthusiast, a traveler exploring new places, or simply someone looking for a delightful dining experience, Cuisinap is your go-to app. Discover the flavors of the world, indulge in culinary delights, and make informed dining decisions with Cuisinap.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 24.0),
                Text(
                  'Discover Local Carinderias',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 16.0),
                Text(
                  'In addition to restaurants, Cuisinap also features local carinderias, offering authentic Filipino dishes. Experience the rich flavors of traditional Filipino cuisine and support local food businesses.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 24.0),
                Text(
                  'Download Cuisinap Now',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 16.0),
                Text(
                  'Experience the joy of discovering new restaurants and exploring diverse cuisines with Cuisinap. Download the app today and embark on a culinary adventure that will leave your taste buds craving for more.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
