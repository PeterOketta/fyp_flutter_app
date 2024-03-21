import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  // Allow optional parameter
  final String? profileName;

  const ProfileScreen({super.key, this.profileName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome", 
              style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            Image.asset(
              'assets/profile_pic.png', 
              width: 250, 
              height: 250, 
            ), 
            const SizedBox(height: 20.0),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                // Handle the "Record" button press
                // ... (e.g., navigate to recording screen)
              },
              child: const Text('Record'),
            ),
          ],
        ),
      ),
    );
  }
}
