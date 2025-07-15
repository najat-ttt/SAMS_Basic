import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'login_page/login_page.dart';
import 'profile_page/course_teacher_dashboard_page.dart';
import 'profile_page/course_advisor_dashboard_page.dart';
import 'profile_page/department_head_dashboard_page.dart';
import 'profile_page/student_dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Platform specific Firebase initialization
  if (kIsWeb) {
    // Web-specific Firebase configuration
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAZk-0O762ba30uaKg4Z8mKVD10cV0okoM",
        appId: "1:241623526441:web:af145909d6302fb64f8038",
        messagingSenderId: "241623526441",
        projectId: "sams8-3-2025",
        storageBucket: "sams8-3-2025.firebasestorage.app",
        authDomain: "sams8-3-2025.firebaseapp.com",
      ),
    );
  } else if (Platform.isWindows) {
    // Windows-specific Firebase configuration
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAZk-0O762ba30uaKg4Z8mKVD10cV0okoM",
        appId: "1:241623526441:windows:af145909d6302fb64f8038",
        messagingSenderId: "241623526441",
        projectId: "sams8-3-2025",
        storageBucket: "sams8-3-2025.firebasestorage.app",
      ),
    );
  } else {
    // Default (Android/iOS) Firebase configuration
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAZk-0O762ba30uaKg4Z8mKVD10cV0okoM",
        appId: "1:241623526441:android:af145909d6302fb64f8038",
        messagingSenderId: "241623526441",
        projectId: "sams8-3-2025",
        storageBucket: "sams8-3-2025.firebasestorage.app",
      ),
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SAMS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white60),
        useMaterial3: true,
      ),
      home: const LoginPageWrapper(),
    );
  }
}

// Wrapper widget to handle authentication state while keeping LoginPage as the base home
class LoginPageWrapper extends StatelessWidget {
  const LoginPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while checking auth state
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          // User is signed in
          User user = snapshot.data!;
          // Check if email is verified
          if (user.emailVerified) {
            // Fetch user role from Firestore
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(),
              builder: (context, firestoreSnapshot) {
                if (firestoreSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (firestoreSnapshot.hasError) {
                  return Scaffold(
                    body: Center(
                      child: Text(
                        "Error loading user data: ${firestoreSnapshot.error}",
                        style: const TextStyle(fontSize: 18, color: Colors.blueGrey),
                      ),
                    ),
                  );
                }

                String role = firestoreSnapshot.data?.get('role') ?? 'Course Teacher';

                // Role-based dashboard navigation
                if (role == 'Course Teacher') {
                  return CourseTeacherDashboardPage(
                    name: user.displayName ?? "User",
                    email: user.email ?? "",
                    role: role,
                  );
                } else if (role == 'Course Advisor') {
                  return CourseAdvisorDashboardPage(
                    name: user.displayName ?? "User",
                    email: user.email ?? "",
                    role: role,
                  );
                } else if (role == 'Department Head') {
                  return DepartmentHeadDashboardPage(
                    name: user.displayName ?? "User",
                    email: user.email ?? "",
                    role: role,
                  );
                } else if (role == 'Student') {
                  return StudentDashboardPage(
                    name: user.displayName ?? "User",
                    email: user.email ?? "",
                    role: role,
                  );
                } else {
                  // Default fallback
                  return StudentDashboardPage(
                    name: user.displayName ?? "User",
                    email: user.email ?? "",
                    role: role,
                  );
                }
              },
            );
          } else {
            // If email is not verified, prompt the user to verify it
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Please verify your email to continue.",
                      style: TextStyle(fontSize: 18, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        // Resend verification email
                        await user.sendEmailVerification();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Verification email resent! Please check your inbox."),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 2.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: const Text("Resend Verification Email"),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () async {
                        // Sign out the user and redirect to LoginPage
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      },
                      child: const Text(
                        "Sign Out",
                        style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        } else {
          // User is not signed in, show LoginPage
          return const LoginPage();
        }
      },
    );
  }
}