import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'login_page.dart';
// Assume you have a LoginPage widget

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _profileInfoKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  String? _mobileNumber;
  bool _isLoading = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Load user data from Firebase
  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('intel') // Ensure this is the correct Firestore path
          .doc(user.uid)
          .get();
      Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;

      setState(() {
        _firstNameController.text = userData['firstName'] ?? '';
        _lastNameController.text = userData['lastName'] ?? '';
        _mobileNumber = userData['Mobile'];
      });
    }
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

  // Update profile in Firestore
  Future<void> _updateProfile() async {
    if (_profileInfoKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        User? user = _auth.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('intel') // Ensure this is the correct Firestore path
              .doc(user.uid)
              .update({
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'Mobile': _mobileNumber,
          });

          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.white],
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
                  constraints: const BoxConstraints(maxWidth: 450),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.5)),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Edit Profile",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 30),
                            _buildProfileForm(),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: _updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black54,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text("Update Profile"),
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

  Widget _buildProfileForm() {
    return Form(
      key: _profileInfoKey,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(8.0), // Add margin to the first input
            child: _buildTextField(
              "First Name",
              _firstNameController,
              validator: (value) => _validateName(value, "First Name"),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.all(8.0), // Add margin to the second input
            child: _buildTextField(
              "Last Name",
              _lastNameController,
              validator: (value) => _validateName(value, "Last Name"),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.all(8.0), // Add margin to the phone input
            child: IntlPhoneField(
              decoration: InputDecoration(
                labelText: "Mobile Number",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              initialCountryCode: 'IN',
              initialValue: _mobileNumber ?? '', // Handle null values
              onChanged: (phone) {
                _mobileNumber = phone.completeNumber;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscureText = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      validator: validator,
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
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final angle = animation.value * 2 * pi + (i * pi / 2);
      final dx = centerX + 100 * cos(angle);
      final dy = centerY + 100 * sin(angle);
      canvas.drawCircle(Offset(dx, dy), 10, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
