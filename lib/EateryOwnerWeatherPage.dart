import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'EateryOwnerMapPage.dart';
import 'EateryOwnerSettingsPage.dart';

class EateryOwnerWeatherPage extends StatefulWidget {
  @override
  _EateryOwnerWeatherPageState createState() => _EateryOwnerWeatherPageState();
}

class _EateryOwnerWeatherPageState extends State<EateryOwnerWeatherPage> {
  late DatabaseReference _weatherRef;
  double _temperature = 0.0;
  double _humidity = 0.0;
  double _altitude = 0.0;
  double _pressure = 0.0;
  String _rainIntensity = ''; // Updated variable name
  String _insight = '';

  bool _isLoading = true; // Track whether data is loading or not

  @override
  void initState() {
    super.initState();
    initializeFirebase();
  }

  void initializeFirebase() async {
    await Firebase.initializeApp();
    _weatherRef = FirebaseDatabase.instance.ref().child('weatherdata');
    _weatherRef.onValue.listen((event) {
      if (!mounted) return; // Check if the widget is still mounted
      if (event.snapshot.value != null) {
        var weatherData = event.snapshot.value;
        print('Raw Weather Data: $weatherData');
        print('Weather Data Type: ${weatherData.runtimeType}');
        if (weatherData is Map) {
          var weatherDataMap = weatherData.cast<String, dynamic>();
          setState(() {
            _temperature = weatherDataMap['temperature']?.toDouble() ?? 0.0;
            _humidity = weatherDataMap['humidity']?.toDouble() ?? 0.0;
            _altitude = weatherDataMap['altitude']?.toDouble() ?? 0.0;
            _pressure = weatherDataMap['pressure']?.toDouble() ?? 0.0;
            _rainIntensity = weatherDataMap['rainIntensity']?.toString() ??
                ''; // Updated key
            _insight = generateInsight();
            _insight = generateInsight();
            _isLoading = false; // Data has been loaded
          });
        } else {
          print('Invalid weather data format');
        }
      } else {
        print('No weather data available');
      }
    });
  }

  String generateInsight() {
    if (_temperature > 0 && _humidity > 0) {
      if (_temperature > 30 && _humidity > 80) {
        return 'Mainit at maalinsangan ang panahon ngayon. Subukang magluto ng Pancit Palabok o Pancit Malabon!';
      } else if (_temperature < 20) {
        return 'Malamig ang panahon ngayon. Pampainit ng katawan ang Sinigang o Bulalo!';
      } else {
        return 'Tangkilikin ang panahon kasama ang masarap na lutong Filipino!';
      }
    }
    return '';
  }

  void navigateToMapPage() {
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
          imageUrls: [],
          price: 0.0,
          type: '',
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  void navigateToWeatherPage() {
    // Do something when weather icon is tapped
  }

  void navigateToSettingsPage() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EateryOwnerSettingsPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('temperature: $_temperature');
    print('humidity: $_humidity');
    print('altitude: $_altitude');
    print('pressure: $_pressure');
    print('rain: $_rainIntensity');
    print('insight: $_insight');

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.blue.shade400],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Today\'s Weather',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    // Add animated sun icon
                    AnimatedContainer(
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [Colors.orange, Colors.amber],
                          center: Alignment.center,
                          radius: 0.5,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.wb_sunny,
                        size: 72,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildWeatherDataContainer(
                      Icons.thermostat_outlined,
                      'Temperature',
                      '$_temperature°C',
                    ),
                    _buildWeatherDataContainer(
                      Icons.water_outlined,
                      'Humidity',
                      '$_humidity%',
                    ),
                    _buildWeatherDataContainer(
                      Icons.height_outlined,
                      'Altitude',
                      '$_altitude m',
                    ),
                    _buildWeatherDataContainer(
                      Icons.trending_up_outlined,
                      'Pressure',
                      '$_pressure hPa',
                    ),
                    _buildWeatherDataContainer(
                      Icons.cloud_outlined,
                      'Rain Intensity',
                      _rainIntensity,
                    ),
                    SizedBox(height: 16),
                    // Add animated insight text with fade transition
                    AnimatedOpacity(
                      duration: Duration(milliseconds: 500),
                      opacity: _insight.isNotEmpty ? 1.0 : 0.0,
                      child: Text(
                        _insight,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blue,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: navigateToMapPage,
              icon: const Icon(Icons.home, size: 23.0, color: Colors.white),
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.yellow,
              ),
              padding: EdgeInsets.all(7.0),
              child: IconButton(
                onPressed: navigateToWeatherPage,
                icon: Icon(
                  Icons.wb_sunny,
                  color: Colors.white,
                  size: 30.0,
                ),
              ),
            ),
            IconButton(
              onPressed: navigateToSettingsPage,
              icon: Icon(Icons.settings, size: 23.0, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDataContainer(IconData icon, String label, String value) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade300, Colors.blue.shade600],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
