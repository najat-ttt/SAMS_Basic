import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _email = widget.email;
    _password = widget.password;
  }

  void _editProfile(BuildContext context) {
    TextEditingController nameController = TextEditingController(text: _name);
    TextEditingController emailController = TextEditingController(text: _email);
    TextEditingController passwordController = TextEditingController(text: _password);

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
                SizedBox(height: 10),
                _buildTextField("Password", passwordController, obscureText: true),
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
                  _password = passwordController.text;
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
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  void _logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        padding: EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: constraints.maxWidth * 0.15, // Responsive size
                    backgroundColor: Colors.blueGrey,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? Text(
                      _name.isNotEmpty ? _name[0].toUpperCase() : "U",
                      style: TextStyle(fontSize: constraints.maxWidth * 0.1, color: Colors.white),
                    )
                        : null,
                  ),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: _pickImage,
                  child: Text("Change Profile Picture"),
                ),
                SizedBox(height: 20),
                Text(
                  _name,
                  style: TextStyle(
                    fontSize: constraints.maxWidth * 0.06, // Responsive font size
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _email,
                  style: TextStyle(
                    fontSize: constraints.maxWidth * 0.04, // Responsive font size
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 30),
                Divider(),
                SizedBox(height: 20),
                _buildProfileField("Full Name", _name, constraints),
                _buildProfileField("Email", _email, constraints),
                _buildProfileField("Password", _password.replaceAll(RegExp(r"."), "*"), constraints), // Mask password
                SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () => _editProfile(context),
                  icon: Icon(Icons.edit),
                  label: Text("Edit Profile"),
                  style: ElevatedButton.styleFrom(
                    elevation: 2.0,
                    fixedSize: Size(constraints.maxWidth * 0.4, 50), // Responsive button size
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
                  label: Text("Logout"),
                  style: ElevatedButton.styleFrom(
                    elevation: 2.0,
                    fixedSize: Size(constraints.maxWidth * 0.4, 50), // Responsive button size
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileField(String title, String value, BoxConstraints constraints) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title:",
            style: TextStyle(
              fontSize: constraints.maxWidth * 0.04, // Responsive font size
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: constraints.maxWidth * 0.04, // Responsive font size
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