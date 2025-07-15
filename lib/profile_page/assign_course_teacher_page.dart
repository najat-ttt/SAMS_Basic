import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignCourseTeacherPage extends StatefulWidget {
  const AssignCourseTeacherPage({super.key});

  @override
  State<AssignCourseTeacherPage> createState() => _AssignCourseTeacherPageState();
}

class _AssignCourseTeacherPageState extends State<AssignCourseTeacherPage> {
  String? selectedCourse;
  String? selectedTeacherEmail;
  bool _isLoading = false;

  Future<List<Map<String, String>>> _fetchCourses() async {
    final snapshot = await FirebaseFirestore.instance.collection('courses').get();
    return snapshot.docs.map((doc) => {
      'code': doc['code']?.toString() ?? '',
      'name': doc['name']?.toString() ?? doc['code']?.toString() ?? '',
    }).where((course) => course['code']!.isNotEmpty).toList();
  }

  Future<List<Map<String, String>>> _fetchTeachers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    List<Map<String, String>> teachers = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      // Debug print to check what is in each user document
      debugPrint('User doc: ' + data.toString());
      final role = data['role']?.toString().trim().toLowerCase();
      final email = data['email']?.toString() ?? '';
      final name = data['name']?.toString() ?? email;
      if (role == 'course teacher' && email.isNotEmpty) {
        teachers.add({'email': email, 'name': name});
      }
    }
    debugPrint('Filtered teachers: ' + teachers.toString());
    return teachers;
  }

  Future<void> _assignTeacher() async {
    if (selectedCourse == null || selectedTeacherEmail == null) return;
    setState(() { _isLoading = true; });
    try {
      await FirebaseFirestore.instance.collection('courses').doc(selectedCourse).update({
        'teacher': selectedTeacherEmail,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course teacher assigned successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error assigning teacher: \\n${e.toString()}')),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Course Teacher'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<List<Map<String, String>>>(
              future: _fetchCourses(),
              builder: (context, courseSnapshot) {
                if (courseSnapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                final courses = courseSnapshot.data ?? [];
                if (courses.isEmpty) {
                  return const Text('No courses found.');
                }
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Select Course'),
                  items: courses.map((course) => DropdownMenuItem(
                    value: course['code'],
                    child: Text('${course['code']} - ${course['name']}'),
                  )).toList(),
                  value: selectedCourse,
                  onChanged: (value) => setState(() => selectedCourse = value),
                );
              },
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, String>>>(
              future: _fetchTeachers(),
              builder: (context, teacherSnapshot) {
                if (teacherSnapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                final teachers = teacherSnapshot.data ?? [];
                // DEBUG: Show fetched teachers in the UI for troubleshooting
                if (teachers.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('No course teachers found.'),
                      const SizedBox(height: 8),
                      Text('Fetched teachers: ' + teachers.toString(), style: const TextStyle(fontSize: 12, color: Colors.red)),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fetched teachers: ' + teachers.toString(), style: const TextStyle(fontSize: 12, color: Colors.green)),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Select Teacher'),
                      items: teachers.map((teacher) => DropdownMenuItem(
                        value: teacher['email'],
                        child: Text(teacher['name'] ?? teacher['email']!),
                      )).toList(),
                      value: selectedTeacherEmail,
                      onChanged: (value) => setState(() => selectedTeacherEmail = value),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    icon: const Icon(Icons.assignment_ind),
                    label: const Text('Assign Teacher'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      minimumSize: const Size(150, 48),
                    ),
                    onPressed: _assignTeacher,
                  ),
          ],
        ),
      ),
    );
  }
}
