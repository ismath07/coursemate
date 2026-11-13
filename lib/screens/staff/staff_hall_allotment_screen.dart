import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../services/pdf_service.dart';
import 'staff_home_screen.dart';
import 'staff_hall_allotment_form_screen.dart';

// ─── Column widths (px) ───────────────────────────────────────────────────────
// S.No | Exam Date | Faculty | Hall | Year/Dept | Register Nos | Total | Actions
const _kW = <double>[50, 100, 140, 80, 200, 300, 80, 96];

// ─── Styling constants ────────────────────────────────────────────────────────
const _kDiv  = Color(0xFFCCCCCC);
const _kPad  = EdgeInsets.symmetric(horizontal: 10, vertical: 8);
const _kBody = TextStyle(fontSize: 13, height: 1.45);
const _kHead = TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.45);

class StaffHallAllotmentScreen extends StatelessWidget {
  const StaffHallAllotmentScreen({super.key});

  // ── Data helpers ──────────────────────────────────────────────────────────
  static List<String> _listFrom(dynamic d) =>
      d is List ? d.map((e) => e.toString()).toList() : [];

  static String _fmtDate(dynamic raw) {
    try {
      DateTime? dt;
      if (raw is Timestamp) dt = raw.toDate();
      else if (raw is String && raw.isNotEmpty) {
        try { dt = DateFormat('dd-MM-yyyy').parseStrict(raw); } catch (_) { dt = DateTime.tryParse(raw); }
      }
      return dt == null ? '-' : DateFormat('dd-MM-yyyy').format(dt);
    } catch (_) { return '-'; }
  }

  static ({List<String> depts, List<String> regs}) _parse(
      Map<String, dynamic> data) {
    final depts = <String>[], regs = <String>[];
    final allocs = data['allocations'];
    if (allocs is List && allocs.isNotEmpty) {
      for (final a in allocs) {
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

  // ── Build a single border-box cell ────────────────────────────────────────
  // width     : fixed pixel width from _kW
  // topBorder : true only for header row
  // leftBorder: true only for the first column
  static Widget _cell({
    required double width,
    required Widget child,
    bool topBorder = false,
    bool leftBorder = false,
  }) {
    return Container(
      width: width,
      padding: _kPad,
      alignment: Alignment.topLeft,
      decoration: BoxDecoration(
        border: Border(
          top:    topBorder  ? const BorderSide(color: _kDiv, width: 0.8) : BorderSide.none,
          left:   leftBorder ? const BorderSide(color: _kDiv, width: 0.8) : BorderSide.none,
          right:  const BorderSide(color: _kDiv, width: 0.8),
          bottom: const BorderSide(color: _kDiv, width: 0.8),
        ),
      ),
      child: child,
    );
  }

  // ── Header row ────────────────────────────────────────────────────────────
  Widget _header(Color primary, bool hasAccess) {
    final labels = [
      'S.No', 'Exam Date', 'Faculty Name', 'Hall No',
      'Year / Dept', 'Register Numbers', 'Total',
      if (hasAccess) 'Actions',
    ];
    return Container(
      color: primary.withValues(alpha: 0.08),
      // Row with mainAxisSize.min — it will be exactly as wide as its children
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < labels.length; i++)
            _cell(
              width: _kW[i],
              topBorder: true,
              leftBorder: i == 0,
              child: Text(labels[i],
                  style: _kHead.copyWith(color: primary)),
            ),
        ],
      ),
    );
  }

