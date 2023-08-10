// ignore: file_names
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:page_transition/page_transition.dart';
import 'EateryOwnerAboutPage.dart';
import 'EateryOwnerAccountSettingsPage.dart';
import 'EateryOwnerMapPage.dart';
import 'EateryOwnerWeatherPage.dart';
import 'EaterySignInPage.dart';
import 'UserReviewsPage.dart'; // Import the UserReviewsPage widget

class EateryOwnerSettingsPage extends StatefulWidget {
  const EateryOwnerSettingsPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EateryOwnerSettingsPageState createState() =>
      _EateryOwnerSettingsPageState();
}

class _EateryOwnerSettingsPageState extends State<EateryOwnerSettingsPage> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  builder: (context) => const EateryOwnerAccountSettingsPage(),
                ),
              );
            },
            isFirstItem: true,
          ),
          _buildSettingsItem(
            Icons.info,
            'About',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EateryOwnerAboutPage(),
                ),
              );
            },
          ),
          _buildSettingsItem(
            Icons.star,
            'User Reviews',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserReviewsPage(),
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
                    child: EateryOwnerMapPage(
                      address: '',
                      category: '',
                      description: '',
                      eateryName: '',
                      foodName: '',
                      imageUrls: const [],
                      price: 0.0,
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
                color: Colors.yellow,
              ),
              padding: const EdgeInsets.all(7.0),
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.fade,
                      child: EateryOwnerWeatherPage(),
                    ),
                  );
                },
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
                  PageTransition(
                    type: PageTransitionType.fade,
                    child: const EateryOwnerSettingsPage(),
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

  Widget _buildSettingsItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isFirstItem = false,
    Widget? trailingWidget,
  }) {
    if (title == 'Dark Mode' && trailingWidget is Switch) {
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
          trailing: trailingWidget,
          onTap: null, // Disable the onTap callback for ListTile
        ),
      );
    } else {
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
          tileColor: Colors.transparent, // Set the tileColor to transparent
        ),
      );
    }
  }

  void _handleLogout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (BuildContext context) => EaterySignInPage(),
      ),
      (Route<dynamic> route) => false,
    );

    Fluttertoast.showToast(
      msg: 'Logged out successfully',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }
}

class DataLogsPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const DataLogsPage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Logs'),
      ),
      body: Container(
          // Add your data logs content here
          ),
    );
  }
}
