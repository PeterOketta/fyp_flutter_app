import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  // Allow optional parameter
  final String? profileName;

  const ProfileScreen({Key? key, this.profileName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome, ${profileName ?? 'User'}!", // Use 'User' if profileName is null
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                // Handle the "Record" button press
                // ... (e.g., navigate to recording screen)
              },
              child: Text('Record'),
            ),
          ],
        ),
      ),
    );
  }
}
