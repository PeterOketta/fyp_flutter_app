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
// import 'screens/homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECG Biometrics App',
      theme: ThemeData.dark(),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/bluetooth-pairing': (context) => const FlutterBlueApp(),
        '/enrollment': (context) => const EnrollmentScreen(),
        '/re-enroll': (context) => const ReEnrollmentPage(),
        // '/create-account': (context) => HomePage(),
        '/create-account': (context) => const AccountSetupPage(),
        '/verification': (context) => const AuthenticationPage(),
        '/enroll': (context) => const EnrollmentScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
