# PDF Download Feature - Usage Guide

## Overview
The PDF download feature has been successfully implemented and fixed. PDFs are now saved to the app's documents directory, which doesn't require storage permissions and works on all Android versions including Android 11+.

## What Was Fixed

1. **Removed External Storage Access**: Changed from external storage (Downloads folder) to app documents directory
2. **Removed Permissions**: No longer requires WRITE_EXTERNAL_STORAGE, READ_EXTERNAL_STORAGE, or MANAGE_EXTERNAL_STORAGE
3. **Simplified Dependencies**: Removed `permission_handler` and `printing` packages
4. **Better Error Handling**: Added loading indicators and detailed error messages
5. **File Path Display**: Shows the exact location where PDF is saved

## File Structure

```
lib/
├── services/
│   └── pdf_service.dart          # PDF generation service
└── screens/
    ├── staff/
    │   ├── view_exam_timetable_screen.dart
    │   ├── view_hall_allotment_screen.dart
    │   └── view_syllabus_screen.dart
    └── student/
        ├── view_hall_allotment_screen.dart
        └── view_syllabus_screen.dart
```

## How to Use

### 1. Basic PDF Generation (Generic)

```dart
import 'package:coursemates_app/services/pdf_service.dart';

Future<void> downloadPDF() async {
  final filePath = await PdfService.generatePDF(
    title: 'My Report',
    subtitle: 'Generated on ${DateTime.now()}',
    headers: ['Name', 'Age', 'City'],
    data: [
      ['John', '25', 'New York'],
      ['Jane', '30', 'London'],
      ['Bob', '35', 'Paris'],
    ],
  );

  if (filePath != null) {
    print('PDF saved to: $filePath');
  } else {
    print('Failed to generate PDF');
  }
}
```

### 2. Exam Timetable PDF

```dart
Future<void> downloadExamTimetable() async {
  // Fetch data from Firestore
  final snapshot = await FirebaseFirestore.instance
      .collection('exam_timetables')
      .doc(degreeId)
      .collection('departments')
      .doc(departmentId)
      .collection('years')
      .doc(yearId)
      .collection('exams')
      .orderBy('createdAt')
      .get();

  // Convert to list of maps
  final timetableData = snapshot.docs.map((doc) {
    final data = doc.data();
    return {
      'date': data['date'] ?? '',
      'day': data['day'] ?? '',
      'subject': data['subject'] ?? '',
      'subjectCode': data['subjectCode'] ?? '',
      'session': data['session'] ?? '',
    };
  }).toList();

  // Generate PDF
  final filePath = await PdfService.generateExamTimetablePDF(
    courseName: 'BCA - Computer Science',
    year: '2nd Year',
    timetableData: timetableData,
  );

  if (filePath != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF saved to: $filePath')),
    );
  }
}
```

### 3. Hall Allotment PDF

```dart
Future<void> downloadHallAllotment() async {
  // Fetch data from Firestore
  final snapshot = await FirebaseFirestore.instance
      .collection('staff_hall_allotments')
      .orderBy('sno')
      .get();

  // Convert to list of maps
  final hallData = snapshot.docs.map((doc) {
    final data = doc.data();
    return {
      'sno': data['sno'] ?? 0,
      'staffName': data['staffName']?.toString() ?? '',
      'hallNo': data['hallNo']?.toString() ?? '',
      'noOfStudents': data['noOfStudents'] ?? [],
      'totalStudents': data['totalStudents'] ?? 0,
    };
  }).toList();

  // Generate PDF
  final filePath = await PdfService.generateHallAllotmentPDF(
    title: 'Hall Allotment',
    hallData: hallData,
  );

  if (filePath != null) {
    print('PDF saved to: $filePath');
  }
}
```

### 4. Syllabus PDF

```dart
Future<void> downloadSyllabus() async {
  // Fetch syllabus data
  final data = await firestoreService.getSyllabus(
    degreeLevelId,
    courseId,
    semesterId,
    subjectCode,
  );

  final units = Map<String, dynamic>.from(data['units']);

  // Generate PDF
  final filePath = await PdfService.generateSyllabusPDF(
    subjectName: 'Data Structures',
    subjectCode: 'CS201',
    course: 'BCA',
    semester: 'Semester 3',
    syllabusData: units,
  );

  if (filePath != null) {
    print('PDF saved to: $filePath');
  }
}
```

### 5. Complete Download Function with UI Feedback

```dart
Future<void> _downloadPDF(BuildContext context) async {
  try {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating PDF...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Fetch your data here
    final data = await fetchYourData();

    if (data.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to download')),
        );
      }
      return;
    }

    // Generate PDF
    final filePath = await PdfService.generatePDF(
      title: 'Your Title',
      headers: ['Column 1', 'Column 2'],
      data: data,
    );

    if (context.mounted) {
      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF Downloaded Successfully\nSaved to: $filePath'),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to download PDF. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

### 6. Adding Download Button to AppBar

```dart
AppBar(
  title: const Text('My Screen'),
  actions: [
    IconButton(
      icon: const Icon(Icons.download, color: Colors.white),
      onPressed: () => _downloadPDF(context),
    ),
  ],
)
```

## Where PDFs Are Saved

PDFs are saved in the app's documents directory:
- **Android**: `/data/data/com.example.coursemates_app/app_flutter/PDFs/`
- **iOS**: App Documents Directory

To access PDFs on Android:
1. Use a file manager app with root access, OR
2. Connect device to computer and use Android Studio's Device File Explorer, OR
3. Add a "Share" button to share the PDF via email/WhatsApp/etc.

## Adding Share Functionality (Optional)

If you want users to easily share PDFs, add the `share_plus` package:

```yaml
dependencies:
  share_plus: ^7.0.0
```

Then modify the download function:

```dart
import 'package:share_plus/share_plus.dart';

Future<void> _downloadAndSharePDF(BuildContext context) async {
  final filePath = await PdfService.generatePDF(...);
  
  if (filePath != null) {
    await Share.shareXFiles([XFile(filePath)], text: 'Check out this PDF!');
  }
}
```

## Troubleshooting

### Issue: "Failed to download PDF"
**Solution**: Check the console logs for detailed error messages. The error is now printed to help debug.

### Issue: Can't find the PDF file
**Solution**: PDFs are in the app's private directory. Use Device File Explorer in Android Studio or add share functionality.

### Issue: PDF is empty
**Solution**: Make sure your data list is not empty before calling the PDF generation function.

## Testing

1. Run the app: `flutter run`
2. Navigate to any screen with a download button
3. Click the download icon
4. You should see "Generating PDF..." followed by "PDF Downloaded Successfully" with the file path
5. Check the console for the exact file path

## Dependencies Used

```yaml
dependencies:
  pdf: ^3.10.0              # PDF generation
  path_provider: ^2.1.0     # Get app directories
  intl: ^0.18.0             # Date formatting
```

## Summary

The PDF download feature is now working correctly with:
- ✅ No permission issues
- ✅ Works on all Android versions
- ✅ Clear error messages
- ✅ File path displayed to user
- ✅ Loading indicators
- ✅ Proper error handling
- ✅ Clean, reusable code
