import 'package:flutter/material.dart';
import 'dart:ui';
import 'login.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  _SignupState createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  bool obscurePassword = true;
  bool terms = false;
  File? cinImage;
  File? jobCardImage;
  File? profileImage;
  bool isDriver = false;
  bool isLoading = false;

  final ImagePicker picker = ImagePicker();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmpasswordController =
      TextEditingController();
  final TextEditingController _licenseNumberController =
      TextEditingController();
  final TextEditingController _licenseExpiryController =
      TextEditingController();

  // --- LOGIQUE D'IMAGE ---
  Future<void> pickImage(Function(File?) setImage) async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        setImage(File(image.path));
      });
    }
  }

  // --- VALIDATIONS ---
  bool validatename(String fullname) =>
      RegExp(r'^[a-zA-Z\s]{5,25}$').hasMatch(fullname);
  bool validateemail(String email) =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  bool validatephone(String phone) => RegExp(r'^[0-9]{8}$').hasMatch(phone);
  bool validatepassword(String password) =>
      RegExp(r'^[A-Z]+[\w.]{5,}$').hasMatch(password);

  // --- BACKEND (INTÉGRAL) ---
  Future<void> handleSignup() async {
    String fullname = _fullNameController.text;
    String email = _emailController.text;
    String phone = _phoneController.text;
    String password = _passwordController.text;
    String confirmpassword = _confirmpasswordController.text;

    if (!validatename(fullname)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid full name (5-25 characters)'),
        ),
      );
      return;
    } else if (!validateemail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    } else if (!validatephone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number (8 digits)'),
        ),
      );
      return;
    } else if (!validatepassword(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password must start with uppercase and be at least 6 characters',
          ),
        ),
      );
      return;
    } else if (password != confirmpassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    } else if (terms == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept terms and conditions')),
      );
      return;
    }

    if (isDriver) {
      if (cinImage == null ||
          jobCardImage == null ||
          _licenseNumberController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please complete all driver documents and license info',
            ),
          ),
        );
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      Map<String, dynamic> requestBody = {
        'full_name': fullname,
        'email': email,
        'phone': phone,
        'password': password,
        'role': isDriver ? "driver" : "commuter",
      };

      if (isDriver) {
        requestBody['license_number'] = _licenseNumberController.text.trim();
        requestBody['license_expiry'] = _licenseExpiryController.text.trim();
      }

      final response = await http.post(
        Uri.parse('http://10.122.164.121:8000/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Login()),
          );
        }
      } else {
        final error = json.decode(response.body);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error['detail'] ?? 'Signup failed'),
              backgroundColor: Colors.red,
            ),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            const Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'SmartPickup',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Create Account',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const Positioned(
              top: 110,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Join SmartPickup today',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),

            Positioned(
              top: 150,
              left: 0,
              right: 0,
              bottom: 20,
              child: Center(
                child: Card(
                  color: const Color.fromARGB(
                    36,
                    143,
                    143,
                    102,
                  ).withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: screenWidth > 900 ? 500 : screenWidth * 0.9,
                    padding: const EdgeInsets.all(25),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildLabel("Account Type"),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildRoleBtn(
                                  "User",
                                  !isDriver,
                                  () => setState(() => isDriver = false),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildRoleBtn(
                                  "Driver",
                                  isDriver,
                                  () => setState(() => isDriver = true),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 25),
                          _buildLabel("Profile Picture"),
                          const SizedBox(height: 10),
                          _buildProfilePicker(),

                          _buildLabel("Full Name"),
                          _buildTextField(
                            _fullNameController,
                            "your full name",
                          ),

                          _buildLabel("Email"),
                          _buildTextField(
                            _emailController,
                            "your@email.com",
                            icon: Icons.email,
                          ),

                          _buildLabel("Phone Number"),
                          _buildTextField(
                            _phoneController,
                            "23456789",
                            icon: Icons.phone,
                          ),

                          _buildLabel("Password"),
                          _buildPasswordField(_passwordController),

                          _buildLabel("Confirm Password"),
                          _buildPasswordField(_confirmpasswordController),

                          if (isDriver) ...[
                            const SizedBox(height: 20),
                            const Divider(color: Colors.white24),
                            _buildLabel("Driver Documents"),
                            const SizedBox(height: 15),
                            _buildDocPicker(
                              "Upload CIN Image",
                              cinImage,
                              () => pickImage((file) => cinImage = file),
                            ),
                            const SizedBox(height: 15),
                            _buildDocPicker(
                              "Upload Driver Card",
                              jobCardImage,
                              () => pickImage((file) => jobCardImage = file),
                            ),

                            _buildLabel("License Number"),
                            _buildTextField(
                              _licenseNumberController,
                              "AB-123456",
                            ),
                            _buildLabel("License Expiry"),
                            _buildTextField(
                              _licenseExpiryController,
                              "YYYY-MM-DD",
                            ),
                          ],

                          const SizedBox(height: 30),
                          Row(
                            children: [
                              Checkbox(
                                value: terms,
                                onChanged: (v) => setState(() => terms = v!),
                                activeColor: Colors.amber,
                              ),
                              const Expanded(
                                child: Text(
                                  'I accept the Terms & Conditions',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : handleSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFCC00),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.black,
                                    )
                                  : const Text(
                                      "SIGN UP",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- COMPOSANTS DE DESIGN ---

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 15, bottom: 5),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: icon != null
            ? Icon(icon, color: const Color(0xFFFFCC00), size: 18)
            : null,
        filled: true,
        fillColor: const Color(0xFF0F0F0F),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFCC00)),
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "••••••••",
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.lock, color: Colors.grey, size: 18),
        suffixIcon: IconButton(
          icon: Icon(
            obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () => setState(() => obscurePassword = !obscurePassword),
        ),
        filled: true,
        fillColor: const Color(0xFF0F0F0F),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFCC00)),
        ),
      ),
    );
  }

  Widget _buildRoleBtn(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFCC00).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFFFCC00) : const Color(0xFF333333),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePicker() {
    return Center(
      child: GestureDetector(
        onTap: () => pickImage((file) => profileImage = file),
        child: Stack(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: const Color(0xFF0F0F0F),
              backgroundImage: profileImage != null
                  ? FileImage(profileImage!)
                  : null,
              child: profileImage == null
                  ? const Icon(Icons.person, size: 40, color: Colors.grey)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFCC00),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 18,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocPicker(String label, File? file, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: file != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(file, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_a_photo,
                    color: Color(0xFFFFCC00),
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
      ),
    );
  }
}
