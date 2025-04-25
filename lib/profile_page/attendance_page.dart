import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

// State management with Provider
class AttendanceState extends ChangeNotifier {
  String? selectedCourse;
  String? selectedSection;
  bool isLoading = false;
  String? currentSessionId;
  DateTime selectedDate = DateTime.now();
  DateTime? currentSessionDate;
  bool isEditingPreviousSession = false;
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> previousSessions = [];
  bool isOffline = false;
  bool isInitialized = false;

  void setSelectedCourse(String? course) {
    selectedCourse = course;
    notifyListeners();
  }

  void setSelectedSection(String? section) {
    selectedSection = section;
    notifyListeners();
  }

  void setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }

  void setCurrentSessionId(String? id) {
    currentSessionId = id;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void setCurrentSessionDate(DateTime? date) {
    currentSessionDate = date;
    notifyListeners();
  }

  void setEditingPreviousSession(bool editing) {
    isEditingPreviousSession = editing;
    notifyListeners();
  }

  void setStudents(List<Map<String, dynamic>> studentsList) {
    students = studentsList;
    notifyListeners();
  }

  void updateStudentStatus(int index, String status) {
    students[index]['status'] = status;
    notifyListeners();
  }

  void setPreviousSessions(List<Map<String, dynamic>> sessions) {
    previousSessions = sessions;
    notifyListeners();
  }

  void setOfflineStatus(bool offline) {
    isOffline = offline;
    notifyListeners();
  }

  void setInitialized(bool initialized) {
    isInitialized = initialized;
    notifyListeners();
  }

  void resetSession() {
    currentSessionId = null;
    currentSessionDate = null;
    isEditingPreviousSession = false;
    students.clear();
    notifyListeners();
  }
}

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final List<String> courses = [
    "Digital Logic Design",
    "Discrete Mathematics",
    "Electrical and Electronic Engineering",
    "Humanities",
    "Mathematics"
  ];

  final List<String> sections = ["A", "B", "C"];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late SharedPreferences _prefs;
  late AttendanceState _state;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    // Initialize offline persistence for Firestore
    _initializeFirestoreSettings();
    // Initialize shared preferences for local caching
    _initializeSharedPreferences();
    // Monitor network connectivity
    _setupConnectivityMonitor();
    // Pre-fetch common data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefs.getInt('selectedCourseIndex')?.let((index) {
        if (index >= 0 && index < courses.length) {
          _state.setSelectedCourse(courses[index]);
        }
      });
      _prefs.getInt('selectedSectionIndex')?.let((index) {
        if (index >= 0 && index < sections.length) {
          _state.setSelectedSection(sections[index]);
          _prefetchStudentData();
        }
      });
    });
  }

  void _initializeFirestoreSettings() {
    _firestore.settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  Future<void> _initializeSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void _setupConnectivityMonitor() {
    // Update the listener to handle List<ConnectivityResult> instead of ConnectivityResult
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      // Check if there's any result in the list
      final hasConnection = results.isNotEmpty &&
          results.any((result) => result != ConnectivityResult.none);

      _state.setOfflineStatus(!hasConnection);

      if (hasConnection && _state.isOffline) {
        // Reconnected - sync data if needed
        _syncOfflineData();
      }
    });

    // Check initial connectivity
    Connectivity().checkConnectivity().then((result) {
      // Handle initial connectivity result
      final List<ConnectivityResult> results =
      result is List<ConnectivityResult> ? result : [result as ConnectivityResult];

      final hasConnection = results.isNotEmpty &&
          results.any((result) => result != ConnectivityResult.none);

      _state.setOfflineStatus(!hasConnection);
    });
  }

  Future<void> _syncOfflineData() async {
    // Implement logic to sync any offline changes when coming back online
    // This could involve checking for pending updates stored locally
    print("Network reconnected - syncing data");
  }

  Future<void> _prefetchStudentData() async {
    if (_state.selectedSection == null) return;

    _state.setLoading(true);

    try {
      // Check if we have cached data first
      final cachedStudentsJson = _prefs.getString('students_${_state.selectedSection}');
      if (cachedStudentsJson != null) {
        final List<dynamic> cachedStudents = jsonDecode(cachedStudentsJson);
        _state.setStudents(cachedStudents.cast<Map<String, dynamic>>());
      }

      // Then fetch from Firestore to update cache
      if (!_state.isOffline) {
        final querySnapshot = await _firestore
            .collection('students')
            .where('section', isEqualTo: _state.selectedSection)
            .orderBy('roll')
            .get();

        final studentsList = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            "rollNo": data['roll'] ?? 0,
            "id": data['roll']?.toString() ?? '0',
            "name": data['name'] ?? 'Unknown',
            "status": "Absent",
            "documentId": doc.id,
          };
        }).toList();

        // Update cache
        _prefs.setString('students_${_state.selectedSection}',
            jsonEncode(studentsList));

        _state.setStudents(studentsList);
        await _checkForExistingSession();
      }
    } catch (e) {
      _showErrorSnackBar("Error fetching students: $e");
    } finally {
      _state.setLoading(false);
      _state.setInitialized(true);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message))
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with ChangeNotifierProvider to access the state throughout the widget tree
    return ChangeNotifierProvider(
      create: (context) {
        _state = AttendanceState();
        return _state;
      },
      child: Consumer<AttendanceState>(
        builder: (context, state, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(state.isEditingPreviousSession
                  ? "Edit Previous Attendance"
                  : "Attendance System"),
              backgroundColor: Colors.blueGrey,
              actions: [
                // Network status indicator
                if (state.isOffline)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Chip(
                      backgroundColor: Colors.orangeAccent,
                      label: Text("Offline Mode",
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                      avatar: Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    ),
                  ),
                // Previous sessions button
                if (!state.isEditingPreviousSession)
                  IconButton(
                    icon: Icon(Icons.history),
                    onPressed: state.isOffline ? null : _showPreviousSessionsDialog,
                    tooltip: "Previous Sessions",
                  ),
                // Back button when editing
                if (state.isEditingPreviousSession)
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      state.resetSession();
                    },
                    tooltip: "Back to Current",
                  ),
              ],
            ),
            body: SafeArea(
              child: state.isInitialized
                  ? _buildMainContent(state)
                  : Center(child: CircularProgressIndicator()),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent(AttendanceState state) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course, Section Selection and Date Picker Card
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
                        "Date: ${DateFormat('yyyy-MM-dd').format(state.selectedDate)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: state.isEditingPreviousSession ? null : () => _selectDate(context),
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
                          value: state.selectedCourse,
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
                          onChanged: state.isEditingPreviousSession || state.isOffline
                              ? null
                              : (value) {
                            state.setSelectedCourse(value);
                            // Save selection to preferences
                            _prefs.setInt('selectedCourseIndex',
                                courses.indexOf(value!));
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Section Dropdown
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: state.selectedSection,
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
                          onChanged: state.isEditingPreviousSession || state.isOffline
                              ? null
                              : (value) {
                            state.setSelectedSection(value);
                            // Save selection to preferences
                            _prefs.setInt('selectedSectionIndex',
                                sections.indexOf(value!));
                            _prefetchStudentData();
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
          if (state.currentSessionId != null)
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.isEditingPreviousSession
                          ? "Editing Attendance - ${DateFormat('yyyy-MM-dd').format(state.currentSessionDate ?? state.selectedDate)}"
                          : "Attendance Session - ${DateFormat('yyyy-MM-dd').format(state.currentSessionDate ?? state.selectedDate)}",
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
                          "${state.selectedCourse} - Section ${state.selectedSection}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        ElevatedButton(
                          onPressed: state.isOffline ? null : _markAllPresent,
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

          // Student List with Error Handling and Retry
          _buildStudentList(state),

          // Session Controls
          if (state.students.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 16.0,
                children: [
                  if (!state.isEditingPreviousSession)
                    ElevatedButton(
                      onPressed: (state.currentSessionId == null && !state.isOffline)
                          ? _startNewSession
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(150, 50),
                      ),
                      child: const Text("New Session"),
                    ),
                  if (state.currentSessionId != null && !state.isEditingPreviousSession)
                    ElevatedButton(
                      onPressed: state.isOffline ? null : _endCurrentSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(150, 50),
                      ),
                      child: const Text("End Session"),
                    ),
                  // Save changes button for editing mode
                  if (state.isEditingPreviousSession)
                    ElevatedButton(
                      onPressed: state.isOffline ? null : _saveEditedAttendance,
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
    );
  }

  Widget _buildStudentList(AttendanceState state) {
    if (state.isLoading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (state.selectedCourse != null && state.selectedSection != null) {
      return Expanded(
        child: state.students.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "No students found in this section",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              if (state.isOffline)
                ElevatedButton(
                  onPressed: _prefetchStudentData,
                  child: const Text("Retry Loading"),
                ),
            ],
          ),
        )
            : ListView.builder(
          // Use a key to force rebuild when data changes
          key: ValueKey('student-list-${state.students.length}'),
          itemCount: state.students.length,
          itemBuilder: (context, index) {
            final student = state.students[index];
            return _buildStudentCard(student, index, state);
          },
          // Add physics to improve scroll performance
          physics: const AlwaysScrollableScrollPhysics(),
        ),
      );
    } else {
      return const Expanded(
        child: Center(
          child: Text(
            "Please select a course and section to begin",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }
  }

  Widget _buildStudentCard(Map<String, dynamic> student, int index, AttendanceState state) {
    return Card(
      key: ValueKey('student-${student['id']}'),
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
                }, state.isOffline),
                _buildStatusButton("Absent", student['status'] == "Absent", () {
                  _markAttendance(index, "Absent");
                }, state.isOffline),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(String label, bool isSelected, VoidCallback onPressed, bool isOffline) {
    return ElevatedButton(
      onPressed: isOffline ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? (label == "Present" ? Colors.green : Colors.red)
            : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _state.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _state.selectedDate) {
      _state.setSelectedDate(picked);
      _checkForExistingSession();
    }
  }

  Future<void> _checkForExistingSession() async {
    if (_state.selectedCourse == null || _state.selectedSection == null || _state.isOffline) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_state.selectedDate);
    _state.setLoading(true);

    try {
      // First check cache
      final sessionId = _prefs.getString('session_${_state.selectedCourse}_${_state.selectedSection}_$dateStr');
      if (sessionId != null) {
        _state.setCurrentSessionId(sessionId);
        _state.setCurrentSessionDate(_state.selectedDate);
        await _loadExistingAttendance();
      }

      // Then check Firestore
      final sessionQuery = await _firestore
          .collection('attendance_sessions')
          .where('course', isEqualTo: _state.selectedCourse)
          .where('section', isEqualTo: _state.selectedSection)
          .where('dateString', isEqualTo: dateStr)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (sessionQuery.docs.isNotEmpty) {
        final sessionDoc = sessionQuery.docs.first;
        _state.setCurrentSessionId(sessionDoc.id);
        _state.setCurrentSessionDate(_state.selectedDate);

        // Update cache
        _prefs.setString('session_${_state.selectedCourse}_${_state.selectedSection}_$dateStr',
            sessionDoc.id);

        await _loadExistingAttendance();
      } else if (sessionId == null) {
        _state.setCurrentSessionId(null);
        _state.setCurrentSessionDate(null);
      }
    } catch (e) {
      print("Error checking for existing session: $e");
      // Handle error gracefully
      _showErrorWithRetry("Could not check for existing sessions", _checkForExistingSession);
    } finally {
      _state.setLoading(false);
    }
  }

  void _showErrorWithRetry(String message, Function retryFunction) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () {
            retryFunction();
          },
        ),
      ),
    );
  }

  Future<void> _loadExistingAttendance() async {
    if (_state.selectedCourse == null ||
        _state.selectedSection == null ||
        _state.currentSessionDate == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_state.currentSessionDate!);

    try {
      // First check cache
      final attendanceKey = 'attendance_${_state.selectedCourse}_${_state.selectedSection}_$dateStr';
      final cachedAttendance = _prefs.getString(attendanceKey);

      if (cachedAttendance != null) {
        final Map<String, dynamic> attendanceData = jsonDecode(cachedAttendance);

        // Apply cached attendance to students list
        for (var student in _state.students) {
          final rollNo = student['id'];
          if (attendanceData.containsKey(rollNo)) {
            student['status'] = attendanceData[rollNo];
          }
        }
        _state.setStudents([..._state.students]); // Trigger UI update
      }

      // If online, fetch from Firestore and update cache
      if (!_state.isOffline) {
        Map<String, dynamic> attendanceMap = {};

        for (var student in _state.students) {
          final rollNo = student['id'];
          final doc = await _firestore
              .collection('attendance_records')
              .doc(dateStr)
              .collection('sections')
              .doc(_state.selectedSection)
              .collection('rolls')
              .doc(rollNo)
              .collection('courses')
              .doc(_state.selectedCourse)
              .get();

          if (doc.exists) {
            final status = doc.data()?['status'] ?? 'Absent';
            student['status'] = status;
            attendanceMap[rollNo] = status;
          }
        }

        // Save to cache
        _prefs.setString(attendanceKey, jsonEncode(attendanceMap));

        // Update UI
        _state.setStudents([..._state.students]);
      }
    } catch (e) {
      print("Error loading attendance: $e");
      _showErrorWithRetry("Could not load attendance data", _loadExistingAttendance);
    }
  }

  Future<void> _markAttendance(int index, String status) async {
    if (_state.currentSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please start a session first")),
      );
      return;
    }

    if (_state.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot update attendance while offline")),
      );
      return;
    }

    final student = _state.students[index];
    final dateStr = DateFormat('yyyy-MM-dd').format(_state.currentSessionDate ?? _state.selectedDate);

    try {
      // Update local state immediately for responsive UI
      _state.updateStudentStatus(index, status);

      // Update cache
      final attendanceKey = 'attendance_${_state.selectedCourse}_${_state.selectedSection}_$dateStr';
      final cachedAttendance = _prefs.getString(attendanceKey);
      Map<String, dynamic> attendanceMap = {};

      if (cachedAttendance != null) {
        attendanceMap = jsonDecode(cachedAttendance);
      }

      attendanceMap[student['id']] = status;
      _prefs.setString(attendanceKey, jsonEncode(attendanceMap));

      // Then update Firestore
      final batch = _firestore.batch();

      // 1. Date-level document
      final dateRef = _firestore.collection('attendance_records').doc(dateStr);
      batch.set(dateRef, {
        'lastUpdated': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));

      // 2. Section-level document
      final sectionRef = dateRef.collection('sections').doc(_state.selectedSection);
      batch.set(sectionRef, {
        'section': _state.selectedSection,
        'course': _state.selectedCourse
      }, SetOptions(merge: true));

      // 3. Roll-level document
      final rollRef = sectionRef.collection('rolls').doc(student['id']);
      batch.set(rollRef, {
        'name': student['name'],
        'lastUpdated': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));

      // 4. Course attendance record
      final courseRef = rollRef.collection('courses').doc(_state.selectedCourse);
      batch.set(courseRef, {
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
        'sessionId': _state.currentSessionId
      });

      await batch.commit();
    } catch (e) {
      // Revert local change if server update fails
      _state.updateStudentStatus(index, status == "Present" ? "Absent" : "Present");
      _showErrorSnackBar("Error updating attendance: $e");
    }
  }

  Future<void> _markAllPresent() async {
    if (_state.currentSessionId == null) return;

    _state.setLoading(true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_state.currentSessionDate ?? _state.selectedDate);
      final batch = _firestore.batch();

      // Update local state first
      List<Map<String, dynamic>> updatedStudents = _state.students.map((student) {
        return {...student, 'status': "Present"};
      }).toList();
      _state.setStudents(updatedStudents);

      // Update cache
      final attendanceKey = 'attendance_${_state.selectedCourse}_${_state.selectedSection}_$dateStr';
      Map<String, dynamic> attendanceMap = {};

      for (var student in updatedStudents) {
        attendanceMap[student['id']] = "Present";
      }

      _prefs.setString(attendanceKey, jsonEncode(attendanceMap));

      // Date-level document
      final dateRef = _firestore.collection('attendance_records').doc(dateStr);
      batch.set(dateRef, {
        'lastUpdated': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));

      // Section-level document
      final sectionRef = dateRef.collection('sections').doc(_state.selectedSection);
      batch.set(sectionRef, {
        'section': _state.selectedSection,
        'course': _state.selectedCourse
      }, SetOptions(merge: true));

      for (final student in updatedStudents) {
        // Roll-level document
        final rollRef = sectionRef.collection('rolls').doc(student['id']);
        batch.set(rollRef, {
          'name': student['name'],
          'lastUpdated': FieldValue.serverTimestamp()
        }, SetOptions(merge: true));

        // Course attendance record
        final courseRef = rollRef.collection('courses').doc(_state.selectedCourse);
        batch.set(courseRef, {
          'status': "Present",
          'timestamp': FieldValue.serverTimestamp(),
          'sessionId': _state.currentSessionId
        });
      }

      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All students marked present")),
      );
    } catch (e) {
      _showErrorSnackBar("Error marking all present: $e");
    } finally {
      _state.setLoading(false);
    }
  }

  Future<void> _startNewSession() async {
    if (_state.selectedCourse == null || _state.selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select course and section first")),
      );
      return;
    }

    if (_state.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot start new session while offline")),
      );
      return;
    }

    _state.setLoading(true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_state.selectedDate);

      // Create new session
      final sessionDoc = await _firestore.collection('attendance_sessions').add({
        'course': _state.selectedCourse,
        'section': _state.selectedSection,
        'date': _state.selectedDate,
        'dateString': dateStr,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update state
      _state.setCurrentSessionId(sessionDoc.id);
      _state.setCurrentSessionDate(_state.selectedDate);

      // Cache session ID
      _prefs.setString('session_${_state.selectedCourse}_${_state.selectedSection}_$dateStr',
          sessionDoc.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New session started")),
      );
    } catch (e) {
      _showErrorSnackBar("Error starting session: $e");
    } finally {
      _state.setLoading(false);
    }
  }

  Future<void> _endCurrentSession() async {
    if (_state.currentSessionId == null) return;

    _state.setLoading(true);

    try {
      await _firestore.collection('attendance_sessions').doc(_state.currentSessionId).update({
        'status': 'completed',
        'endTime': FieldValue.serverTimestamp(),
      });

      // Remove from cache
      final dateStr = DateFormat('yyyy-MM-dd').format(_state.currentSessionDate ?? _state.selectedDate);
      _prefs.remove('session_${_state.selectedCourse}_${_state.selectedSection}_$dateStr');

      _state.setCurrentSessionId(null);
      _state.setCurrentSessionDate(null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session completed successfully")),
      );
    } catch (e) {
      _showErrorSnackBar("Error ending session: $e");
    } finally {
      _state.setLoading(false);
    }
  }

  // METHODS FOR EDITING PREVIOUS SESSIONS WITH IMPROVED NETWORK HANDLING

  Future<void> _showPreviousSessionsDialog() async {
    if (_state.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot access previous sessions while offline")),
      );
      return;
    }

    _state.setLoading(true);

    try {
      // First check cache
      final cachedSessionsJson = _prefs.getString('previous_sessions');
      if (cachedSessionsJson != null) {
        final List<dynamic> cachedSessions = jsonDecode(cachedSessionsJson);
        _state.setPreviousSessions(cachedSessions.cast<Map<String, dynamic>>());
      }

      // Then fetch from Firestore to get latest
      final query = await _firestore
          .collection('attendance_sessions')
          .where('status', isEqualTo: 'completed')
          .orderBy('date', descending: true)
          .limit(30) // Limit to recent 30 sessions
          .get();

      final sessions = query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'course': data['course'],
          'section': data['section'],
          'date': (data['date'] as Timestamp).toDate(),
          'dateString': data['dateString'],
        };
      }).toList();

      // Update cache
      _prefs.setString('previous_sessions', jsonEncode(sessions));

      _state.setPreviousSessions(sessions);

      // Show dialog with previous sessions
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => _buildPreviousSessionsDialog(),
        );
      }
    } catch (e) {
      _showErrorWithRetry("Error fetching previous sessions", _showPreviousSessionsDialog);
    } finally {
      _state.setLoading(false);
    }
  }

  Widget _buildPreviousSessionsDialog() {
    return AlertDialog(
      title: const Text("Previous Attendance Sessions"),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _state.previousSessions.isEmpty
            ? const Center(child: Text("No previous sessions found"))
            : ListView.builder(
          itemCount: _state.previousSessions.length,
          itemBuilder: (context, index) {
            final session = _state.previousSessions[index];
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

  Future<void> _editPreviousSession(Map<String, dynamic> session) async {
    if (_state.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot edit previous sessions while offline")),
      );
      return;
    }

    _state.setLoading(true);
    _state.setEditingPreviousSession(true);
    _state.setSelectedCourse(session['course']);
    _state.setSelectedSection(session['section']);
    _state.setCurrentSessionId(session['id']);
    _state.setCurrentSessionDate(session['date']);
    _state.setStudents([]);

    try {
      // Fetch students for this section - first from cache
      final cachedStudentsJson = _prefs.getString('students_${session['section']}');
      if (cachedStudentsJson != null) {
        final List<dynamic> cachedStudents = jsonDecode(cachedStudentsJson);
        _state.setStudents(cachedStudents.cast<Map<String, dynamic>>());
      }

      // Then from Firestore
      final querySnapshot = await _firestore
          .collection('students')
          .where('section', isEqualTo: session['section'])
          .orderBy('roll')
          .get();

      final studentsList = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "rollNo": data['roll'] ?? 0,
          "id": data['roll']?.toString() ?? '0',
          "name": data['name'] ?? 'Unknown',
          "status": "Absent",
          "documentId": doc.id,
        };
      }).toList();

      // Cache updated list
      _prefs.setString('students_${session['section']}', jsonEncode(studentsList));

      _state.setStudents(studentsList);

      // Load attendance data from the selected previous session
      await _loadExistingAttendance();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Previous session loaded for editing")),
      );
    } catch (e) {
      _showErrorSnackBar("Error loading previous session: $e");
      _state.setEditingPreviousSession(false);
      _state.setCurrentSessionId(null);
      _state.setCurrentSessionDate(null);
    } finally {
      _state.setLoading(false);
    }
  }

  Future<void> _saveEditedAttendance() async {
    if (_state.currentSessionId == null || !_state.isEditingPreviousSession) return;

    if (_state.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot save changes while offline")),
      );
      return;
    }

    _state.setLoading(true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_state.currentSessionDate!);
      final batch = _firestore.batch();

      // Update cache first
      final attendanceKey = 'attendance_${_state.selectedCourse}_${_state.selectedSection}_$dateStr';
      Map<String, dynamic> attendanceMap = {};

      for (var student in _state.students) {
        attendanceMap[student['id']] = student['status'];
      }

      _prefs.setString(attendanceKey, jsonEncode(attendanceMap));

      // Update the timestamp at date level
      final dateRef = _firestore.collection('attendance_records').doc(dateStr);
      batch.set(dateRef, {
        'lastUpdated': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));

      // Process each student's attendance
      for (final student in _state.students) {
        final rollRef = dateRef
            .collection('sections')
            .doc(_state.selectedSection)
            .collection('rolls')
            .doc(student['id']);

        batch.set(rollRef, {
          'lastUpdated': FieldValue.serverTimestamp()
        }, SetOptions(merge: true));

        final courseRef = rollRef.collection('courses').doc(_state.selectedCourse);
        batch.set(courseRef, {
          'status': student['status'],
          'timestamp': FieldValue.serverTimestamp(),
          'sessionId': _state.currentSessionId,
          'editedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance updated successfully")),
      );

      // Return to normal mode
      _state.resetSession();
    } catch (e) {
      _showErrorSnackBar("Error saving attendance changes: $e");
    } finally {
      _state.setLoading(false);
    }
  }
}

// Extension for nullable int in SharedPreferences
extension NullableIntExtension on int? {
  void let(Function(int) block) {
    final value = this;
    if (value != null) {
      block(value);
    }
  }
}
