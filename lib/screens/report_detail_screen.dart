import 'package:flutter/material.dart';
import '../data/models/report.dart';
import 'dart:io';

class ReportDetailScreen extends StatelessWidget {
  final Report report;
  const ReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(report.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (report.imagePath.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(report.imagePath),
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            SizedBox(height: 16),
            Text(
              report.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(getCategoryLabel(report.category)),
                ),
                Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 237, 233, 234),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(getStatusLabel(report.status)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
