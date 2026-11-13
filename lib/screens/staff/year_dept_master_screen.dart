import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/year_dept_sort.dart';

class YearDeptMasterScreen extends StatefulWidget {
  const YearDeptMasterScreen({super.key});

  @override
  State<YearDeptMasterScreen> createState() => _YearDeptMasterScreenState();
}

class _YearDeptMasterScreenState extends State<YearDeptMasterScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Year/Dept'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Year/Dept (e.g., I - MSc IT)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter year/dept')));
                return;
              }
              try {
                await FirebaseFirestore.instance.collection('master_data').doc('year_dept').collection('items').add({
                  'displayName': nameCtrl.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Year/Dept added successfully')));
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final nameCtrl = TextEditingController(text: data['displayName']?.toString() ?? '');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Year/Dept'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Year/Dept')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter year/dept')));
                return;
              }
              try {
                await FirebaseFirestore.instance.collection('master_data').doc('year_dept').collection('items').doc(doc.id).update({
                  'displayName': nameCtrl.text.trim(),
                });
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Year/Dept updated successfully')));
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteYearDept(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Year/Dept'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('master_data').doc('year_dept').collection('items').doc(docId).delete();
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Year/Dept deleted successfully')));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF0D1B6F), Color(0xFF880E4F)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Year/Department', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 90,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
        flexibleSpace: Container(decoration: gradient),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search year/dept...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('master_data').doc('year_dept').collection('items').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var docs = YearDeptSort.sortDocuments(snapshot.data!.docs);
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((d) => (d['displayName']?.toString() ?? '').toLowerCase().contains(_searchQuery)).toList();
                }

                if (docs.isEmpty) return const Center(child: Text('No year/dept found'));

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final displayName = doc['displayName']?.toString() ?? '';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(displayName),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showEditDialog(doc)),
                            IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => _deleteYearDept(doc.id)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
