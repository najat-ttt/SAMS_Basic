import 'package:flutter/material.dart';
import 'attendance_page.dart';
import 'reports_page.dart';
import 'schedule_page.dart';
import '../login_page/login_page.dart';
import 'profile_page.dart';

class DashboardPage extends StatelessWidget {
  final String name;
  final String email;
  final String role;

  const DashboardPage({super.key, 
    required this.name,
    required this.email,
    required this.role,
  });

  void _logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Breakpoint for small screens

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: "Logout",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              "Welcome, $name!",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Email: $email",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // Disable GridView scrolling
              crossAxisCount: isSmallScreen ? 2 : 4, // Responsive grid columns
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2, // Adjusted aspect ratio for better fit
              children: [
                _buildDashboardCard(
                  icon: Icons.person,
                  title: "Profile",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(
                          name: name,
                          email: email,
                          password: "********", // For demonstration
                        ),
                      ),
                    );
                  },
                ),
                _buildDashboardCard(
                  icon: Icons.check_circle,
                  title: "Attendance",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AttendancePage(),
                      ),
                    );
                  },
                ),
                _buildDashboardCard(
                  icon: Icons.calendar_today,
                  title: "Schedule",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SchedulePage(),
                      ),
                    );
                  },
                ),
                _buildDashboardCard(
                  icon: Icons.analytics,
                  title: "Reports",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AttendanceReportPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build a dashboard card
  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Ensure the Column takes minimum space
            children: [
              Icon(icon, size: 48, color: Colors.blueGrey),
              const SizedBox(height: 8), // Reduced spacing
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2, // Limit text to 2 lines
                overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
              ),
            ],
          ),
        ),
      ),
    );
  }
}