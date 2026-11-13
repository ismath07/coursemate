import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/pdf_service.dart';
import 'staff_home_screen.dart';

// ─── Column widths ────────────────────────────────────────────────────────────
const _kColW = [50.0, 100.0, 80.0, 200.0, 310.0, 80.0];
// Indices:       S.No  Date   Hall  Year/Dept  RegNos  Total
const _kHeaders = [
  'S.No', 'Exam Date', 'Hall No', 'Year / Dept',
  'Register Numbers', 'Total',
];
const _kBorder = BorderSide(color: Color(0xFFCCCCCC), width: 0.8);
const _kCellPad = EdgeInsets.symmetric(horizontal: 10, vertical: 8);
const _kBodyStyle = TextStyle(fontSize: 13, height: 1.4);
const _kHeadStyle = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w700, height: 1.4);

// ═══════════════════════════════════════════════════════════════════════════════
class StaffViewHallAllotmentScreen extends StatelessWidget {
  const StaffViewHallAllotmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Hall Allotment',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 90,
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(30))),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D1B6F), Color(0xFF880E4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () => _downloadPDF(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('staff_hall_allotments')
              .orderBy('createdAt', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(
                  child: Text('Failed to load hall allotments'));
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(
                  child: Text('No hall allotments found'));
            }
            // Horizontal + vertical scroll
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: _buildTable(context, docs),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (i) => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => StaffHomeScreen(initialIndex: i)),
        ),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined), label: 'Syllabus'),
          BottomNavigationBarItem(
              icon: Icon(Icons.schedule_outlined), label: 'Timetable'),
          BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              label: 'Admin'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  // ── Table builder ─────────────────────────────────────────────────────────
  Widget _buildTable(
      BuildContext context, List<QueryDocumentSnapshot> docs) {
    final primary = Theme.of(context).colorScheme.primary;
    final totalW =
        _kColW.fold<double>(0, (sum, w) => sum + w) + _kColW.length * 0.8;

    return SizedBox(
      width: totalW,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _headerRow(primary),
          // Data rows — index is always ascending 0,1,2,… → S.No = index+1
          for (var i = 0; i < docs.length; i++)
            _dataRow(docs[i].data() as Map<String, dynamic>, i),
        ],
      ),
    );
  }

  // ── Header row ────────────────────────────────────────────────────────────
  Widget _headerRow(Color primary) {
    return Container(
      color: primary.withValues(alpha: 0.08),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _kHeaders.length; i++)
            _rawCell(
              width: _kColW[i],
              isFirst: i == 0,
              isHeader: true,
              child: Text(_kHeaders[i],
                  style: _kHeadStyle.copyWith(color: primary)),
            ),
        ],
      ),
    );
  }

  // ── Data row — IntrinsicHeight ensures tallest cell sets row height ────────
  Widget _dataRow(Map<String, dynamic> data, int idx) {
    final sno = (idx + 1).toString();
    final date = _fmtDate(data['examDate']);
    final hall = data['hallNo']?.toString() ?? '-';
    final total = (data['totalStudents'] ?? 0).toString();

    final parsed = _parseAllocations(data);
    final depts = parsed.depts.isEmpty ? ['-'] : parsed.depts;
    final regs = parsed.regs.isEmpty ? ['-'] : parsed.regs;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.stretch, // all cells same height
        children: [
          _rawCell(
              width: _kColW[0],
              isFirst: true,
              child: Text(sno, style: _kBodyStyle)),
          _rawCell(
              width: _kColW[1],
              child: Text(date, style: _kBodyStyle)),
          _rawCell(
              width: _kColW[2],
              child: Text(hall, style: _kBodyStyle)),
          // Year/Dept — one Text per dept, never clipped
          _rawCell(
            width: _kColW[3],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final d in depts) Text(d, style: _kBodyStyle),
              ],
            ),
          ),
          // Register Numbers — one Text per entry, never clipped
          _rawCell(
            width: _kColW[4],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final r in regs) Text(r, style: _kBodyStyle),
              ],
            ),
          ),
          _rawCell(
              width: _kColW[5],
              child: Text(total, style: _kBodyStyle)),
        ],
      ),
    );
  }

  // ── Raw cell ──────────────────────────────────────────────────────────────
  Widget _rawCell({
    required double width,
    required Widget child,
    bool isFirst = false,
    bool isHeader = false,
  }) {
    return Container(
      width: width,
      padding: _kCellPad,
      decoration: BoxDecoration(
        border: Border(
          left: isFirst
              ? _kBorder
              : const BorderSide(color: Color(0xFFCCCCCC), width: 0.8),
          right: _kBorder,
          bottom: _kBorder,
          top: isHeader ? _kBorder : BorderSide.none,
        ),
      ),
      alignment: Alignment.topLeft,
      child: child,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static String _fmtDate(dynamic raw) {
    try {
      DateTime? dt;
      if (raw is Timestamp) {
        dt = raw.toDate();
      } else if (raw is String && raw.isNotEmpty) {
        try {
          dt = DateFormat('dd-MM-yyyy').parseStrict(raw);
        } catch (_) {
          dt = DateTime.tryParse(raw);
        }
      }
      return dt == null ? '-' : DateFormat('dd-MM-yyyy').format(dt);
    } catch (_) {
      return '-';
    }
  }

  static List<String> _listFrom(dynamic d) =>
      d is List ? d.map((e) => e.toString()).toList() : [];

  static ({List<String> depts, List<String> regs}) _parseAllocations(
      Map<String, dynamic> data) {
    final depts = <String>[];
    final regs = <String>[];
    final allocations = data['allocations'];
    if (allocations is List && allocations.isNotEmpty) {
      for (final a in allocations) {
        if (a is Map<String, dynamic>) {
          depts.add(a['yearDept']?.toString() ?? '');
          final r = _listFrom(a['registerNumbers']);
          regs.add(r.isEmpty ? '-' : r.join(', '));
        }
      }
    } else {
      final yd = data['yearDept']?.toString() ?? '';
      if (yd.isNotEmpty) depts.add(yd);
      final r = _listFrom(data['regNos']);
      regs.add(r.isEmpty ? '-' : r.join(', '));
    }
    return (depts: depts, regs: regs);
  }
}

// ─── PDF download ─────────────────────────────────────────────────────────────
Future<void> _downloadPDF(BuildContext context) async {
  try {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Generating PDF...'),
        duration: Duration(seconds: 2)));

    final snapshot = await FirebaseFirestore.instance
        .collection('staff_hall_allotments')
        .orderBy('createdAt', descending: false)
        .get();

    if (snapshot.docs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No data to download')));
      }
      return;
    }

    final hallData = snapshot.docs.asMap().entries.map((e) {
      final data = e.value.data();
      final parsed =
          StaffViewHallAllotmentScreen._parseAllocations(data);
      return {
        'sno': e.key + 1,
        'examDate': StaffViewHallAllotmentScreen._fmtDate(data['examDate']),
        'hallNo': data['hallNo']?.toString() ?? '',
        'yearDepts': parsed.depts,
        'regNosGroups': parsed.regs,
        'totalStudents': data['totalStudents'] ?? 0,
      };
    }).toList();

    final filePath = await PdfService.generateStaffHallAllotmentPDF(
      title: 'Hall Allotment',
      hallData: hallData,
      excludeStaff: true,
    );

    if (context.mounted) {
      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('PDF saved\n$filePath'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to generate PDF.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }
}
