import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'home_page.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Form keys for validation
  final GlobalKey<FormState> _basicInfoKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _emailSignupKey = GlobalKey<FormState>();

  // Controllers for fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _reenterPasswordController =
      TextEditingController();
  String? _mobileNumber;

  int _currentStep = 0; // Current step in the signup process
  bool _isLoading = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper method to validate names
  String? _validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
      return '$fieldName must contain only alphabets';
    }
    return null;
  }

  // Helper method to validate password
  String? _validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    if (!RegExp(r'[!@#\$&*~]').hasMatch(password)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  // Email signup handler
  // Email signup handler
  Future<void> _signUpWithEmail() async {
    if (_emailSignupKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Update user profile (optional)
        await userCredential.user?.updateDisplayName(
          "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}",
        );

        // Send verification email
        await userCredential.user?.sendEmailVerification();

        // Save user details in Firestore
        await FirebaseFirestore.instance
            .collection('intel')
            .doc(userCredential.user?.uid)
            .set({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'mobile': _mobileNumber,
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Show confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Verification email sent. Please verify your email.")),
        );

        // Navigate to Home Page (or other appropriate screen)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Sign Up",
          style: TextStyle(fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Particle animation
          Positioned.fill(
            child: CustomPaint(
              painter: _InwardParticlePainter(_animationController),
            ),
          ),
          // Center content with glassmorphism effect
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 40, horizontal: 34),
                  constraints: BoxConstraints(maxWidth: 450),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(1)),
                  ),
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Sign Up",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 30),
                            if (_currentStep == 0) _buildBasicInfoForm(),
                            if (_currentStep == 1) _buildEmailSignupForm(),
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (_currentStep > 0)
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _currentStep--;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black54,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text("Back"),
                                  ),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_currentStep == 0) {
                                      if (_basicInfoKey.currentState!
                                          .validate()) {
                                        setState(() {
                                          _currentStep++;
                                        });
                                      }
                                    } else if (_currentStep == 1) {
                                      _signUpWithEmail();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black54,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    _currentStep == 1 ? "Sign Up" : "Next",
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoForm() {
    return Form(
      key: _basicInfoKey,
      child: Column(
        children: [
          _buildTextField("First Name", _firstNameController,
              validator: (value) => _validateName(value, "First Name"),
              paddingTop: 10,
              paddingBottom: 10),
          const SizedBox(height: 16),
          _buildTextField("Last Name", _lastNameController,
              validator: (value) => _validateName(value, "Last Name"),
              paddingBottom: 10),
          const SizedBox(height: 16),
          IntlPhoneField(
            decoration: InputDecoration(
              labelText: "Mobile Number",
              labelStyle: TextStyle(color: Colors.black), // Black label
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide:
                    BorderSide(color: Colors.black, width: 1), // Black border
              ),
            ),
            initialCountryCode: 'IN',
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (phone) {
              _mobileNumber = phone.completeNumber;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSignupForm() {
    return Form(
      key: _emailSignupKey,
      child: Column(
        children: [
          _buildTextField("Email", _emailController,
              validator: (value) => value == null || !value.contains('@')
                  ? 'Enter a valid email'
                  : null),
          const SizedBox(height: 16),
          _buildTextField("Password", _passwordController,
              obscureText: true, validator: _validatePassword),
          const SizedBox(height: 16),
          _buildTextField("Re-enter Password", _reenterPasswordController,
              obscureText: true,
              validator: (value) => value != _passwordController.text
                  ? 'Passwords do not match'
                  : null),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscureText = false,
      String? Function(String?)? validator,
      double paddingTop = 0.0,
      double paddingBottom = 0.0}) {
    return Padding(
      padding: EdgeInsets.only(top: paddingTop, bottom: paddingBottom),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.black), // Black label text
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
                color: Colors.black, width: 1), // Always black border
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
                color: Colors.black, width: 2), // Black border on focus
          ),
        ),
        obscureText: obscureText,
        validator: validator,
      ),
    );
  }
}

class _InwardParticlePainter extends CustomPainter {
  final Animation<double> animation;

  _InwardParticlePainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = size.width / 2 + 60;
    final radius = maxRadius - (animation.value * maxRadius);
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final dx =
          centerX + radius * cos(i * pi / 2); // Corrected angle calculation
      final dy =
          centerY + radius * sin(i * pi / 2); // Corrected angle calculation
      canvas.drawCircle(Offset(dx, dy), 12, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
