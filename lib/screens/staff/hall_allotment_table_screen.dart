import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class HallAllotmentTableScreen extends StatelessWidget {
  final String degreeId;
  final String degreeName;
  const HallAllotmentTableScreen({super.key, required this.degreeId, required this.degreeName});

  static const String _examId = 'nov_2025';

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    debugPrint('🟢 HallAllotmentTableScreen');
  debugPrint('➡️ degreeId = $degreeId');
  debugPrint('➡️ degreeName = $degreeName');
  debugPrint('➡️ examId = $_examId');
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('View Hall Allotment', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 90,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D1B6F), Color(0xFF880E4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              degreeName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: firestoreService.getHallAllotmentRows(
  degreeId: degreeId,
  examId: _examId,
),

                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Failed to load hall allotments.'));
                  }
                  final rows = snapshot.data ?? [];
                  if (rows.isEmpty) {
                    return const Center(child: Text('No data available'));
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Sno')),
                          DataColumn(label: Text('Year/Dept')),
                          DataColumn(label: Text('Register Numbers')),
                          DataColumn(label: Text('HallNo')),
                        ],
                        rows: rows.map((row) {
                          final sno = row['sno']?.toString() ?? '';
                          final yearDept = (row['yearDept'] is List)
                              ? (row['yearDept'] as List).map((e) => e.toString()).join('\n')
                              : '';
                          final regNos = (row['regNumbers'] is List)
                              ? (row['regNumbers'] as List).map((e) => e.toString()).join('\n')
                              : '';

                          final hallNo = row['hallNo']?.toString() ?? '';    
                          return DataRow(
                            cells: [
                              DataCell(Text(sno)),
                              DataCell(Text(yearDept)),
                              DataCell(Text(regNos)),
                              DataCell(Text(hallNo)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
