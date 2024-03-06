import 'package:flutter/material.dart';

class AccountSetupPage extends StatefulWidget {
  @override
  _AccountSetupPageState createState() => _AccountSetupPageState();
}

class _AccountSetupPageState extends State<AccountSetupPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Text Editing Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Submission flag (optional)
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Account'),
      ),
      body: SingleChildScrollView( // Make the content scrollable if necessary
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Image (Placeholder)
              // Image.asset('assets/images/ecg_logo.png', height: 150),

              // SizedBox(height: 20.0),

              // Email Text Field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  // Basic email validation
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address.';
                  }
                  if (!RegExp(r"^[a-zA-Z0-9.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z]+$").hasMatch(value)) {
                    return 'Please enter a valid email address.';
                  }
                  return null;
                },
              ),

              SizedBox(height: 20.0),

              // Password Text Field
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  // Basic password validation
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password.';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters.';
                  }
                  return null;
                },
              ),

              SizedBox(height: 20.0),

              // Confirm Password Text Field
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                validator: (value) {
                  // Confirm password match
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password.';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
              ),

              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  // Execute authentication model logic (to be implemented)
                  Navigator.pushNamed(context, '/bluetooth-pairing');
                },
                child: Text('Create Account'),
              ),
              // Create Account Button
              // ElevatedButton(
              //   onPressed: _isSubmitting
              //       ? null
              //       : () {
              //     if (_formKey.currentState!.validate()) {
              //       setState(() {
              //         _isSubmitting = true; // Start submission process
              //       });
              //
              //       // TODO: Implement your account creation logic here (API call, data storage)
              //
              //       setState(() {
              //         _isSubmitting = false; // End submission process
              //       });
              //     }
              //   },
              //   child: _isSubmitting ? CircularProgressIndicator() : Text('Create Account'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
