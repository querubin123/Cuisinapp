// ignore: file_names
import 'package:flutter/material.dart';
import 'HomePage.dart';
import 'package:page_transition/page_transition.dart';
import 'package:lottie/lottie.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'SettingsPage.dart';
import 'WeatherForecastPage.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  double? _pagePosition = 0.0;
  bool _showButton = false;

  final List<String> _weatherTexts = [
    'Did you know? Weather is the state of the atmosphere, describing the conditions regarding temperature, air pressure, wind, humidity, and precipitation.',
    'Fun Fact: Lightning can reach incredibly high temperatures, with some bolts reaching temperatures hotter than the surface of the sun.',
    'Trivia: The size of raindrops can vary, but on average, raindrops are about 1 to 2 millimeters in diameter. However, larger raindrops can reach sizes of up to 6 millimeters or more during heavy downpours.',
    'GPS technology is used in weather forecasting. By measuring the total electron content in the atmosphere, GPS receivers help gather data for predicting and monitoring weather conditions.',
    'Welcome to Cuisinapp Weather Station.',
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _pagePosition = _pageController.page;
        _showButton = _currentPageIndex == _weatherTexts.length - 1;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleButtonPress() {
    // Add your code to show the weather in the user's area

    // Navigate to the weather forecast page with a fade transition
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.fade,
        child: const WeatherForecastPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      home: Scaffold(
        backgroundColor: Colors.white,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanUpdate: (details) {
            if (details.delta.dx > 0) {
              // Swiped from left to right (previous slide)
              if (_currentPageIndex > 0) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            } else if (details.delta.dx < 0) {
              // Swiped from right to left (next slide)
              if (_currentPageIndex < _weatherTexts.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            }
          },
          child: Container(
            color: Colors
                .blueGrey[100], // Replace with your desired background color
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _weatherTexts.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPageIndex = index;
                        _showButton =
                            _currentPageIndex == _weatherTexts.length - 1;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(top: 50),
                        child: LottieBuilder.asset(
                          'assets/weather${index + 1}.json',
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Text(
                    _weatherTexts[_currentPageIndex],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontFamily: 'Calibri',
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: DotsIndicator(
                    dotsCount: _weatherTexts.length,
                    position: (_pagePosition ?? 0.0).toInt(),
                    decorator: DotsDecorator(
                      activeColor: Colors.blue,
                      color: Colors.grey,
                      size: const Size.square(9.0),
                      activeSize: const Size(18.0, 9.0),
                      activeShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                  ),
                ),
                if (_showButton)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _handleButtonPress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                        ),
                        child: const Text(
                          'See Full Forecast',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
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
                icon: const Icon(Icons.home, size: 23.0),
              ),
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFCDE990),
                ),
                padding: const EdgeInsets.all(7.0),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.fade,
                        child: const WeatherPage(),
                      ),
                    );
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
                icon: const Icon(Icons.settings, size: 23.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
