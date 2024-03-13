import 'package:flutter/material.dart';
import 'HomePage.dart';
import 'EnrollmentPage.dart';
import 'VerificationPage.dart';
import 'WelcomePage.dart';
import 'AccountSetupPage.dart';
import 'Re_enrollment.dart';
import 'BluetoothPage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECG Biometrics App',
      theme: ThemeData.dark(),
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomeScreen(),
        '/bluetooth-pairing': (context) => FlutterBlueApp(),
        '/enrollment': (context) => EnrollmentScreen(),
        '/re-enroll': (context) => ReEnrollmentPage(),
        '/create-account': (context) => AccountSetupPage(),
        '/verification': (context) => AuthenticationPage(),
        '/enroll': (context) => EnrollmentScreen(),
        '/profile': (context) => ProfileScreen(),

      },
    );
  }
}

