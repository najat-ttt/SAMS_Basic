import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'dart:io';

class AttendanceReportPage extends StatefulWidget {
  const AttendanceReportPage({super.key});

  @override
  _AttendanceReportPageState createState() => _AttendanceReportPageState();
}

class _AttendanceReportPageState extends State<AttendanceReportPage> {
  String? selectedCourse;
  String? selectedSection;
  bool isLoading = false;
  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();

  final List<String> courses = [
    "Digital Logic Design",
    "Discrete Mathematics",
    "Electrical and Electronic Engineering",
    "Humanities",
    "Mathematics"
  ];

  final List<String> sections = ["A", "B", "C"];

  List<Map<String, dynamic>> students = [];
  Map<String, Map<String, String>> attendanceData = {};
  List<String> datesList = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Reports"),
        backgroundColor: Colors.blueGrey,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Generate Attendance Report",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                      const SizedBox(height: 16),

                      // Date Range Selection
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Start Date"),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _selectDate(context, true),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(DateFormat('yyyy-MM-dd').format(startDate)),
                                        const Icon(Icons.calendar_today),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("End Date"),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _selectDate(context, false),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(DateFormat('yyyy-MM-dd').format(endDate)),
                                        const Icon(Icons.calendar_today),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Generate Button
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isLoading ? null : _generateReport,
                              icon: const Icon(Icons.refresh),
                              label: const Text("Generate Report"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Export Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: (attendanceData.isEmpty || isLoading) ? null : _exportToExcel,
                              icon: const Icon(Icons.table_chart),
                              label: const Text("Export to Excel"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: (attendanceData.isEmpty || isLoading) ? null : _exportToPdf,
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text("Export to PDF"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Report Preview
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (attendanceData.isEmpty)
                    ? const Center(
                  child: Text(
                    "No data to display.\nPlease select course, section and date range and generate report.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
                    : Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Attendance Report: $selectedCourse - Section $selectedSection",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Period: ${DateFormat('yyyy-MM-dd').format(startDate)} to ${DateFormat('yyyy-MM-dd').format(endDate)}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: _buildAttendanceTable(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? startDate : endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
          if (startDate.isAfter(endDate)) {
            endDate = startDate;
          }
        } else {
          endDate = picked;
          if (endDate.isBefore(startDate)) {
            startDate = endDate;
          }
        }
      });
    }
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

      setState(() {
        students = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            "rollNo": data['roll'] ?? 0,
            "id": data['roll']?.toString() ?? '0',
            "name": data['name'] ?? 'Unknown',
          };
        }).toList();
      });
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

  Future<void> _generateReport() async {
    if (selectedCourse == null || selectedSection == null || students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select course and section first")),
      );
      return;
    }

    setState(() {
      isLoading = true;
      attendanceData.clear();
      datesList.clear();
    });

    try {
      // Generate list of dates between start and end date
      List<DateTime> datesInRange = [];
      for (DateTime date = startDate;
      date.isBefore(endDate.add(const Duration(days: 1)));
      date = date.add(const Duration(days: 1))) {
        datesInRange.add(date);
      }

      // Convert to string format for Firestore queries
      datesList = datesInRange.map((date) => DateFormat('yyyy-MM-dd').format(date)).toList();

      // Initialize attendance data structure
      for (var student in students) {
        attendanceData[student['id']] = {};
        for (var dateStr in datesList) {
          attendanceData[student['id']]![dateStr] = '-'; // Default to absent
        }
      }

      // Fetch attendance data for each date
      for (var dateStr in datesList) {
        final sectionRef = _firestore
            .collection('attendance_records')
            .doc(dateStr)
            .collection('sections')
            .doc(selectedSection);

        // Get all rolls for this section and date
        for (var student in students) {
          final String rollNo = student['id'];

          final courseDoc = await sectionRef
              .collection('rolls')
              .doc(rollNo)
              .collection('courses')
              .doc(selectedCourse)
              .get();

          if (courseDoc.exists) {
            String status = courseDoc.data()?['status'] ?? '-';
            attendanceData[rollNo]![dateStr] = status == 'Present' ? 'P' : 'A';
          }
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generating report: $e")),
      );
    }
  }

  Widget _buildAttendanceTable() {
    return DataTable(
      columnSpacing: 12,
      headingRowColor: MaterialStateProperty.all(Colors.blueGrey[100]),
      border: TableBorder.all(color: Colors.grey.shade300),
      columns: [
        const DataColumn(
          label: Text(
            'Roll',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const DataColumn(
          label: Text(
            'Name',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ...datesList.map(
              (dateStr) => DataColumn(
            label: SizedBox(
              width: 75,
              child: Text(
                dateStr.substring(5), // Show only MM-DD
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
      rows: students.map((student) {
        return DataRow(
          cells: [
            DataCell(Text(student['id'])),
            DataCell(Text(student['name'])),
            ...datesList.map(
                  (dateStr) => DataCell(
                Center(
                  child: Text(
                    attendanceData[student['id']]![dateStr] ?? '-',
                    style: TextStyle(
                      color: (attendanceData[student['id']]![dateStr] == 'P')
                          ? Colors.green
                          : ((attendanceData[student['id']]![dateStr] == 'A')
                          ? Colors.red
                          : Colors.grey),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Future<void> _exportToExcel() async {
    try {
      setState(() {
        isLoading = true;
      });

      final excel_lib.Excel excel = excel_lib.Excel.createExcel();
      final excel_lib.Sheet sheet = excel['Attendance Report'];

      // Add header
      final headerCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
      headerCell.value = excel_lib.TextCellValue('Attendance Report');

      final courseCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
      courseCell.value = excel_lib.TextCellValue('$selectedCourse - Section $selectedSection');

      final periodCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2));
      periodCell.value = excel_lib.TextCellValue('Period: ${DateFormat('yyyy-MM-dd').format(startDate)} to ${DateFormat('yyyy-MM-dd').format(endDate)}');

      // Add table headers
      final rollHeaderCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4));
      rollHeaderCell.value = excel_lib.TextCellValue('Roll');

      final nameHeaderCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4));
      nameHeaderCell.value = excel_lib.TextCellValue('Name');

      // Add date headers
      for (int i = 0; i < datesList.length; i++) {
        final dateCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: i + 2, rowIndex: 4));
        dateCell.value = excel_lib.TextCellValue(datesList[i]);
      }

      // Add student data
      for (int i = 0; i < students.length; i++) {
        final student = students[i];

        final rollCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 5));
        rollCell.value = excel_lib.TextCellValue(student['id']);

        final nameCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 5));
        nameCell.value = excel_lib.TextCellValue(student['name']);

        for (int j = 0; j < datesList.length; j++) {
          final dateStr = datesList[j];
          final status = attendanceData[student['id']]![dateStr] ?? '-';

          final statusCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: j + 2, rowIndex: i + 5));
          statusCell.value = excel_lib.TextCellValue(status);
        }
      }

      // Save the file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'attendance_report_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.xlsx';
      final path = '${directory.path}/$fileName';

      final fileBytes = excel.encode();
      final file = File(path);
      await file.writeAsBytes(fileBytes!);

      await OpenFile.open(path);

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Excel file saved to $path")),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error exporting to Excel: $e")),
      );
    }
  }

  Future<void> _exportToPdf() async {
    try {
      setState(() {
        isLoading = true;
      });

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text('Attendance Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 8),
              pw.Text('$selectedCourse - Section $selectedSection', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Period: ${DateFormat('yyyy-MM-dd').format(startDate)} to ${DateFormat('yyyy-MM-dd').format(endDate)}',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
              pw.SizedBox(height: 20),
              _buildPdfTable(),
            ];
          },
        ),
      );

      // Save the file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'attendance_report_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.pdf';
      final path = '${directory.path}/$fileName';

      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      await OpenFile.open(path);

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF file saved to $path")),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error exporting to PDF: $e")),
      );
    }
  }

  pw.Table _buildPdfTable() {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Roll', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            ...datesList.map(
                  (dateStr) => pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(dateStr, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
            ),
          ],
        ),
        // Data rows
        ...students.map(
              (student) => pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(student['id']),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(student['name']),
              ),
              ...datesList.map(
                    (dateStr) {
                  final status = attendanceData[student['id']]![dateStr] ?? '-';
                  return pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Center(
                      child: pw.Text(
                        status,
                        style: pw.TextStyle(
                          color: status == 'P'
                              ? PdfColors.green
                              : (status == 'A' ? PdfColors.red : PdfColors.grey),
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}