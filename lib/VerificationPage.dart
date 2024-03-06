import 'package:flutter/material.dart';

class AuthenticationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Execute authentication model logic (to be implemented)
                Navigator.pushNamed(context, '/profile', arguments: {'profileName': 'Mike'});
              },
              child: Text('Authenticate'),
            ),
            ElevatedButton(
              onPressed: () {

              },
              child: Text('Retry'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/re-enroll');
                // Retry logic (to be implemented)
              },
              child: Text('Re-enroll'),
            ),
          ],
        ),
      ),
    );
  }
}
