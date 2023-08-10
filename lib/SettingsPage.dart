// ignore: file_names
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:page_transition/page_transition.dart';
import 'DataLogsPage.dart';
import 'HomePage.dart';
import 'WeatherPage.dart';
import 'AboutPage.dart';
import 'SignInUserPage.dart';
import 'FavoritesPage.dart';
import 'AccountSettingsPage.dart';
// ignore: depend_on_referenced_packages
import 'package:provider/provider.dart';

class DarkThemeProvider with ChangeNotifier {
  bool _isDarkModeEnabled = false;

  bool get isDarkModeEnabled => _isDarkModeEnabled;

  void toggleDarkMode() {
    _isDarkModeEnabled = !_isDarkModeEnabled;
    notifyListeners();
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DarkThemeProvider(),
      child: Consumer<DarkThemeProvider>(
        builder: (context, darkThemeProvider, _) {
          return MaterialApp(
            theme: darkThemeProvider.isDarkModeEnabled
                ? ThemeData.dark()
                : ThemeData.light(),
            home: Scaffold(
              body: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                children: [
                  _buildSettingsItem(
                    Icons.account_circle,
                    'Account Settings',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountSettingsPage(),
                        ),
                      );
                    },
                    isFirstItem: true,
                  ),
                  _buildFavoritesButton(
                    Icons.favorite,
                    'Favorites',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FavoritesPage(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    Icons.info,
                    'About',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AboutPage(),
                        ),
                      );
                    },
                  ),
                  _buildDataLogsButton(
                    Icons.data_usage,
                    ' Data Logs',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DataLogsPage(
                            eateryName: '',
                            longitude: 0.0,
                            latitude: 0.0,
                            onEateryNameTap: (double latitude, double longitude,
                                String eateryName) {},
                          ), // Navigate to DataLogsPage
                        ),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    Icons.exit_to_app,
                    'Logout',
                    () => _handleLogout(context),
                  ),
                ],
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
        },
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    // Simulate logout process
    await Future.delayed(const Duration(seconds: 2));

    // ignore: use_build_context_synchronously
    Navigator.pushAndRemoveUntil(
      context,
      PageTransition(
        type: PageTransitionType.fade,
        child: SignInUserPage(),
      ),
      (route) => false, // Remove all previous routes from the stack
    );
    Fluttertoast.showToast(
      msg: 'Logged out successfully',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  Widget _buildSettingsItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isFirstItem = false,
  }) {
    return Container(
      margin: EdgeInsets.only(top: isFirstItem ? 50.0 : 16.0),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: Icon(icon),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFavoritesButton(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 16.0),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: Icon(icon),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDataLogsButton(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 16.0),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: Icon(icon),
        onTap: onTap,
      ),
    );
  }
}
