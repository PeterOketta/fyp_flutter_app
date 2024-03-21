import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container( // Wrap everything in a container
        padding: const EdgeInsets.all(25.0), // Add padding around elements 
        child: Center( 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,  
            children: [
              const Text(
                'Welcome to the ECG Biometrics App!',
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.1), // Adjusted spacing
              Image.asset(
                'assets/biometrics image.png',
                 width: 200, // Adjust image width
                 height: 200, // Adjust image height
              ), 
              const SizedBox(height: 15),
              const Text(
                'Secure and convenient authentication using your unique ECG signature.',
                style: TextStyle(fontSize: 16.0),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.08), // Adjusted spacing 
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/bluetooth-pairing');
                },
                child: const Text('Get Started'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
