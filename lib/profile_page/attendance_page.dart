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
  // Add a flag to track if we're in edit mode
  bool isEditingPreviousSession = false;

  final List<String> courses = [
    "Digital Logic Design",
    "Discrete Mathematics",
    "Electrical and Electronic Engineering",
    "Humanities",
    "Mathematics"
  ];

  final List<String> sections = ["A", "B", "C"];

  List<Map<String, dynamic>> students = [];
  // Add a list to store previous sessions
  List<Map<String, dynamic>> previousSessions = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditingPreviousSession ? "Edit Previous Attendance" : "Attendance System"),
        backgroundColor: Colors.blueGrey,
        actions: [
          // Add a button to access previous sessions
          if (!isEditingPreviousSession)
            IconButton(
              icon: Icon(Icons.history),
              onPressed: _showPreviousSessionsDialog,
              tooltip: "Previous Sessions",
            ),
          // Add a back button when editing previous sessions
          if (isEditingPreviousSession)
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  isEditingPreviousSession = false;
                  currentSessionId = null;
                  currentSessionDate = null;
                  students.clear();
                });
              },
              tooltip: "Back to Current",
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course, Section Selection and Date Picker Row
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Selection
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.blueGrey),
                          const SizedBox(width: 5),
                          Text(
                            "Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: isEditingPreviousSession ? null : () => _selectDate(context),
                            child: const Text("Change Date"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

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
                              onChanged: isEditingPreviousSession ? null : (value) {
                                setState(() {
                                  selectedCourse = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Section Dropdown
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: selectedSection,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: "Select Section",
                                border: OutlineInputBorder(),
                              ),
                              items: sections.map((section) {
                                return DropdownMenuItem(
                                  value: section,
                                  child: Text("$section"),
                                );
                              }).toList(),
                              onChanged: isEditingPreviousSession ? null : (value) {
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
              const SizedBox(height: 10),

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
                          isEditingPreviousSession
                              ? "Editing Attendance - ${DateFormat('yyyy-MM-dd').format(currentSessionDate ?? selectedDate)}"
                              : "Attendance Session - ${DateFormat('yyyy-MM-dd').format(currentSessionDate ?? selectedDate)}",
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
                      if (!isEditingPreviousSession)
                        ElevatedButton(
                          onPressed: currentSessionId == null ? _startNewSession : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size(150, 50),
                          ),
                          child: const Text("New Session"),
                        ),
                      if (currentSessionId != null && !isEditingPreviousSession)
                        ElevatedButton(
                          onPressed: _endCurrentSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: const Size(150, 50),
                          ),
                          child: const Text("End Session"),
                        ),
                      // Save changes button for editing mode
                      if (isEditingPreviousSession)
                        ElevatedButton(
                          onPressed: _saveEditedAttendance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            minimumSize: const Size(150, 50),
                          ),
                          child: const Text("Save Changes"),
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
    if (selectedCourse == null || selectedSection == null || currentSessionDate == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(currentSessionDate!);

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
    final dateStr = DateFormat('yyyy-MM-dd').format(currentSessionDate ?? selectedDate);

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
      final dateStr = DateFormat('yyyy-MM-dd').format(currentSessionDate ?? selectedDate);
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

  // NEW METHODS FOR EDITING PREVIOUS SESSIONS

  // Method to fetch and show previous completed sessions
  Future<void> _showPreviousSessionsDialog() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch completed sessions for the selected course and section
      final query = await _firestore
          .collection('attendance_sessions')
          .where('status', isEqualTo: 'completed')
          .orderBy('date', descending: true)
          .limit(30) // Limit to recent 30 sessions
          .get();

      previousSessions = query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'course': data['course'],
          'section': data['section'],
          'date': (data['date'] as Timestamp).toDate(),
          'dateString': data['dateString'],
        };
      }).toList();

      // Show dialog with previous sessions
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => _buildPreviousSessionsDialog(),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching previous sessions: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Build dialog to show previous sessions
  Widget _buildPreviousSessionsDialog() {
    return AlertDialog(
      title: const Text("Previous Attendance Sessions"),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: previousSessions.isEmpty
            ? const Center(child: Text("No previous sessions found"))
            : ListView.builder(
          itemCount: previousSessions.length,
          itemBuilder: (context, index) {
            final session = previousSessions[index];
            return ListTile(
              title: Text("${session['course']} - Section ${session['section']}"),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(session['date'])),
              trailing: const Icon(Icons.edit),
              onTap: () {
                Navigator.of(context).pop(); // Close dialog
                _editPreviousSession(session);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
      ],
    );
  }

  // Method to load a previous session for editing
  Future<void> _editPreviousSession(Map<String, dynamic> session) async {
    setState(() {
      isLoading = true;
      isEditingPreviousSession = true;
      selectedCourse = session['course'];
      selectedSection = session['section'];
      currentSessionId = session['id'];
      currentSessionDate = session['date'];
      students.clear();
    });

    try {
      // Fetch students for this section
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

      // Load attendance data from the selected previous session
      await _loadExistingAttendance();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Previous session loaded for editing")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading previous session: $e")),
      );
      setState(() {
        isEditingPreviousSession = false;
        currentSessionId = null;
        currentSessionDate = null;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Method to save changes to the edited attendance
  Future<void> _saveEditedAttendance() async {
    if (currentSessionId == null || !isEditingPreviousSession) return;

    setState(() {
      isLoading = true;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(currentSessionDate!);
      final batch = _firestore.batch();

      // Update the timestamp at date level
      final dateRef = _firestore.collection('attendance_records').doc(dateStr);
      batch.set(dateRef, {
        'lastUpdated': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));

      // Process each student's attendance
      for (final student in students) {
        final rollRef = dateRef
            .collection('sections')
            .doc(selectedSection)
            .collection('rolls')
            .doc(student['id']);

        batch.set(rollRef, {
          'lastUpdated': FieldValue.serverTimestamp()
        }, SetOptions(merge: true));

        final courseRef = rollRef.collection('courses').doc(selectedCourse);
        batch.set(courseRef, {
          'status': student['status'],
          'timestamp': FieldValue.serverTimestamp(),
          'sessionId': currentSessionId,
          'editedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance updated successfully")),
      );

      // Return to normal mode
      setState(() {
        isEditingPreviousSession = false;
        currentSessionId = null;
        currentSessionDate = null;
        students.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving attendance changes: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}