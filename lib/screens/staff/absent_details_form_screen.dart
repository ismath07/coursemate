import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AbsentDetailsFormScreen extends StatefulWidget {
  final DocumentSnapshot? existing;
  const AbsentDetailsFormScreen({this.existing, super.key});

  @override
  State<AbsentDetailsFormScreen> createState() => _AbsentDetailsFormScreenState();
}

class _AbsentDetailsFormScreenState extends State<AbsentDetailsFormScreen> {
  // Selected items
  Map<String, String>? _selectedHall;
  Map<String, String>? _selectedStaff;
  final List<Map<String, String>> _selectedStudents = [];

  // Controllers
  final _studentSearch = TextEditingController();
  final _studentNameCtrl = TextEditingController();
  final _regNoCtrl = TextEditingController();
  final _absentCountCtrl = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _populateExisting();
    }
  }

  Future<void> _populateExisting() async {
    final d = widget.existing!.data() as Map<String, dynamic>;

    final hallNo = d['hallNo']?.toString() ?? '';
    final staffName = d['staffName']?.toString() ?? '';
    final rawStudents = d['students'];

    // Load staff & hall docs to pre-select
    if (hallNo.isNotEmpty || staffName.isNotEmpty) {
      // Get hall list
      final hallSnap = await FirebaseFirestore.instance
          .collection('master_data')
          .doc('halls')
          .collection('items')
          .orderBy('hallNo')
          .get();
      final hallList = hallSnap.docs
          .map((d) => {'id': d.id, 'name': (d['hallNo'] ?? d.id).toString()})
          .toList();

      // Get staff list
      final staffSnap = await FirebaseFirestore.instance
          .collection('master_data')
          .doc('staff')
          .collection('items')
          .orderBy('displayName')
          .get();
      final staffList = staffSnap.docs
          .map((d) => {'id': d.id, 'name': (d['displayName'] ?? d.id).toString()})
          .toList();

      // Find matches
      if (hallNo.isNotEmpty) {
        try {
          final hall = hallList.firstWhere((h) => h['name'] == hallNo);
          _selectedHall = hall;
        } catch (e) {
          // ignore if not found
        }
      }

      if (staffName.isNotEmpty) {
        try {
          final staff = staffList.firstWhere((s) => s['name'] == staffName);
          _selectedStaff = staff;
        } catch (e) {
          // ignore if not found
        }
      }

      // Pre-populate students
      if (rawStudents is List) {
        for (final s in rawStudents) {
          if (s is Map) {
            _selectedStudents.add({
              'name': s['name']?.toString() ?? '',
              'reg': s['regNo']?.toString() ?? '',
            });
          }
        }
        _absentCountCtrl.text = _selectedStudents.length.toString();
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _studentSearch.dispose();
    _studentNameCtrl.dispose();
    _regNoCtrl.dispose();
    _absentCountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedHall == null || _selectedStaff == null || _selectedStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select hall, staff and at least one student'),
      ));
      return;
    }

    setState(() => _saving = true);

    try {
      final payload = {
        'hallNo': _selectedHall!['name'],
        'staffName': _selectedStaff!['name'],
        'students': _selectedStudents
            .map((s) => {'name': s['name'] ?? '', 'regNo': s['reg'] ?? ''})
            .toList(),
        'absentCount': _selectedStudents.length,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (widget.existing == null) {
        final snap = await FirebaseFirestore.instance
            .collection('absent_details')
            .orderBy('sno', descending: true)
            .limit(1)
            .get();
        final nextSno = snap.docs.isEmpty ? 1 : ((snap.docs.first.data()['sno'] ?? 0) + 1);
        payload['sno'] = nextSno;
        await FirebaseFirestore.instance.collection('absent_details').add(payload);
      } else {
        await FirebaseFirestore.instance
            .collection('absent_details')
            .doc(widget.existing!.id)
            .update(payload);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF0D1B6F), Color(0xFF880E4F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Add Absent Record' : 'Edit Absent Record',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 90,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        flexibleSpace: Container(decoration: gradient),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Staff Name Dropdown
            const Text('Staff Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('master_data')
                  .doc('staff')
                  .collection('items')
                  .orderBy('displayName')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return _buildDropdownFromMaps(
                    context: context,
                    label: 'Staff Name',
                    value: _selectedStaff?['id'],
                    items: [],
                    onSelect: (m) => setState(() => _selectedStaff = m),
                  );
                }
                final staffList = snapshot.data!.docs
                    .map((d) => {'id': d.id, 'name': (d['displayName'] ?? d.id).toString()})
                    .toList();
                return _buildDropdownFromMaps(
                  context: context,
                  label: 'Staff Name',
                  value: _selectedStaff?['id'],
                  items: staffList,
                  onSelect: (m) => setState(() => _selectedStaff = m),
                );
              },
            ),

            const SizedBox(height: 16),

            // Hall No Dropdown
            const Text('Hall No', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('master_data')
                  .doc('halls')
                  .collection('items')
                  .orderBy('hallNo')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return _buildDropdownFromMaps(
                    context: context,
                    label: 'Hall No',
                    value: _selectedHall?['id'],
                    items: [],
                    onSelect: (m) => setState(() => _selectedHall = m),
                  );
                }
                final hallList = snapshot.data!.docs
                    .map((d) => {'id': d.id, 'name': (d['hallNo'] ?? d.id).toString()})
                    .toList();
                return _buildDropdownFromMaps(
                  context: context,
                  label: 'Hall No',
                  value: _selectedHall?['id'],
                  items: hallList,
                  onSelect: (m) => setState(() => _selectedHall = m),
                );
              },
            ),

            const SizedBox(height: 16),

            // Student Name
            const Text('Student Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _studentNameCtrl,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Enter student name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 16),

            // Register Number
            const Text('Register Number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _regNoCtrl,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Enter register number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final name = _studentNameCtrl.text.trim();
                      final reg = _regNoCtrl.text.trim();

                      if (name.isNotEmpty && reg.isNotEmpty) {
                        setState(() {
                          _selectedStudents.add({'name': name, 'reg': reg});
                          _absentCountCtrl.text = _selectedStudents.length.toString();
                          _studentNameCtrl.clear();
                          _regNoCtrl.clear();
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Please enter both name and register number'),
                        ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Add Student'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            // Selected students
            if (_selectedStudents.isNotEmpty) ...[
              const Text('Selected Students', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _selectedStudents
                    .asMap()
                    .entries
                    .map((entry) {
                      final i = entry.key;
                      final s = entry.value;
                      return Chip(
                        label: Text('${s['name']} (${s['reg']})'),
                        onDeleted: () {
                          setState(() {
                            _selectedStudents.removeAt(i);
                            _absentCountCtrl.text = _selectedStudents.length.toString();
                          });
                        },
                      );
                    })
                    .toList(),
              ),
            ],

            const SizedBox(height: 16),
            const Text('Number of Students Absent', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              controller: _absentCountCtrl,
            ),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: InkWell(
                onTap: _saving ? null : _save,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF0D1B6F), Color(0xFF880E4F)]),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Center(
                    child: _saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            widget.existing == null ? 'ADD' : 'UPDATE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownFromMaps({
    required BuildContext context,
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required void Function(Map<String, String>?) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text('Select $label'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: BorderRadius.circular(12),
              items: items
                  .map((item) => DropdownMenuItem<String>(
                        value: item['id'],
                        child: Text(item['name'] ?? ''),
                      ))
                  .toList(),
              onChanged: (selectedId) {
                if (selectedId == null) {
                  onSelect(null);
                } else {
                  final selected = items.firstWhere(
                    (item) => item['id'] == selectedId,
                    orElse: () => <String, String>{},
                  );
                  onSelect(selected.isNotEmpty ? selected : null);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
