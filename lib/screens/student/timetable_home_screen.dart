import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'view_hall_allotment_screen.dart';
import '../staff/select_degree_exam_timetable_screen.dart';
import '../staff/view_exam_timetable_screen.dart';
import '../shared/select_semester_overall_screen.dart';


class TimetableHomeScreen extends StatefulWidget {
  const TimetableHomeScreen({super.key});

  @override
  State<TimetableHomeScreen> createState() => _TimetableHomeScreenState();
}

class _TimetableHomeScreenState extends State<TimetableHomeScreen> {
  String? selectedDegree;
  String? selectedDegreeName;
  String? selectedSemester; // 'ODD' or 'EVEN'
  String? selectedDepartment;
  String? selectedDepartmentName;
  String? selectedYear;
  String? selectedYearName;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _searchTimetable() async {
    if (selectedDegree == null || selectedSemester == null || selectedDepartment == null || selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all fields')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewExamTimetableScreen(
          degreeId: selectedDegree!,
          degreeName: selectedDegreeName ?? selectedDegree!,
          departmentId: selectedDepartment!,
          departmentName: selectedDepartmentName ?? selectedDepartment!,
          yearId: selectedYear!,
          yearName: selectedYearName ?? selectedYear!,
          semesterType: selectedSemester!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            Text(
              'Select Timetable Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 20),

            _card(
              context,
              icon: Icons.description_outlined,
              title: 'Exam Timetable',
              subtitle: 'View UG / PG exam schedule',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SelectDegreeExamTimetableScreen()),
                );
               
                // TODO: Navigate to Exam Timetable
              },
            ),

            const SizedBox(height: 16),

            _card(
              context,
              icon: Icons.apartment_outlined,
              title: 'Hall Allotment',
              subtitle: 'Check exam hall details',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentViewHallAllotmentScreen()),
                );
              },
            ),

            const SizedBox(height: 16),

            _card(
              context,
              icon: Icons.table_chart_outlined,
              title: 'Overall Exam Timetable',
              subtitle: 'View all timetables by semester',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SelectSemesterOverallScreen()),
                );
              },
            ),

            const SizedBox(height: 40),

            // Find Exam Timetable Section
            Text(
              'Find Exam Timetable',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 20),

            // Degree Dropdown
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('exam_timetables')
                  .orderBy('displayName')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return _buildDropdown(context: context, label: 'Degree', value: null, items: [], onChanged: null);
                }

                final degrees = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {'id': doc.id, 'name': (data['displayName'] ?? doc.id).toString()};
                }).toList();

                if (selectedDegree != null && !degrees.any((d) => d['id'] == selectedDegree)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      selectedDegree = null; selectedDegreeName = null;
                      selectedSemester = null;
                      selectedDepartment = null; selectedDepartmentName = null;
                      selectedYear = null; selectedYearName = null;
                    });
                  });
                }

                return _buildDropdown(
                  context: context,
                  label: 'Degree',
                  value: selectedDegree,
                  items: degrees,
                  onChanged: (value) {
                    final name = degrees.firstWhere((d) => d['id'] == value, orElse: () => {'name': value ?? ''})['name'];
                    setState(() {
                      selectedDegree = value; selectedDegreeName = name;
                      selectedSemester = null;
                      selectedDepartment = null; selectedDepartmentName = null;
                      selectedYear = null; selectedYearName = null;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            // Semester Dropdown
            _buildDropdown(
              context: context,
              label: 'Semester',
              value: selectedSemester,
              items: selectedDegree == null
                  ? []
                  : [
                      {'id': 'ODD', 'name': 'ODD SEMESTER'},
                      {'id': 'EVEN', 'name': 'EVEN SEMESTER'},
                    ],
              onChanged: selectedDegree == null
                  ? null
                  : (value) {
                      setState(() {
                        selectedSemester = value;
                        selectedDepartment = null; selectedDepartmentName = null;
                        selectedYear = null; selectedYearName = null;
                      });
                    },
            ),

            const SizedBox(height: 16),

            // Department Dropdown — queries semesters/{semesterType}/departments
            if (selectedDegree != null && selectedSemester != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('exam_timetables')
                    .doc(selectedDegree)
                    .collection('semesters')
                    .doc(selectedSemester)
                    .collection('departments')
                    .orderBy('displayName')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _buildDropdown(context: context, label: 'Department', value: null, items: [], onChanged: null);
                  }

                  final departments = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return {'id': doc.id, 'name': (data['displayName'] ?? doc.id).toString()};
                  }).toList();

                  if (selectedDepartment != null && !departments.any((d) => d['id'] == selectedDepartment)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        selectedDepartment = null; selectedDepartmentName = null;
                        selectedYear = null; selectedYearName = null;
                      });
                    });
                  }

                  return _buildDropdown(
                    context: context,
                    label: 'Department',
                    value: selectedDepartment,
                    items: departments,
                    onChanged: (value) {
                      final name = departments.firstWhere((d) => d['id'] == value, orElse: () => {'name': value ?? ''})['name'];
                      setState(() {
                        selectedDepartment = value; selectedDepartmentName = name;
                        selectedYear = null; selectedYearName = null;
                      });
                    },
                  );
                },
              )
            else
              _buildDropdown(context: context, label: 'Department', value: null, items: [], onChanged: null),

            const SizedBox(height: 16),

            // Year Dropdown — queries semesters/{semesterType}/departments/{deptId}/years
            if (selectedDegree != null && selectedSemester != null && selectedDepartment != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('exam_timetables')
                    .doc(selectedDegree)
                    .collection('semesters')
                    .doc(selectedSemester)
                    .collection('departments')
                    .doc(selectedDepartment)
                    .collection('years')
                    .orderBy('displayName')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _buildDropdown(context: context, label: 'Year', value: null, items: [], onChanged: null);
                  }

                  final years = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return {'id': doc.id, 'name': (data['displayName'] ?? doc.id).toString()};
                  }).toList();

                  if (selectedYear != null && !years.any((y) => y['id'] == selectedYear)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() { selectedYear = null; selectedYearName = null; });
                    });
                  }

                  return _buildDropdown(
                    context: context,
                    label: 'Year',
                    value: selectedYear,
                    items: years,
                    onChanged: (value) {
                      final name = years.firstWhere((y) => y['id'] == value, orElse: () => {'name': value ?? ''})['name'];
                      setState(() { selectedYear = value; selectedYearName = name; });
                    },
                  );
                },
              )
            else
              _buildDropdown(context: context, label: 'Year', value: null, items: [], onChanged: null),

            const SizedBox(height: 24),

            // Search Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _searchTimetable,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Search',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

  Widget _buildDropdown({
    required BuildContext context,
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required void Function(String?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
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
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item['id'],
                  child: Text(item['name']!),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
