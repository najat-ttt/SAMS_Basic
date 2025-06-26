import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../login_page/login_page.dart';

class ProfilePage extends StatefulWidget {
  final String name;
  final String email;
  final String password; // For demonstration purposes

  const ProfilePage({super.key,
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String _name;
  late String _email;
  late String _password;
  File? _profileImage;
  static const String _profileImagePathKey = 'profile_image_path';

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _email = widget.email;
    _password = widget.password;
    _loadProfileImage();
  }

  // Load the profile image path from SharedPreferences
  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString(_profileImagePathKey);

    if (imagePath != null) {
      final file = File(imagePath);
      if (await file.exists()) {
        setState(() {
          _profileImage = file;
        });
      }
    }
  }

  // Save the profile image path to SharedPreferences
  Future<void> _saveProfileImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImagePathKey, path);
  }

  void _editProfile(BuildContext context) {
    TextEditingController nameController = TextEditingController(text: _name);
    TextEditingController emailController = TextEditingController(text: _email);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Profile"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField("Full Name", nameController),
                SizedBox(height: 10),
                _buildTextField("Email", emailController),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _name = nameController.text;
                  _email = emailController.text;
                });
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Copy the image to app's documents directory to ensure persistence
      final String newPath = await _saveImageToAppDirectory(image.path);

      setState(() {
        _profileImage = File(newPath);
      });

      // Save the path for future app launches
      await _saveProfileImagePath(newPath);
    }
  }

  // Save image to application documents directory to ensure persistence
  Future<String> _saveImageToAppDirectory(String sourcePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String targetPath = '${directory.path}/$fileName';

    // Copy the image
    final File sourceFile = File(sourcePath);
    final File newImage = await sourceFile.copy(targetPath);

    return newImage.path;
  }

  void _logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final double avatarRadius = isSmallScreen ? 60 : 50;
    final double nameFontSize = isSmallScreen ? 26 : 22;
    final double emailFontSize = isSmallScreen ? 18 : 15;
    final double fieldFontSize = isSmallScreen ? 17 : 14;
    final double buttonFontSize = isSmallScreen ? 18 : 15;
    final double buttonWidth = isSmallScreen ? 220 : 180;
    final double buttonHeight = isSmallScreen ? 50 : 44;
    final double cardPadding = isSmallScreen ? 20 : 16;

    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: "Logout",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(cardPadding),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Colors.blueGrey,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? Text(
                      _name.isNotEmpty ? _name[0].toUpperCase() : "U",
                      style: TextStyle(fontSize: avatarRadius * 0.9, color: Colors.white),
                    )
                        : null,
                  ),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: _pickImage,
                  child: Text("Change Profile Picture", style: TextStyle(fontSize: fieldFontSize)),
                ),
                SizedBox(height: 20),
                Text(
                  _name,
                  style: TextStyle(
                    fontSize: nameFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  _email,
                  style: TextStyle(
                    fontSize: emailFontSize,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                Divider(),
                SizedBox(height: 20),
                _buildProfileField("Full Name", _name, fieldFontSize),
                _buildProfileField("Email", _email, fieldFontSize),
                _buildProfileField("Password", _password.replaceAll(RegExp(r"."), "*"), fieldFontSize),
                SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () => _editProfile(context),
                  icon: Icon(Icons.edit),
                  label: Text("Edit Profile", style: TextStyle(fontSize: buttonFontSize)),
                  style: ElevatedButton.styleFrom(
                    elevation: 2.0,
                    fixedSize: Size(buttonWidth, buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    _logout(context);
                  },
                  icon: Icon(Icons.logout),
                  label: Text("Logout", style: TextStyle(fontSize: buttonFontSize)),
                  style: ElevatedButton.styleFrom(
                    elevation: 2.0,
                    fixedSize: Size(buttonWidth, buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String title, String value, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title:",
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }
}