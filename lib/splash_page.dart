import 'package:flutter/material.dart';
import 'RegisterOptions.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    navigateToSignUpOptions();
  }

  void navigateToSignUpOptions() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RegisterOptions()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Stack(
                children: [
                  Positioned(
                    left: (constraints.maxWidth - 200) / 2,
                    top: (constraints.maxHeight - 200) / 2,
                    child: Image.asset(
                      'assets/Kusinapplogo.png',
                      width: 200,
                      height: 200,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
