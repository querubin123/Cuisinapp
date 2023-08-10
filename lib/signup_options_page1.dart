import 'package:flutter/material.dart';
import 'package:cuisinapp/EaterySignInPage.dart';
import 'package:flutter/services.dart';
import 'EateryOwnerMapPage.dart';
import 'EateryOwnerSignUpPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpOptionsPage1 extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const SignUpOptionsPage1({Key? key});

  Future<bool> checkUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userData =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Check if the user document exists in Firestore
      final snapshot = await userData.get();
      return snapshot.exists;
    }

    return false;
  }

  Future<bool> checkEateryOwnerData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final eateryOwnerData =
          FirebaseFirestore.instance.collection('eateryOwners').doc(user.uid);

      // Check if the eatery owner document exists in Firestore
      final snapshot = await eateryOwnerData.get();
      return snapshot.exists;
    }

    return false;
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 8.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.exit_to_app,
                color: Colors.blue,
                size: 48.0,
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Confirm Exit',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Are you sure you want to exit?',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 18.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      backgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text('No'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                      SystemNavigator.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text('Yes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await _showExitConfirmationDialog(context);
        return shouldExit;
      },
      child: FutureBuilder<bool>(
        future: checkUserData(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            // Loading state
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.0, // Adjust the stroke width here
              ),
            );
          }

          // final bool hasUserData = userSnapshot.data ?? false;

          return FutureBuilder<bool>(
            future: checkEateryOwnerData(),
            builder: (context, eateryOwnerSnapshot) {
              if (eateryOwnerSnapshot.connectionState ==
                  ConnectionState.waiting) {
                // Loading state
                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0, // Adjust the stroke width here
                  ),
                );
              }

              final bool hasEateryOwnerData = eateryOwnerSnapshot.data ?? false;

              return Scaffold(
                extendBodyBehindAppBar: true,
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
                body: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/BG1.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                    Positioned(
                      top: 80,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Find Places',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFD4D4),
                                height: 1,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Where You Can',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFD4D4),
                                height: 1,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Get Satisfied To',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFD4D4),
                                height: 1,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'To Filipino',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFD4D4),
                                height: 1,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Cuisine',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFD4D4),
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 32,
                      left: 32,
                      right: 32,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EateryOwnerSignUpPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFFCDE990).withOpacity(1),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              side: BorderSide.none,
                              minimumSize: const Size(double.infinity, 0),
                            ),
                            child: const Text(
                              'SIGN UP AS EATERY OWNER',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: hasEateryOwnerData
                                ? () {
                                    // Eatery owner has data, navigate to EateryOwnerHomePage
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EateryOwnerMapPage(
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
                                  }
                                : () {
                                    // Eatery owner has no data or not signed in, navigate to EaterySignInPage
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EaterySignInPage(),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(
                                    color: Colors.white, width: 2),
                              ),
                              minimumSize: const Size(double.infinity, 0),
                            ),
                            child: const Text(
                              'SIGN IN AS EATERY OWNER',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