  // ── Data row ─────────────────────────────────────────────────────────────
  // IntrinsicHeight forces every sibling cell to match the tallest cell's
  // height. CrossAxisAlignment.stretch makes borders fill that height.
  Widget _row(int idx, QueryDocumentSnapshot doc, bool hasAccess,
      BuildContext ctx) {
    final data   = doc.data() as Map<String, dynamic>;
    final sno    = (idx + 1).toString();
    final date   = _fmtDate(data['examDate']);
    final name   = data['staffName']?.toString() ?? '-';
    final hall   = data['hallNo']?.toString() ?? '-';
    final total  = (data['totalStudents'] ?? 0).toString();
    final parsed = _parse(data);
    final depts  = parsed.depts.isEmpty ? ['-'] : parsed.depts;
    final regs   = parsed.regs.isEmpty  ? ['-'] : parsed.regs;

    return IntrinsicHeight(
      child: Row(
        // min → the Row is exactly as wide as the sum of child widths.
        // No overflow possible because each child has a fixed Container width.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cell(width: _kW[0], leftBorder: true,
              child: Text(sno,  style: _kBody)),
          _cell(width: _kW[1],
              child: Text(date, style: _kBody)),
          _cell(width: _kW[2],
              child: Text(name, style: _kBody)),
          _cell(width: _kW[3],
              child: Text(hall, style: _kBody)),

          // Year/Dept — each department on its own line
          _cell(
            width: _kW[4],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final d in depts) Text(d, style: _kBody)],
            ),
          ),

          // Register Numbers — each group on its own line
          _cell(
            width: _kW[5],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final r in regs) Text(r, style: _kBody)],
            ),
          ),

          _cell(width: _kW[6],
              child: Text(total, style: _kBody)),

          // Actions — only when staff has edit access
          if (hasAccess)
            _cell(
              width: _kW[7],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () => _edit(ctx, doc),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.edit, size: 18),
                    ),
                  ),
                  InkWell(
                    onTap: () => _delete(ctx, doc.id),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.delete, size: 18, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Table ─────────────────────────────────────────────────────────────────
  Widget _table(BuildContext ctx, List<QueryDocumentSnapshot> docs,
      bool hasAccess) {
    final primary = Theme.of(ctx).colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(primary, hasAccess),
        for (var i = 0; i < docs.length; i++)
          _row(i, docs[i], hasAccess, ctx),
      ],
    );
  }

  // ── CRUD helpers ─────────────────────────────────────────────────────────
  Future<void> _add(BuildContext ctx) async {
    final ok = await Navigator.push<bool>(
        ctx, MaterialPageRoute(builder: (_) => const StaffHallAllotmentFormScreen()));
    if (ok == true && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Staff hall allotment added successfully')));
    }
  }

  Future<void> _edit(BuildContext ctx, DocumentSnapshot doc) async {
    final ok = await Navigator.push<bool>(
        ctx, MaterialPageRoute(builder: (_) => StaffHallAllotmentFormScreen(existing: doc)));
    if (ok == true && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Staff hall allotment updated successfully')));
    }
  }

  Future<void> _delete(BuildContext ctx, String id) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Delete'),
        content: const Text('Delete this hall allotment record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseFirestore.instance
          .collection('staff_hall_allotments')
          .doc(id)
          .delete();
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('Staff hall allotment deleted successfully')));
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: FirestoreService().editAccessStream(),
      builder: (ctx, snap) {
        final hasAccess = snap.data ?? false;

        return Scaffold(
          backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Faculty Hall Allotment',
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            toolbarHeight: 80,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
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
            actions: [
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: () => _downloadPDF(ctx),
              ),
            ],
          ),

          // ── Body: horizontal scroll → vertical scroll → custom table ──────
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('staff_hall_allotments')
                .orderBy('createdAt', descending: false)
                .snapshots(),
            builder: (ctx2, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Failed to load data.'));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No staff hall allotments found.'));
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                // padding inside scroll → doesn't constrain the Row
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: _table(ctx2, docs, hasAccess),
                ),
              );
            },
          ),

          floatingActionButton: hasAccess
              ? FloatingActionButton(
                  onPressed: () => _add(ctx),
                  backgroundColor: Theme.of(ctx).colorScheme.primary,
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 2,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(ctx).colorScheme.primary,
            onTap: (i) => Navigator.pushReplacement(
                ctx, MaterialPageRoute(builder: (_) => StaffHomeScreen(initialIndex: i))),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book_outlined), label: 'Syllabus'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.schedule_outlined), label: 'Timetable'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.admin_panel_settings_outlined), label: 'Admin'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline), label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}

// ─── PDF download (outside class — top-level function) ────────────────────────
Future<void> _downloadPDF(BuildContext context) async {
  try {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Generating PDF…'), duration: Duration(seconds: 2)));

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
      final data   = e.value.data();
      final parsed = StaffHallAllotmentScreen._parse(data);
      return {
        'sno'          : e.key + 1,
        'examDate'     : StaffHallAllotmentScreen._fmtDate(data['examDate']),
        'staffName'    : data['staffName']?.toString() ?? '',
        'hallNo'       : data['hallNo']?.toString() ?? '',
        'yearDepts'    : parsed.depts,
        'regNosGroups' : parsed.regs,
        'totalStudents': data['totalStudents'] ?? 0,
      };
    }).toList();

    final filePath = await PdfService.generateStaffHallAllotmentPDF(
      title: 'Faculty Hall Allotment',
      hallData: hallData,
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
