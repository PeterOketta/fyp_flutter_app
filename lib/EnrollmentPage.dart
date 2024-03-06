import 'package:flutter/material.dart';

class EnrollmentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Your app's title or desired content for the app bar
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            Text(
              'Create your ECG Profile',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 20.0),

            // Instructions and Image
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Image.asset('assets/images/sensor_placement.png'), // Replace with your sensor placement image
                // SizedBox(width: 20.0),
                Text(
                  'Place the sensor on your garment as shown.',
                  style: TextStyle(fontSize: 16.0),
                ),
              ],
            ),

            SizedBox(height: 20.0),
            // Bluetooth Connection Status
            Text(
              'Bluetooth: Connected', // Update dynamically based on connection state
              style: TextStyle(fontSize: 16.0),
            ),

            SizedBox(height: 20.0),
            // Start Enrollment Button
            ElevatedButton(
              onPressed: () {
                // Start ECG data capture process
                // ... (e.g., call function to capture data)
                Navigator.pushNamed(context, '/profile', arguments: {'profileName': 'Mike'});

              },
              child: Text('Start Enrollment'),
            ),
          ],
        ),
      ),
    );
  }
}
