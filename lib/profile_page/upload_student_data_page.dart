import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';

class UploadStudentDataPage extends StatefulWidget {
  const UploadStudentDataPage({super.key});

  @override
  State<UploadStudentDataPage> createState() => _UploadStudentDataPageState();
}

class _UploadStudentDataPageState extends State<UploadStudentDataPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rollController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  final TextEditingController _seriesController = TextEditingController();
  bool _isLoading = false;
  String _uploadMode = 'manual'; // 'manual' or 'excel'

  Future<void> _uploadStudent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    try {
      final seriesDoc = 'series-${_seriesController.text.trim()}';
      final roll = int.tryParse(_rollController.text.trim()) ?? 0;
      await FirebaseFirestore.instance
          .collection('student')
          .doc(seriesDoc)
          .collection('students')
          .doc(roll.toString())
          .set({
        'roll': roll,
        'name': _nameController.text.trim(),
        'section': _sectionController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student data uploaded successfully!')),
      );
      _nameController.clear();
      _rollController.clear();
      _sectionController.clear();
      _seriesController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading student: $e')),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _importFromExcel() async {
    setState(() { _isLoading = true; });
    try {
      final seriesDoc = 'series-${_seriesController.text.trim()}';
      // Pick Excel file
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
      if (result == null || result.files.isEmpty) {
        setState(() { _isLoading = false; });
        return;
      }
      final fileBytes = result.files.first.bytes;
      if (fileBytes == null) {
        setState(() { _isLoading = false; });
        return;
      }
      final excel = Excel.decodeBytes(fileBytes);
      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) {
        setState(() { _isLoading = false; });
        return;
      }
      // Find column indexes for name, roll (robust against formatting, any order, log headers)
      final header = sheet.rows.first.map((cell) {
        if (cell == null || cell.value == null) return '';
        return cell.value.toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
      }).toList();
      debugPrint('Excel headers: ' + header.join(', '));
      int nameIdx = -1;
      int rollIdx = -1;
      for (int i = 0; i < header.length; i++) {
        if (header[i].contains('name')) nameIdx = i;
        if (header[i].contains('roll')) rollIdx = i;
      }
      if (nameIdx == -1 || rollIdx == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel must have columns named "Roll" and "Name" (case-insensitive, not merged, not hidden). Found: ${header.join(", ")}')),
        );
        setState(() { _isLoading = false; });
        return;
      }
      // Upload each row and assign section based on index
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final name = row.length > nameIdx ? row[nameIdx]?.value?.toString()?.trim() ?? '' : '';
        final rollStr = row.length > rollIdx ? row[rollIdx]?.value?.toString()?.trim() ?? '' : '';
        if (name.isEmpty || rollStr.isEmpty) continue;
        final roll = int.tryParse(rollStr) ?? 0;
        String section;
        if (i <= 60) {
          section = 'A';
        } else if (i <= 120) {
          section = 'B';
        } else {
          section = 'C';
        }
        await FirebaseFirestore.instance
            .collection('student')
            .doc(seriesDoc)
            .collection('students')
            .doc(roll.toString())
            .set({
          'roll': roll,
          'name': name,
          'section': section,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excel data uploaded successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing Excel: $e')),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Student Data'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SizedBox(
            width: 400,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Manual Entry'),
                          value: 'manual',
                          groupValue: _uploadMode,
                          onChanged: (value) {
                            setState(() { _uploadMode = value!; });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Import from Excel'),
                          value: 'excel',
                          groupValue: _uploadMode,
                          onChanged: (value) {
                            setState(() { _uploadMode = value!; });
                          },
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: _seriesController,
                    decoration: const InputDecoration(labelText: 'Series Number'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty ? 'Enter series number' : null,
                  ),
                  const SizedBox(height: 16),
                  if (_uploadMode == 'manual') ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Student Name'),
                      validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _rollController,
                      decoration: const InputDecoration(labelText: 'Roll Number'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty ? 'Enter roll number' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sectionController,
                      decoration: const InputDecoration(labelText: 'Section'),
                      validator: (value) => value == null || value.isEmpty ? 'Enter section' : null,
                    ),
                    const SizedBox(height: 32),
                  ],
                  _isLoading
                      ? const CircularProgressIndicator()
                      : (_uploadMode == 'manual'
                          ? ElevatedButton.icon(
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Upload'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey,
                                minimumSize: const Size(150, 48),
                              ),
                              onPressed: _uploadStudent,
                            )
                          : ElevatedButton.icon(
                              icon: const Icon(Icons.file_upload),
                              label: const Text('Import from Excel'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                minimumSize: const Size(150, 48),
                              ),
                              onPressed: _importFromExcel,
                            )
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
