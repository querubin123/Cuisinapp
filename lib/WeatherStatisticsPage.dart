// ignore: file_names
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class WeatherStatisticsPage extends StatefulWidget {
  final Map<String, dynamic> weatherData;

  const WeatherStatisticsPage({super.key, required this.weatherData});

  @override
  // ignore: library_private_types_in_public_api
  _WeatherStatisticsPageState createState() => _WeatherStatisticsPageState();
}

class _WeatherStatisticsPageState extends State<WeatherStatisticsPage> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    initializeNotifications();
  }

  Future<void> initializeNotifications() async {
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('mipmap/ic_launcher');
    var initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(String title, String body) async {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    var platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  String getTemperatureAssumption(double temperature) {
    if (temperature > 25) {
      return "It's a hot day. It's a good time to enjoy some ice cream!";
    } else if (temperature < 20) {
      return "It's a cold day. Warm up with a hot bowl of soup!";
    } else {
      return "The temperature is moderate. Enjoy a balanced meal.";
    }
  }

  String getHumidityAssumption(int humidity) {
    if (humidity > 70) {
      return "High humidity today. Stay hydrated and enjoy some refreshing fruits!";
    } else if (humidity < 30) {
      return "Low humidity today. Savor some moisturizing foods like avocados or nuts!";
    } else {
      return "Humidity levels are comfortable today. Choose your favorite meal.";
    }
  }

  String getWindSpeedAssumption(double windSpeed) {
    if (windSpeed > 30) {
      return "Strong winds today. Opt for warm and hearty dishes like pasta or curry!";
    } else if (windSpeed < 10) {
      return "Light breeze today. It's a great time for a picnic with sandwiches and fruits!";
    } else {
      return "Moderate wind conditions. Enjoy your preferred cuisine.";
    }
  }

  String getCloudinessAssumption(int cloudiness) {
    if (cloudiness > 70) {
      return "Mostly cloudy today. Indulge in comfort foods like pizza or burgers!";
    } else if (cloudiness < 30) {
      return "Clear skies today. Grill some BBQ or have a refreshing salad!";
    } else {
      return "Partly cloudy conditions. Relish your favorite dishes.";
    }
  }

  @override
  Widget build(BuildContext context) {
    var temperature = widget.weatherData['current']['temp_c'];
    var humidity = widget.weatherData['current']['humidity'];
    var windSpeed = widget.weatherData['current']['wind_kph'];
    var cloudiness = widget.weatherData['current']['cloud'];

    String overallAssumption =
        "${getTemperatureAssumption(temperature)}\n${getHumidityAssumption(humidity)}\n${getWindSpeedAssumption(windSpeed)}\n${getCloudinessAssumption(cloudiness)}";

    showNotification('Weather Update', overallAssumption);

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              WeatherStatisticCard(
                title: 'Temperature',
                value: '$temperature°C',
                iconData: Icons.thermostat_rounded,
                cardColor: Colors.orange,
                margin: const EdgeInsets.fromLTRB(20, 70, 20, 10),
                assumption: getTemperatureAssumption(temperature),
              ),
              WeatherStatisticCard(
                title: 'Humidity',
                value: '$humidity%',
                iconData: Icons.water_drop_rounded,
                cardColor: Colors.blue,
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                assumption: getHumidityAssumption(humidity),
              ),
              WeatherStatisticCard(
                title: 'Wind Speed',
                value: '$windSpeed km/h',
                iconData: Icons.air,
                cardColor: Colors.green,
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                assumption: getWindSpeedAssumption(windSpeed),
              ),
              WeatherStatisticCard(
                title: 'Cloudiness',
                value: '$cloudiness%',
                iconData: Icons.cloud_rounded,
                cardColor: Colors.grey,
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                assumption: getCloudinessAssumption(cloudiness),
              ),
              const SizedBox(height: 20),
              WeatherBarChart(weatherData: widget.weatherData),
            ],
          ),
        ),
      ),
    );
  }
}

class WeatherStatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData iconData;
  final Color cardColor;
  final EdgeInsets margin;
  final String assumption;

  const WeatherStatisticCard({
    super.key,
    required this.title,
    required this.value,
    required this.iconData,
    required this.cardColor,
    required this.margin,
    required this.assumption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: margin,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                iconData,
                color: Colors.white,
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            assumption,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherBarChart extends StatelessWidget {
  final Map<String, dynamic> weatherData;

  const WeatherBarChart({super.key, required this.weatherData});

  List<charts.Series<WeatherMetric, String>> _createSeries() {
    final List<WeatherMetric> dataPoints = [
      WeatherMetric('Temperature', weatherData['current']['temp_c']),
      WeatherMetric('Humidity', weatherData['current']['humidity']),
      WeatherMetric('Wind Speed', weatherData['current']['wind_kph']),
      WeatherMetric('Cloudiness', weatherData['current']['cloud']),
    ];

    return [
      charts.Series<WeatherMetric, String>(
        id: 'WeatherMetrics',
        domainFn: (WeatherMetric metric, _) => metric.metric,
        measureFn: (WeatherMetric metric, _) => metric.value,
        data: dataPoints,
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Weather Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: charts.BarChart(
              _createSeries(),
              animate: true,
              vertical: false,
              domainAxis: const charts.OrdinalAxisSpec(
                renderSpec: charts.NoneRenderSpec(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherMetric {
  final String metric;
  final dynamic value;

  WeatherMetric(this.metric, this.value);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Statistics',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const WeatherStatisticsPage(
        weatherData: {
          'current': {
            'temp_c': 26,
            'humidity': 80,
            'wind_kph': 15,
            'cloud': 50,
          },
        },
      ),
    );
  }
}
