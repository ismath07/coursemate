import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

// Helper function to get the priority of a unit key
int _getUnitPriority(String key) {
  final lowerKey = key.toLowerCase();
  
  // Course Objective: priority 0
  if (lowerKey.contains('course') && lowerKey.contains('objective')) {
    return 0;
  }
  
  // Unit X: priority X
  final unitMatch = RegExp(r'unit[^\d]*(\d+)').firstMatch(lowerKey);
  if (unitMatch != null) {
    final unitNumber = int.tryParse(unitMatch.group(1)!);
    if (unitNumber != null) {
      return unitNumber;
    }
  }
  
  // Reference/References: priority 999
  if (lowerKey.contains('reference')) {
    return 999;
  }
  
  // Unknown: priority 998
  return 998;
}

// Helper function to get the display label for a unit key
String _getUnitLabel(String key) {
  final lowerKey = key.toLowerCase();
  
  // Course Objective
  if (lowerKey.contains('course') && lowerKey.contains('objective')) {
    return 'Course Objectives';
  }
  
  // Unit X
  final unitMatch = RegExp(r'unit[^\d]*(\d+)').firstMatch(lowerKey);
  if (unitMatch != null) {
    final unitNumber = int.tryParse(unitMatch.group(1)!);
    if (unitNumber != null) {
      return 'UNIT $unitNumber';
    }
  }
  
  // Reference/References
  if (lowerKey.contains('reference')) {
    return 'Reference';
  }
  
  // Keep as is
  return key;
}

// Helper function to sort units and return ordered entries
List<MapEntry<String, dynamic>> _sortSyllabusUnits(Map<String, dynamic> units) {
  final entries = units.entries.toList();
  entries.sort((a, b) => _getUnitPriority(a.key).compareTo(_getUnitPriority(b.key)));
  return entries.map((e) => MapEntry(_getUnitLabel(e.key), e.value)).toList();
}

class PdfService {
  // ─── College constants ────────────────────────────────────────────────────
  static const _collegeName =
      'RABIAMMAL AHAMED MAIDEEN COLLEGE FOR WOMEN, THIRUVARUR';
  static const _collegeLines = [
    '(Affiliated to Bharathidasan University, Tiruchirappalli)',
    'An Institution formed under the Article 30(1) of Constitution of India',
    'Recognized Under Section 2(f) & 12(B) of the UGC Act, 1956',
    'VASAN NAGAR, TIRUVARUR - 610 001, TAMILNADU, S. INDIA',
  ];

