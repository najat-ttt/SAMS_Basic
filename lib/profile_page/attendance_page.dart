import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  String? selectedCourse;
  String? selectedSection;
  bool isLoading = false;
  String? currentSessionId;
  DateTime selectedDate = DateTime.now();
  DateTime? currentSessionDate;

  final List<String> courses = [
    "Mathematics",
    "Humanities",
    "Digital Logic Design",
    "Electrical and Electronic Engineering",
    "Discrete Mathematics",
  ];

  final List<String> sections = ["A", "B", "C"];

  List<Map<String, dynamic>> students = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance System"),
        backgroundColor: Colors.blueGrey,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course, Section Selection and Date Picker Row
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Selection
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.blueGrey),
                          const SizedBox(width: 8),
                          Text(
                            "Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _selectDate(context),
                            child: const Text("Change Date"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Course and Section Selection
                      Row(
                        children: [
                          // Course Dropdown
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              value: selectedCourse,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: "Select Course",
                                border: OutlineInputBorder(),
                              ),
                              items: courses.map((course) {
                                return DropdownMenuItem(
                                  value: course,
                                  child: Text(course, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedCourse = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Section Dropdown
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: selectedSection,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: "Section",
                                border: OutlineInputBorder(),
                              ),
                              items: sections.map((section) {
                                return DropdownMenuItem(
                                  value: section,
                                  child: Text("$section"),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedSection = value;
                                  _fetchStudents();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Session Info
              if (currentSessionId != null)
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Attendance Session - ${DateFormat('yyyy-MM-dd').format(currentSessionDate ?? selectedDate)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          children: [
                            Text(
                              "$selectedCourse - Section $selectedSection",
                              style: const TextStyle(fontSize: 16),
                            ),
                            ElevatedButton(
                              onPressed: _markAllPresent,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text("Mark All Present"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Student List
              if (isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (selectedCourse != null && selectedSection != null)
                Expanded(
                  child: students.isEmpty
                      ? const Center(
                    child: Text(
                      "No students found in this section",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                      : ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return _buildStudentCard(student, index);
                    },
                  ),
                )
              else
                const Expanded(
                  child: Center(
                    child: Text(
                      "Please select a course and section to begin",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),

              // Session Controls
              if (students.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    spacing: 16.0,
                    children: [
                      ElevatedButton(
                        onPressed: currentSessionId == null ? _startNewSession : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(150, 50),
                        ),
                        child: const Text("New Session"),
                      ),
                      if (currentSessionId != null)
                        ElevatedButton(
                          onPressed: _endCurrentSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: const Size(150, 50),
                          ),
                          child: const Text("End Session"),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _checkForExistingSession();
    }
  }

  Widget _buildStudentCard(Map<String, dynamic> student, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${student['id']}: ${student['name']}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: [
                _buildStatusButton("Present", student['status'] == "Present", () {
                  _markAttendance(index, "Present");
                }),
                _buildStatusButton("Absent", student['status'] == "Absent", () {
                  _markAttendance(index, "Absent");
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(String label, bool isSelected, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? (label == "Present" ? Colors.green : Colors.red)
            : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  Future<void> _fetchStudents() async {
    if (selectedSection == null) return;

    setState(() {
      isLoading = true;
      students.clear();
    });

    try {
      final querySnapshot = await _firestore
          .collection('students')
          .where('section', isEqualTo: selectedSection)
          .orderBy('roll')
          .get();

      students = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "rollNo": data['roll'] ?? 0,
          "id": data['roll']?.toString() ?? '0',
          "name": data['name'] ?? 'Unknown',
          "status": "Absent",
          "documentId": doc.id,
        };
      }).toList();

      await _checkForExistingSession();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching students: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _checkForExistingSession() async {
    if (selectedCourse == null || selectedSection == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    try {
      final sessionQuery = await _firestore
          .collection('attendance_sessions')
          .where('course', isEqualTo: selectedCourse)
          .where('section', isEqualTo: selectedSection)
          .where('dateString', isEqualTo: dateStr)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (sessionQuery.docs.isNotEmpty) {
        final sessionDoc = sessionQuery.docs.first;
        setState(() {
          currentSessionId = sessionDoc.id;
          currentSessionDate = selectedDate;
        });
        await _loadExistingAttendance();
      } else {
        setState(() {
          currentSessionId = null;
          currentSessionDate = null;
        });
      }
    } catch (e) {
      print("Error checking for existing session: $e");
    }
  }

  Future<void> _loadExistingAttendance() async {
    if (selectedCourse == null || selectedSection == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    try {
      for (var student in students) {
        final rollNo = student['id'];
        final doc = await _firestore
            .collection('attendance_records')
            .doc(dateStr)
            .collection('sections')
            .doc(selectedSection)
            .collection('rolls')
            .doc(rollNo)
            .collection('courses')
            .doc(selectedCourse)
            .get();

        if (doc.exists) {
          student['status'] = doc.data()?['status'] ?? 'Absent';
        }
      }
      setState(() {});
    } catch (e) {
      print("Error loading attendance: $e");
    }
  }

  Future<void> _startNewSession() async {
    if (selectedCourse == null || selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select course and section first")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

      // Create new session
      final sessionDoc = await _firestore.collection('attendance_sessions').add({
        'course': selectedCourse,
        'section': selectedSection,
        'date': selectedDate,
        'dateString': dateStr,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        currentSessionId = sessionDoc.id;
        currentSessionDate = selectedDate;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New session started")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error starting session: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _markAttendance(int index, String status) async {
    if (currentSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please start a session first")),
      );
      return;
    }

    final student = students[index];
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    try {
      setState(() {
        student['status'] = status;
      });

      final batch = _firestore.batch();

      // 1. Date-level document
      final dateRef = _firestore.collection('attendance_records').doc(dateStr);
      batch.set(dateRef, {
        'lastUpdated': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));

      // 2. Section-level document
      final sectionRef = dateRef.collection('sections').doc(selectedSection);
      batch.set(sectionRef, {
        'section': selectedSection,
        'course': selectedCourse
      }, SetOptions(merge: true));

      // 3. Roll-level document
      final rollRef = sectionRef.collection('rolls').doc(student['id']);
      batch.set(rollRef, {
        'name': student['name'],
        'lastUpdated': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));

      // 4. Course attendance record
      final courseRef = rollRef.collection('courses').doc(selectedCourse);
      batch.set(courseRef, {
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
        'sessionId': currentSessionId
      });

      await batch.commit();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating attendance: $e")),
      );
    }
  }

  Future<void> _markAllPresent() async {
    if (currentSessionId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final batch = _firestore.batch();

      // Date-level document
      final dateRef = _firestore.collection('attendance_records').doc(dateStr);
      batch.set(dateRef, {
        'lastUpdated': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));

      // Section-level document
      final sectionRef = dateRef.collection('sections').doc(selectedSection);
      batch.set(sectionRef, {
        'section': selectedSection,
        'course': selectedCourse
      }, SetOptions(merge: true));

      for (final student in students) {
        student['status'] = "Present";

        // Roll-level document
        final rollRef = sectionRef.collection('rolls').doc(student['id']);
        batch.set(rollRef, {
          'name': student['name'],
          'lastUpdated': FieldValue.serverTimestamp()
        }, SetOptions(merge: true));

        // Course attendance record
        final courseRef = rollRef.collection('courses').doc(selectedCourse);
        batch.set(courseRef, {
          'status': "Present",
          'timestamp': FieldValue.serverTimestamp(),
          'sessionId': currentSessionId
        });
      }

      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All students marked present")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error marking all present: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _endCurrentSession() async {
    if (currentSessionId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      await _firestore.collection('attendance_sessions').doc(currentSessionId).update({
        'status': 'completed',
        'endTime': FieldValue.serverTimestamp(),
      });

      setState(() {
        currentSessionId = null;
        currentSessionDate = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session completed successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error ending session: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}