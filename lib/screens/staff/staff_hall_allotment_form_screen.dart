import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/year_dept_sort.dart';

class _AllocationGroup {
  Map<String, String>? selectedYearDept;
  final TextEditingController registerNoCtrl;

  _AllocationGroup({
    this.selectedYearDept,
    TextEditingController? registerNoCtrl,
  }) : registerNoCtrl = registerNoCtrl ?? TextEditingController();

  void dispose() {
    registerNoCtrl.dispose();
  }
}

class StaffHallAllotmentFormScreen extends StatefulWidget {
  final DocumentSnapshot? existing;
  const StaffHallAllotmentFormScreen({this.existing, super.key});

  @override
  State<StaffHallAllotmentFormScreen> createState() =>
      _StaffHallAllotmentFormScreenState();
}

class _StaffHallAllotmentFormScreenState
    extends State<StaffHallAllotmentFormScreen> {
  Map<String, String>? _selectedStaff;
  Map<String, String>? _selectedHall;
  DateTime? _examDate;

  final List<_AllocationGroup> _allocationGroups = [];
  final _totalStudentsCtrl = TextEditingController();

  bool _saving = false;

  String get _examDateDisplay =>
      _examDate == null ? '' : DateFormat('dd-MM-yyyy').format(_examDate!);

  Set<String> get _usedYearDeptIds {
    final ids = <String>{};
    for (final g in _allocationGroups) {
      final id = g.selectedYearDept?['id'];
      if (id != null) ids.add(id);
    }
    return ids;
  }

  @override
  void initState() {
    super.initState();
    _allocationGroups.add(_AllocationGroup());
    if (widget.existing != null) _populateExisting();
  }

  Future<void> _populateExisting() async {
    final d = widget.existing!.data() as Map<String, dynamic>;

    final staffName = d['staffName']?.toString();
    final hallNo = d['hallNo']?.toString();
    final totalStudents = d['totalStudents'] ?? 0;

    final examDateRaw = d['examDate'];
    if (examDateRaw is Timestamp) {
      _examDate = examDateRaw.toDate();
    } else if (examDateRaw is DateTime) {
      _examDate = examDateRaw;
    } else if (examDateRaw is String && examDateRaw.isNotEmpty) {
      try {
        _examDate = DateFormat('dd-MM-yyyy').parseStrict(examDateRaw);
      } catch (_) {
        try {
          _examDate = DateTime.parse(examDateRaw);
        } catch (_) {}
      }
    }

    final allocations = d['allocations'];

    final ydFutures = <Future<void>>[];

    if (allocations is List && allocations.isNotEmpty) {
      _allocationGroups.clear();
      for (int i = 0; i < allocations.length; i++) {
        final a = allocations[i];
        if (a is Map<String, dynamic>) {
          final ydName = a['yearDept']?.toString() ?? '';
          final regNosRaw = a['registerNumbers'];
          List<String> regNosList = [];
          if (regNosRaw is List) {
            regNosList = regNosRaw.map((e) => e.toString()).toList();
          }
          _allocationGroups.add(_AllocationGroup(
            registerNoCtrl:
                TextEditingController(text: regNosList.join('\n')),
          ));
          ydFutures.add(_resolveYearDeptSelection(ydName, i));
        }
      }
    } else {
      final ydName = d['yearDept']?.toString() ?? '';
      final regNosRaw = d['regNos'];
      List<String> regNosList = [];
      if (regNosRaw is List) {
        regNosList = regNosRaw.map((e) => e.toString()).toList();
      }
      if (_allocationGroups.isNotEmpty) {
        _allocationGroups[0].registerNoCtrl.text = regNosList.join('\n');
        ydFutures.add(_resolveYearDeptSelection(ydName, 0));
      }
    }

    _totalStudentsCtrl.text = totalStudents.toString();

    await Future.wait([
      _resolveStaffHallSelections(staffName, hallNo),
      ...ydFutures,
    ]);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _resolveStaffHallSelections(
      String? staffName, String? hallNo) async {
    try {
      if (staffName != null && staffName.isNotEmpty) {
        final staffSnap = await FirebaseFirestore.instance
            .collection('master_data')
            .doc('staff')
            .collection('items')
            .get();
        for (final doc in staffSnap.docs) {
          final dn = (doc['displayName'] ?? doc.id).toString();
          if (dn == staffName) {
            _selectedStaff = {'id': doc.id, 'name': dn};
            break;
          }
        }
      }
      if (hallNo != null && hallNo.isNotEmpty) {
        final hallSnap = await FirebaseFirestore.instance
            .collection('master_data')
            .doc('halls')
            .collection('items')
            .get();
        for (final doc in hallSnap.docs) {
          final hn = (doc['hallNo'] ?? doc.id).toString();
          if (hn == hallNo) {
            _selectedHall = {'id': doc.id, 'name': hn};
            break;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _resolveYearDeptSelection(String ydName, int groupIndex) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('master_data')
          .doc('year_dept')
          .collection('items')
          .get();
      for (final doc in snap.docs) {
        final dn = (doc['displayName'] ?? doc.id).toString();
        if (dn == ydName) {
          if (groupIndex < _allocationGroups.length) {
            _allocationGroups[groupIndex].selectedYearDept = {
              'id': doc.id,
              'name': dn
            };
          }
          break;
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final g in _allocationGroups) {
      g.dispose();
    }
    _totalStudentsCtrl.dispose();
    super.dispose();
  }

  void _addGroup() {
    setState(() {
      _allocationGroups.add(_AllocationGroup());
    });
  }

  void _removeGroup(int index) {
    if (_allocationGroups.length <= 1) return;
    setState(() {
      _allocationGroups[index].dispose();
      _allocationGroups.removeAt(index);
    });
  }

  List<String> _parseRegisterNumbers(String raw) {
    return raw
        .split(RegExp(r'[,\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _pickExamDate() async {
    final first = DateTime(2000);
    final last = DateTime(2100);
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate ?? DateTime.now(),
      firstDate: first,
      lastDate: last,
    );
    if (picked != null && mounted) {
      setState(() => _examDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _save() async {
    if (_examDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select Exam Date')));
      return;
    }
    if (_selectedStaff == null || _selectedHall == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select staff and hall')));
      return;
    }

    for (int i = 0; i < _allocationGroups.length; i++) {
      final g = _allocationGroups[i];
      if (g.selectedYearDept == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Please select Year/Dept for group ${i + 1}')));
        return;
      }
      final regNos = _parseRegisterNumbers(g.registerNoCtrl.text);
      if (regNos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Please enter at least one register number for group ${i + 1}')));
        return;
      }
    }

    final selectedNames = _allocationGroups
        .map((g) => g.selectedYearDept?['name'])
        .whereType<String>()
        .toList();
    final uniqueNames = selectedNames.toSet();
    if (uniqueNames.length != selectedNames.length) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Duplicate Year/Dept selection detected. '
              'Please select different Year/Dept per group.')));
      return;
    }

    final totalStudentsStr = _totalStudentsCtrl.text.trim();
    if (totalStudentsStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter total students')));
      return;
    }

    final total = int.tryParse(totalStudentsStr) ?? 0;
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Total students must be greater than 0')));
      return;
    }

    setState(() => _saving = true);

    try {
      final allocationsPayload = _allocationGroups.map((g) {
        return {
          'yearDept': g.selectedYearDept!['name'],
          'registerNumbers': _parseRegisterNumbers(g.registerNoCtrl.text),
        };
      }).toList();

      final payload = {
        'examDate': Timestamp.fromDate(_examDate!),
        'staffName': _selectedStaff!['name'],
        'hallNo': _selectedHall!['name'],
        'allocations': allocationsPayload,
        'totalStudents': total,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (widget.existing == null) {
        await FirebaseFirestore.instance
            .collection('staff_hall_allotments')
            .add(payload);
      } else {
        await FirebaseFirestore.instance
            .collection('staff_hall_allotments')
            .doc(widget.existing!.id)
            .update(payload);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving: $e')));
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
        title: Text(widget.existing == null
            ? 'Add Hall Allotment'
            : 'Edit Hall Allotment',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 90,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
        flexibleSpace: Container(decoration: gradient),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('Staff Name',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                    label: 'Staff Name',
                    value: _selectedStaff?['id'],
                    items: const [],
                    onSelect: (m) => setState(() => _selectedStaff = m),
                  );
                }
                final staffList = snapshot.data!.docs
                    .map((d) => {
                          'id': d.id,
                          'name': (d['displayName'] ?? d.id).toString()
                        })
                    .toList();
                return _buildDropdownFromMaps(
                  label: 'Staff Name',
                  value: _selectedStaff?['id'],
                  items: staffList,
                  onSelect: (m) => setState(() => _selectedStaff = m),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text('Hall No',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                    label: 'Hall No',
                    value: _selectedHall?['id'],
                    items: const [],
                    onSelect: (m) => setState(() => _selectedHall = m),
                  );
                }
                final hallList = snapshot.data!.docs
                    .map((d) =>
                        {'id': d.id, 'name': (d['hallNo'] ?? d.id).toString()})
                    .toList();
                return _buildDropdownFromMaps(
                  label: 'Hall No',
                  value: _selectedHall?['id'],
                  items: hallList,
                  onSelect: (m) => setState(() => _selectedHall = m),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text('Exam Date',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickExamDate,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 18, color: Colors.grey.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _examDateDisplay.isEmpty
                            ? 'Select Exam Date'
                            : _examDateDisplay,
                        style: TextStyle(
                          fontSize: 14,
                          color: _examDateDisplay.isEmpty
                              ? Colors.grey.shade600
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ..._buildAllocationGroups(),
            const SizedBox(height: 20),
            const Text('Total Students',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _totalStudentsCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Enter total number of students',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: InkWell(
                onTap: _saving ? null : _save,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF0D1B6F), Color(0xFF880E4F)]),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Center(
                    child: _saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(widget.existing == null ? 'ADD' : 'UPDATE',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAllocationGroups() {
    final widgets = <Widget>[];
    for (int i = 0; i < _allocationGroups.length; i++) {
      widgets.add(_buildAllocationGroup(i));
      widgets.add(const SizedBox(height: 12));
      widgets.add(Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => _addGroup(),
          icon: const Icon(Icons.add_box_outlined, size: 18),
          label: const Text('Add Another Year/Dept',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF0D1B6F),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ));
      widgets.add(const SizedBox(height: 16));
    }
    return widgets;
  }

  Widget _buildAllocationGroup(int index) {
    final group = _allocationGroups[index];
    final canRemove = _allocationGroups.length > 1;
    final usedIds = _usedYearDeptIds;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Year/Dept ${index + 1}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D1B6F)),
                ),
              ),
              if (canRemove)
                TextButton.icon(
                  onPressed: () => _removeGroup(index),
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: Colors.red),
                  label: const Text('Remove',
                      style: TextStyle(fontSize: 12, color: Colors.red)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Year/Dept',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('master_data')
                .doc('year_dept')
                .collection('items')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return _buildDropdownFromMaps(
                  label: 'Year/Dept',
                  value: group.selectedYearDept?['id'],
                  items: const [],
                  onSelect: (m) => setState(() {
                    group.selectedYearDept = m;
                  }),
                );
              }
              final sortedDocs =
                  YearDeptSort.sortDocuments(snapshot.data!.docs);
              final fullList = sortedDocs
                  .map((d) => {
                        'id': d.id,
                        'name':
                            (d['displayName'] ?? d.id).toString()
                      })
                  .toList();

              final filteredList = fullList.where((item) {
                final id = item['id'];
                final currentId = group.selectedYearDept?['id'];
                if (id == currentId) return true;
                return !usedIds.contains(id);
              }).toList();

              return _buildDropdownFromMaps(
                label: 'Year/Dept',
                value: group.selectedYearDept?['id'],
                items: filteredList,
                onSelect: (m) => setState(() {
                  group.selectedYearDept = m;
                }),
              );
            },
          ),
          const SizedBox(height: 12),
          const Text('Register Numbers',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: group.registerNoCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText:
                  'Enter one register number per line or comma separated',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFromMaps({
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required void Function(Map<String, String>?) onSelect,
  }) {
    return Container(
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
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
    );
  }
}