  // ─── Shared college header widget ────────────────────────────────────────
  static pw.Widget _buildCollegeHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          _collegeName,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        ..._collegeLines.map(
          (line) => pw.Text(
            line,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 1),
      ],
    );
  }

  // ─── Shared title + meta section ─────────────────────────────────────────
  static pw.Widget _buildTitleSection({
    required String title,
    String? course,
    String? year,
    String? subject,
    String? subjectCode,
    String? semester,
  }) {
    final generated =
        DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(height: 8),
        pw.Text(
          title.toUpperCase(),
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        if (subject != null)
          pw.Text('Subject: $subject',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 10)),
        if (subjectCode != null)
          pw.Text('Subject Code: $subjectCode',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 10)),
        if (course != null)
          pw.Text('Course: $course',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 10)),
        if (year != null)
          pw.Text('Year: $year',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 10)),
        if (semester != null)
          pw.Text('Semester: $semester',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 10)),
        pw.Text('Generated: $generated',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 9)),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 10),
      ],
    );
  }

  // ─── Shared table builder (MultiPage-aware, used by other PDF methods) ────
  static pw.Widget _buildTable(List<List<String>> tableData) {
    if (tableData.isEmpty) return pw.Text('No data available');
    final headers = tableData.first;
    final rows = tableData.sublist(1);

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
      ),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      headerAlignment: pw.Alignment.center,
      cellAlignment: pw.Alignment.centerLeft,
      border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    );
  }

  // ─── Row-based table widgets for Overall PDF (MultiPage-safe) ─────────────
  // Instead of a single pw.Table (which is fixed-size and splits if too tall),
  // we emit individual row widgets into the MultiPage build list.
  // MultiPage flows them naturally across pages. The header widget is emitted
  // only once per year — it is never repeated because it is just a plain widget.

  // Fixed column flex ratios matching A4 content width (≈539pt after margins)
  static const _colFlex = [12, 9, 30, 14, 9]; // Date, Day, Subject, Code, Session

  static pw.Widget _tableHeaderRow() {
    const labels = ['Date', 'Day', 'Course Name', 'Course Code', 'Session'];
    return pw.Container(
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey300,
        border: pw.Border(
          top: pw.BorderSide(width: 0.5, color: PdfColors.grey600),
          bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey600),
        ),
      ),
      child: pw.Row(
        children: List.generate(labels.length, (i) => pw.Expanded(
          flex: _colFlex[i],
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(
                    width: i == 0 ? 0.5 : 0, color: PdfColors.grey600),
                right: const pw.BorderSide(width: 0.5, color: PdfColors.grey600),
              ),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            child: pw.Text(
              labels[i],
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            ),
          ),
        )),
      ),
    );
  }

  static pw.Widget _tableDataRow(List<String> cells, {bool isLast = false}) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: isLast ? 0.5 : 0.3, color: PdfColors.grey600),
        ),
      ),
      child: pw.Row(
        children: List.generate(cells.length, (i) => pw.Expanded(
          flex: _colFlex[i],
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(
                    width: i == 0 ? 0.5 : 0, color: PdfColors.grey600),
                right: const pw.BorderSide(width: 0.5, color: PdfColors.grey600),
              ),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            child: pw.Text(cells[i], style: const pw.TextStyle(fontSize: 9)),
          ),
        )),
      ),
    );
  }

  // ─── Permission helper ────────────────────────────────────────────────────
  static Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidVersion =
          int.tryParse(Platform.version.split('.').first) ?? 0;
      if (androidVersion >= 33) return true;
      if (androidVersion >= 30) {
        final status = await Permission.manageExternalStorage.request();
        if (status.isGranted) return true;
      }
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  // ─── Download directory helper ────────────────────────────────────────────
  static Future<Directory?> getDownloadDirectory() async {
    try {
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) return downloadDir;

        final downloadsDir = Directory('/storage/emulated/0/Downloads');
        if (await downloadsDir.exists()) return downloadsDir;

        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final folder = Directory('${externalDir.path}/Downloads');
          if (!await folder.exists()) await folder.create(recursive: true);
          return folder;
        }
      }
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return null;
    }
  }

  // ─── Core save helper ─────────────────────────────────────────────────────
  static Future<String?> _savePdf(pw.Document pdf, String fileName) async {
    final directory = await getDownloadDirectory();
    if (directory == null) return null;

    final safeFileName =
        '${fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}_'
        '${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$safeFileName');

    final bytes = await pdf.save();
    await file.writeAsBytes(bytes, flush: true);
    return await file.exists() ? file.path : null;
  }


  // ─── Exam Timetable PDF ───────────────────────────────────────────────────
  static Future<String?> generateExamTimetablePDF({
    required String courseName,
    required String year,
    String semester = '',
    required List<Map<String, dynamic>> timetableData,
  }) async {
    try {
      if (!await requestPermission()) return null;

      final tableData = [
        ['Date', 'Day', 'Course Name', 'Course Code', 'Session'],
        ...timetableData.map((item) => [
              item['date']?.toString() ?? '',
              item['day']?.toString() ?? '',
              item['subject']?.toString() ?? '',
              item['subjectCode']?.toString() ?? '',
              item['session']?.toString() ?? '',
            ]),
      ];

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          build: (context) => [
            _buildCollegeHeader(),
            _buildTitleSection(
              title: 'Exam Timetable',
              course: courseName,
              semester: semester.isNotEmpty ? semester : null,
              year: year,
            ),
            _buildTable(tableData),
          ],
        ),
      );

      return await _savePdf(pdf, 'Exam_Timetable');
    } catch (_) {
      return null;
    }
  }

  // ─── Hall Allotment PDF (Hall Allotment screen - no staff name) ────────────────
  // Columns: S.No | Exam Date | Hall No | Year/Dept | Register Numbers | Total
  static Future<String?> generateHallAllotmentPDF({
    required String title,
    required List<Map<String, dynamic>> hallData,
  }) async {
    try {
      if (!await requestPermission()) return null;

      const border = pw.BorderSide(width: 0.5, color: PdfColors.grey600);
      const headerBg = PdfColors.grey300;

      pw.Widget txt(String t, {bool bold = false}) => pw.Text(
            t,
            style: bold
                ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)
                : const pw.TextStyle(fontSize: 9),
          );

      // Multi-line cell: stacks each item on its own line
      pw.Widget multiTxt(List<String> lines) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (final line in lines)
                pw.Text(line, style: const pw.TextStyle(fontSize: 9))
            ],
          );

      // Build table rows
      final tableRows = <List<pw.Widget>>[];

      // Header row
      tableRows.add([
        pw.Text('S.No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
        pw.Text('Exam Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
        pw.Text('Hall No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
        pw.Text('Year / Dept', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
        pw.Text('Register Numbers', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
        pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
      ]);

      // Data rows
      for (final item in hallData) {
        final yearDepts = item['yearDepts'] ?? [];
        final regNosGroups = item['regNosGroups'] ?? [];

        final yearLines = yearDepts is List && yearDepts.isNotEmpty
            ? yearDepts
                .map((e) => e?.toString() ?? '')
                .where((e) => e.isNotEmpty)
                .toList()
            : ['-'];

        final regLines = regNosGroups is List && regNosGroups.isNotEmpty
            ? regNosGroups
                .map((e) => e?.toString() ?? '')
                .where((e) => e.isNotEmpty)
                .toList()
            : ['-'];

        tableRows.add([
          txt(item['sno']?.toString() ?? ''),
          txt(item['examDate']?.toString() ?? '-'),
          txt(item['hallNo']?.toString() ?? ''),
          multiTxt(yearLines),
          multiTxt(regLines),
          txt(item['totalStudents']?.toString() ?? ''),
        ]);
      }

      // Build table with proper borders
      final table = pw.Table(
        border: pw.TableBorder(
          left: border,
          right: border,
          top: border,
          bottom: border,
          horizontalInside: border,
          verticalInside: border,
        ),
        columnWidths: {
          0: const pw.FlexColumnWidth(1),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(1.5),
          3: const pw.FlexColumnWidth(3),
          4: const pw.FlexColumnWidth(4),
          5: const pw.FlexColumnWidth(1),
        },
        children: [
          // Header row
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: headerBg),
            children: tableRows[0]
                .map((cell) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: cell,
                    ))
                .toList(),
          ),
          // Data rows
          ...tableRows.skip(1).map((row) => pw.TableRow(
                children: row
                    .map((cell) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: cell,
                        ))
                    .toList(),
              )),
        ],
      );

      // ── Assemble ─────────────────────────────────────────────────────────
      final List<pw.Widget> content = [
        _buildCollegeHeader(),
        _buildTitleSection(title: title),
        pw.SizedBox(height: 8),
        table,
      ];

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          build: (_) => content,
        ),
      );

      return await _savePdf(pdf, title);
    } catch (e) {
      print('Hall Allotment PDF Error: $e');
      return null;
    }
  }

  // ─── Staff Hall Allotment PDF (Faculty Hall Allotment screen - with staff name) ──
  // Columns: S.No | Exam Date | Faculty Name | Hall No | Year/Dept | Register Numbers | Total
  static Future<String?> generateStaffHallAllotmentPDF({
    required String title,
    required List<Map<String, dynamic>> hallData,
    bool excludeStaff = false,
  }) async {
    try {
      if (!await requestPermission()) return null;

      const border = pw.BorderSide(width: 0.5, color: PdfColors.grey600);
      const headerBg = PdfColors.grey300;

      pw.Widget txt(String t, {bool bold = false}) => pw.Text(
            t,
            style: bold
                ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)
                : const pw.TextStyle(fontSize: 9),
          );

      // Multi-line cell: stacks each item on its own line
      pw.Widget multiTxt(List<String> lines) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (final line in lines)
                pw.Text(line, style: const pw.TextStyle(fontSize: 9))
            ],
          );

      // Build table rows
      final tableRows = <List<pw.Widget>>[];

      // Header row
      if (excludeStaff) {
        // 6 columns: S.No | Exam Date | Hall No | Year/Dept | Register Numbers | Total
        tableRows.add([
          pw.Text('S.No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          pw.Text('Exam Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          pw.Text('Hall No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          pw.Text('Year / Dept', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          pw.Text('Register Numbers', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
        ]);
      } else {
        // 7 columns: S.No | Exam Date | Faculty Name | Hall No | Year/Dept | Register Numbers | Total
        tableRows.add([
          pw.Text('S.No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          pw.Text('Exam Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          pw.Text('Faculty Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          pw.Text('Hall No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          pw.Text('Year / Dept', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          pw.Text('Register Numbers', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
        ]);
      }

      // Data rows
      for (final item in hallData) {
        final yearDepts = item['yearDepts'] ?? [];
        final regNosGroups = item['regNosGroups'] ?? [];

        final yearLines = yearDepts is List && yearDepts.isNotEmpty
            ? yearDepts
                .map((e) => e?.toString() ?? '')
                .where((e) => e.isNotEmpty)
                .toList()
            : ['-'];

        final regLines = regNosGroups is List && regNosGroups.isNotEmpty
            ? regNosGroups
                .map((e) => e?.toString() ?? '')
                .where((e) => e.isNotEmpty)
                .toList()
            : ['-'];

        if (excludeStaff) {
          // 6 columns
          tableRows.add([
            txt(item['sno']?.toString() ?? ''),
            txt(item['examDate']?.toString() ?? '-'),
            txt(item['hallNo']?.toString() ?? ''),
            multiTxt(yearLines),
            multiTxt(regLines),
            txt(item['totalStudents']?.toString() ?? ''),
          ]);
        } else {
          // 7 columns
          tableRows.add([
            txt(item['sno']?.toString() ?? ''),
            txt(item['examDate']?.toString() ?? '-'),
            txt(item['staffName']?.toString() ?? ''),
            txt(item['hallNo']?.toString() ?? ''),
            multiTxt(yearLines),
            multiTxt(regLines),
            txt(item['totalStudents']?.toString() ?? ''),
          ]);
        }
      }

      // Build table with proper borders
      late final pw.Table table;

      if (excludeStaff) {
        // 6-column table
        table = pw.Table(
          border: pw.TableBorder(
            left: border,
            right: border,
            top: border,
            bottom: border,
            horizontalInside: border,
            verticalInside: border,
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(3),
            4: const pw.FlexColumnWidth(4),
            5: const pw.FlexColumnWidth(1),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: headerBg),
              children: tableRows[0]
                  .map((cell) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: cell,
                      ))
                  .toList(),
            ),
            // Data rows
            ...tableRows.skip(1).map((row) => pw.TableRow(
                  children: row
                      .map((cell) => pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: cell,
                          ))
                      .toList(),
                )),
          ],
        );
      } else {
        // 7-column table
        table = pw.Table(
          border: pw.TableBorder(
            left: border,
            right: border,
            top: border,
            bottom: border,
            horizontalInside: border,
            verticalInside: border,
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2.5),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(3),
            5: const pw.FlexColumnWidth(4),
            6: const pw.FlexColumnWidth(1),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: headerBg),
              children: tableRows[0]
                  .map((cell) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: cell,
                      ))
                  .toList(),
            ),
            // Data rows
            ...tableRows.skip(1).map((row) => pw.TableRow(
                  children: row
                      .map((cell) => pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: cell,
                          ))
                      .toList(),
                )),
          ],
        );
      }

      // ── Assemble ─────────────────────────────────────────────────────────
      final List<pw.Widget> content = [
        _buildCollegeHeader(),
        _buildTitleSection(title: title),
        pw.SizedBox(height: 8),
        table,
      ];

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          build: (_) => content,
        ),
      );

      return await _savePdf(pdf, title);
    } catch (e) {
      print('Staff Hall Allotment PDF Error: $e');
      return null;
    }
  }

  // ─── Syllabus PDF ─────────────────────────────────────────────────────────
  static Future<String?> generateSyllabusPDF({
    required String subjectName,
    required String subjectCode,
    required String course,
    required String semester,
    required Map<String, dynamic> syllabusData,
  }) async {
    try {
      if (!await requestPermission()) return null;

      // Canonical syllabus order using custom sorting
      final orderedEntries = _sortSyllabusUnits(syllabusData);

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          build: (context) => [
            _buildCollegeHeader(),
            _buildTitleSection(
              title: 'Syllabus',
              subject: subjectName,
              subjectCode: subjectCode,
              course: course,
              semester: semester,
            ),
            ...orderedEntries.map((entry) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      entry.key,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      entry.value.toString(),
                      style: const pw.TextStyle(fontSize: 10),
                      textAlign: pw.TextAlign.justify,
                    ),
                    pw.SizedBox(height: 12),
                  ],
                )),
          ],
        ),
      );

      return await _savePdf(pdf, 'Syllabus_$subjectCode');
    } catch (_) {
      return null;
    }
  }

  // ─── Overall Exam Timetable PDF ──────────────────────────────────────────
  /// Generates one continuous PDF report for a semester.
  ///
  /// Layout rules:
  /// - Degree heading printed once per degree.
  /// - Department name printed once per department.
  /// - Year label + table header row printed once per year.
  /// - Data rows flow across pages naturally via MultiPage.
  /// - When a page break falls mid-table, rows continue on the next page
  ///   WITHOUT repeating the degree, department, or table header.
  ///
  /// [semesterType]  'ODD' or 'EVEN'
  /// [degreeGroups]  tree: degrees → departments → years → exams
  static Future<String?> generateOverallExamTimetablePDF({
    required String semesterType,
    required List<Map<String, dynamic>> degreeGroups,
  }) async {
    try {
      if (!await requestPermission()) return null;

      final pdf = pw.Document();

      // Build a single flat list of widgets for MultiPage.
      // MultiPage flows these across pages without repeating any of them.
      final List<pw.Widget> content = [];

      // ── Title ─────────────────────────────────────────────────────────────
      content.add(_buildCollegeHeader());
      content.add(_buildTitleSection(
        title: 'Overall Exam Timetable',
        semester: '$semesterType SEMESTER',
      ));

      for (final degreeGroup in degreeGroups) {
        final degreeName = degreeGroup['degreeName'] as String;
        final departments =
            degreeGroup['departments'] as List<Map<String, dynamic>>;

        // ── Degree heading — emitted ONCE ─────────────────────────────────
        content.add(pw.SizedBox(height: 10));
        content.add(
          pw.Container(
            width: double.infinity,
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration:
                const pw.BoxDecoration(color: PdfColors.blueGrey800),
            child: pw.Text(
              degreeName.toUpperCase(),
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        );

        for (final dept in departments) {
          final deptName = dept['deptName'] as String;
          final years = dept['years'] as List<Map<String, dynamic>>;

          // ── Department heading — emitted ONCE ───────────────────────────
          content.add(pw.SizedBox(height: 8));
          content.add(
            pw.Text(
              deptName,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey700,
              ),
            ),
          );

          for (final yearEntry in years) {
            final yearName = yearEntry['yearName'] as String;
            final exams =
                yearEntry['exams'] as List<Map<String, dynamic>>;

            if (exams.isEmpty) continue;

            // ── Year label — emitted ONCE ──────────────────────────────────
            content.add(pw.SizedBox(height: 6));
            content.add(
              pw.Text(
                yearName,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
            );
            content.add(pw.SizedBox(height: 3));

            // ── Table header row — emitted ONCE per year ───────────────────
            content.add(_tableHeaderRow());

            // ── Data rows — flow across pages without repeating the header ──
            for (int i = 0; i < exams.length; i++) {
              final e = exams[i];
              content.add(_tableDataRow(
                [
                  e['date']?.toString() ?? '',
                  e['day']?.toString() ?? '',
                  e['subject']?.toString() ?? '',
                  e['subjectCode']?.toString() ?? '',
                  e['session']?.toString() ?? '',
                ],
                isLast: i == exams.length - 1,
              ));
            }

            content.add(pw.SizedBox(height: 4));
          }

          // Thin divider between departments
          content.add(
            pw.Divider(thickness: 0.5, color: PdfColors.grey400),
          );
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin:
              const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          build: (_) => content,
        ),
      );

      return await _savePdf(pdf, 'Overall_Exam_Timetable_$semesterType');
    } catch (_) {
      return null;
    }
  }

  // ─── Absent Details PDF ──────────────────────────────────────────────────
  /// Columns: S.No | Hall No | No. Absent | Student Names | Reg Nos | Staff
  /// Student names and reg numbers are stacked vertically inside their cells.
  /// Rows flow across pages via MultiPage; the header is emitted only once.
  static Future<String?> generateAbsentDetailsPDF({
    required List<Map<String, dynamic>> records,
  }) async {
    try {
      if (!await requestPermission()) return null;

      // Column flex weights (A4 content ≈ 539pt, margins 28×2)
      // S.No | Hall No | Count | Student Name | Reg No | Staff
      const flex = [5, 8, 8, 22, 18, 18];

      const pad = pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5);
      const border = pw.BorderSide(width: 0.5, color: PdfColors.grey600);

      // ── Single cell wrapper ──────────────────────────────────────────────
      pw.Widget cell({
        required int col,
        required pw.Widget child,
        bool isHeader = false,
      }) {
        return pw.Expanded(
          flex: flex[col],
          child: pw.Container(
            decoration: pw.BoxDecoration(
              color: isHeader ? PdfColors.grey300 : null,
              border: pw.Border(
                left: col == 0 ? border : pw.BorderSide.none,
                right: border,
              ),
            ),
            padding: pad,
            child: child,
          ),
        );
      }

      pw.Widget txt(String t, {bool bold = false}) => pw.Text(
            t,
            style: bold
                ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)
                : const pw.TextStyle(fontSize: 9),
          );

      // ── Header row (emitted once) ────────────────────────────────────────
      pw.Widget headerRow() => pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: border,
                bottom: border,
              ),
            ),
            child: pw.Row(children: [
              cell(col: 0, child: txt('S.No', bold: true), isHeader: true),
              cell(col: 1, child: txt('Hall No', bold: true), isHeader: true),
              cell(col: 2, child: txt('No.\nAbsent', bold: true), isHeader: true),
              cell(col: 3, child: txt('Student Name', bold: true), isHeader: true),
              cell(col: 4, child: txt('Register Number', bold: true), isHeader: true),
              cell(col: 5, child: txt('Staff Name', bold: true), isHeader: true),
            ]),
          );

      // ── Data row builder ─────────────────────────────────────────────────
      pw.Widget dataRow(Map<String, dynamic> rec, {required bool isLast}) {
        final sno = (rec['sno'] ?? '').toString();
        final hallNo = (rec['hallNo'] ?? '').toString();
        final staffName = (rec['staffName'] ?? '').toString();

        final rawStudents = rec['students'];
        final List<Map<String, String>> students = [];
        if (rawStudents is List) {
          for (final s in rawStudents) {
            if (s is Map) {
              students.add({
                'name': s['name']?.toString() ?? '',
                'regNo': s['regNo']?.toString() ?? '',
              });
            }
          }
        }
        final absentCount = students.length.toString();

        // Stacked names column
        pw.Widget namesCol() => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: students
                  .map((s) => txt(s['name']!))
                  .toList(),
            );

        // Stacked reg nos column
        pw.Widget regNosCol() => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: students
                  .map((s) => txt(s['regNo']!))
                  .toList(),
            );

        return pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(
                width: isLast ? 0.5 : 0.3,
                color: PdfColors.grey600,
              ),
            ),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              cell(col: 0, child: txt(sno)),
              cell(col: 1, child: txt(hallNo)),
              cell(col: 2, child: txt(absentCount)),
              cell(col: 3, child: namesCol()),
              cell(col: 4, child: regNosCol()),
              cell(col: 5, child: txt(staffName)),
            ],
          ),
        );
      }

      // ── Assemble MultiPage content ────────────────────────────────────────
      final List<pw.Widget> content = [
        _buildCollegeHeader(),
        _buildTitleSection(title: 'Absent Details Report'),
        pw.SizedBox(height: 4),
        headerRow(),
        ...records.asMap().entries.map(
              (e) => dataRow(e.value, isLast: e.key == records.length - 1),
            ),
      ];

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          build: (_) => content,
        ),
      );

      return await _savePdf(pdf, 'Absent_Details');
    } catch (_) {
      return null;
    }
  }

  // ─── Generic PDF (kept for any future use) ────────────────────────────────
  static Future<String?> generatePdf({
    required String title,
    required List<List<String>> tableData,
    String? subtitle,
  }) async {
    try {
      if (!await requestPermission()) return null;

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          build: (context) => [
            _buildCollegeHeader(),
            _buildTitleSection(title: title),
            _buildTable(tableData),
          ],
        ),
      );

      return await _savePdf(pdf, title);
    } catch (_) {
      return null;
    }
  }
}
