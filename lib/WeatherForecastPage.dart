// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';
import 'HomePage.dart';
import 'SettingsPage.dart';
import 'WeatherStatisticsPage.dart';
import 'package:weather_icons/weather_icons.dart';

class WeatherForecastPage extends StatefulWidget {
  const WeatherForecastPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WeatherForecastPageState createState() => _WeatherForecastPageState();
}

class _WeatherForecastPageState extends State<WeatherForecastPage> {
  String apiKey =
      '301aea2899354ba3bb1123229233105'; // Replace with your WeatherAPI API key

  Future<dynamic> fetchWeatherData() async {
    var url =
        'https://api.weatherapi.com/v1/current.json?key=$apiKey&q=auto:ip';
    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var weatherData = jsonDecode(response.body);
      return weatherData;
    } else {
      throw Exception('Failed to fetch weather data. Please try again later.');
    }
  }

  IconData getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
        return WeatherIcons.day_sunny;
      case 'clear':
        return WeatherIcons.night_clear;
      case 'partly cloudy':
        return WeatherIcons.day_cloudy;
      case 'cloudy':
        return WeatherIcons.cloudy;
      case 'rainy':
        return WeatherIcons.rain;
      case 'thunderstorm':
        return WeatherIcons.thunderstorm;
      case 'snowy':
        return WeatherIcons.snow;
      default:
        return WeatherIcons
            .thermometer; // Use thermometer icon for unknown conditions
    }
  }

  Widget buildWeatherDataContainer(
      String title, IconData iconData, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            iconData,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshWeatherData() async {
    setState(() {
      // Reset weather data
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF61A4F1),
              Color(0xFF478DE0),
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _refreshWeatherData,
          child: FutureBuilder(
            future: fetchWeatherData(),
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                );
              } else if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Failed to fetch weather data',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                );
              } else {
                var temperature = snapshot.data['current']['temp_c'];
                var humidity = snapshot.data['current']['humidity'];
                var windSpeed = snapshot.data['current']['wind_kph'];
                var cloudiness = snapshot.data['current']['cloud'];
                var condition = snapshot.data['current']['condition']['text'];

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Weather Forecast',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      buildWeatherDataContainer(
                        'Temperature',
                        getWeatherIcon('temperature'),
                        '$temperature°C',
                      ),
                      const SizedBox(height: 10),
                      buildWeatherDataContainer(
                        'Humidity',
                        WeatherIcons.humidity,
                        '$humidity%',
                      ),
                      const SizedBox(height: 10),
                      buildWeatherDataContainer(
                        'Wind Speed',
                        WeatherIcons.strong_wind,
                        '$windSpeed km/h',
                      ),
                      const SizedBox(height: 10),
                      buildWeatherDataContainer(
                        'Cloudiness',
                        WeatherIcons.cloud,
                        '$cloudiness%',
                      ),
                      const SizedBox(height: 10),
                      buildWeatherDataContainer(
                        'Condition',
                        getWeatherIcon(condition.toLowerCase()),
                        condition,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageTransition(
                              type: PageTransitionType.fade,
                              child: WeatherStatisticsPage(
                                weatherData: snapshot.data,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: const Color(0xFFCDE990),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'View Statistics',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF478DE0),
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  PageTransition(
                    type: PageTransitionType.fade,
                    child: HomePage(
                      address: '',
                      category: '',
                      description: '',
                      eateryName: '',
                      foodName: '',
                      imageUrls: const [],
                      submittedPrice: 0.0,
                      type: '',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.home, size: 28.0, color: Colors.white),
            ),
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFCDE990),
              ),
              padding: const EdgeInsets.all(7.0),
              child: IconButton(
                onPressed: () {
                  // Refresh weather data
                  _refreshWeatherData();
                },
                icon: const Icon(
                  Icons.wb_cloudy,
                  color: Colors.white,
                  size: 30.0,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.fade,
                    child: const SettingsPage(),
                  ),
                );
              },
              icon: const Icon(Icons.settings, size: 28.0, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
