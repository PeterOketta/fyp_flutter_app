import 'package:flutter/material.dart';
import 'HomePage.dart';
import 'EnrollmentPage.dart';
import 'VerificationPage.dart';
import 'WelcomePage.dart';
import 'AccountSetupPage.dart';
import 'Re_enrollment.dart';
import 'BluetoothPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        // '/create-account': (context) => HomePage(),
        '/create-account': (context) => AccountSetupPage(),
        '/verification': (context) => AuthenticationPage(),
        '/enroll': (context) => EnrollmentScreen(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}
