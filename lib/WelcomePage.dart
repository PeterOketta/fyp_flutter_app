import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image.asset('assets/images/ecg_logo.png'), // Replace with your logo image
            // SizedBox(height: 40),
            Text(
              'Welcome to the ECG Biometrics App!',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Secure and convenient authentication using your unique ECG signature.',
              style: TextStyle(fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/create-account');
              },
              child: Text('Get Started'),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/bluetooth-pairing');
              },
              child: Text('I already have an account'),
            ),
          ],
        ),
      ),
    );
  }
}

