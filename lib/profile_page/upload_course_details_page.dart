import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';

class UploadCourseDetailsPage extends StatefulWidget {
  const UploadCourseDetailsPage({super.key});

  @override
  State<UploadCourseDetailsPage> createState() => _UploadCourseDetailsPageState();
}

class _UploadCourseDetailsPageState extends State<UploadCourseDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _creditController = TextEditingController();
  bool _isLoading = false;
  String _uploadMode = 'manual'; // 'manual' or 'excel'

  Future<void> _uploadCourse() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    try {
      await FirebaseFirestore.instance.collection('courses').doc(_codeController.text.trim()).set({
        'code': _codeController.text.trim(),
        'name': _nameController.text.trim(),
        'credit': double.tryParse(_creditController.text.trim()) ?? 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course details uploaded successfully!')),
      );
      _codeController.clear();
      _nameController.clear();
      _creditController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading course: ${e.toString()}')),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _importFromExcel() async {
    setState(() { _isLoading = true; });
    try {
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
      // Find column indexes for code, name, credit
      final header = sheet.rows.first.map((cell) {
        if (cell == null || cell.value == null) return '';
        return cell.value.toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
      }).toList();
      int codeIdx = -1;
      int nameIdx = -1;
      int creditIdx = -1;
      for (int i = 0; i < header.length; i++) {
        if (header[i].contains('code')) codeIdx = i;
        if (header[i].contains('name')) nameIdx = i;
        if (header[i].contains('credit')) creditIdx = i;
      }
      if (codeIdx == -1 || nameIdx == -1 || creditIdx == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel must have columns named "Code", "Name", and "Credit".')),
        );
        setState(() { _isLoading = false; });
        return;
      }
      // Upload each row
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final code = row.length > codeIdx ? row[codeIdx]?.value?.toString()?.trim() ?? '' : '';
        final name = row.length > nameIdx ? row[nameIdx]?.value?.toString()?.trim() ?? '' : '';
        final creditStr = row.length > creditIdx ? row[creditIdx]?.value?.toString()?.trim() ?? '' : '';
        if (code.isEmpty || name.isEmpty || creditStr.isEmpty) continue;
        final credit = double.tryParse(creditStr) ?? 0.0;
        await FirebaseFirestore.instance.collection('courses').doc(code).set({
          'code': code,
          'name': name,
          'credit': credit,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excel course data uploaded successfully!')),
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
        title: const Text('Upload Course Details'),
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
                  if (_uploadMode == 'manual') ...[
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(labelText: 'Course Code'),
                      validator: (value) => value == null || value.isEmpty ? 'Enter course code' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Course Name'),
                      validator: (value) => value == null || value.isEmpty ? 'Enter course name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _creditController,
                      decoration: const InputDecoration(labelText: 'Credit'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty ? 'Enter credit' : null,
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
                              onPressed: _uploadCourse,
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
