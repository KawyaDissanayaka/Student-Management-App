import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReportExportService {
  /// Converts headers and rows to CSV string
  static String generateCsv({
    required String reportTitle,
    required List<String> headers,
    required List<List<String>> rows,
    Map<String, String>? summaryMetrics,
  }) {
    final StringBuffer buffer = StringBuffer();

    // Title & Generation timestamp
    buffer.writeln('# $reportTitle');
    buffer.writeln('# Generated on: ${DateTime.now().toLocal().toString().substring(0, 19)}');
    buffer.writeln();

    // Summary metrics if provided
    if (summaryMetrics != null && summaryMetrics.isNotEmpty) {
      buffer.writeln('# --- SUMMARY METRICS ---');
      summaryMetrics.forEach((key, val) {
        buffer.writeln('# $key: $val');
      });
      buffer.writeln();
    }

    // Headers
    buffer.writeln(headers.map((h) => _escapeCsvValue(h)).join(','));

    // Rows
    for (final row in rows) {
      buffer.writeln(row.map((cell) => _escapeCsvValue(cell)).join(','));
    }

    return buffer.toString();
  }

  /// Converts data into a clean, printable text / PDF formatted report
  static String generatePrintableTextReport({
    required String reportTitle,
    required List<String> headers,
    required List<List<String>> rows,
    Map<String, String>? summaryMetrics,
  }) {
    final StringBuffer buffer = StringBuffer();
    final now = DateTime.now().toLocal().toString().substring(0, 19);

    buffer.writeln('========================================================================');
    buffer.writeln('                     STUDENT MANAGEMENT SYSTEM');
    buffer.writeln('                     $reportTitle');
    buffer.writeln('========================================================================');
    buffer.writeln('Generated: $now\n');

    if (summaryMetrics != null && summaryMetrics.isNotEmpty) {
      buffer.writeln('--- EXECUTIVE SUMMARY ---');
      summaryMetrics.forEach((key, val) {
        buffer.writeln('• $key: $val');
      });
      buffer.writeln('------------------------------------------------------------------------\n');
    }

    buffer.writeln('--- DATA RECORDS (${rows.length} entries) ---\n');
    for (int i = 0; i < rows.length; i++) {
      buffer.writeln('Record #${i + 1}:');
      for (int h = 0; h < headers.length && h < rows[i].length; h++) {
        buffer.writeln('  ${headers[h]}: ${rows[i][h]}');
      }
      buffer.writeln('------------------------------------------------------------------------');
    }

    buffer.writeln('\n*** End of Report ***');
    return buffer.toString();
  }

  static String _escapeCsvValue(String val) {
    if (val.contains(',') || val.contains('"') || val.contains('\n')) {
      return '"${val.replaceAll('"', '""')}"';
    }
    return val;
  }

  /// Shows export dialog with options to Copy or View formatted export
  static void showExportDialog({
    required BuildContext context,
    required String reportTitle,
    required List<String> headers,
    required List<List<String>> rows,
    Map<String, String>? summaryMetrics,
  }) {
    final csvContent = generateCsv(
      reportTitle: reportTitle,
      headers: headers,
      rows: rows,
      summaryMetrics: summaryMetrics,
    );

    final printableContent = generatePrintableTextReport(
      reportTitle: reportTitle,
      headers: headers,
      rows: rows,
      summaryMetrics: summaryMetrics,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.file_download_rounded, color: Colors.tealAccent, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Export $reportTitle',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select export format (${rows.length} records ready):',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.table_chart_rounded, color: Colors.greenAccent),
              ),
              title: const Text('Excel / CSV Format', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Comma-separated values for spreadsheet import', style: TextStyle(color: Colors.grey, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _showPreviewDialog(context, 'Excel / CSV Export', csvContent);
              },
            ),
            const Divider(color: Colors.white10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
              ),
              title: const Text('Printable Document / PDF Format', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Formatted text report for archiving or printing', style: TextStyle(color: Colors.grey, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _showPreviewDialog(context, 'Printable Document Report', printableContent);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  static void _showPreviewDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: Colors.tealAccent, size: 20),
              tooltip: 'Copy to Clipboard',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report copied to clipboard!'), backgroundColor: Colors.green),
                );
              },
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 380,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                content,
                style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied report data to clipboard!'), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 16),
            label: const Text('Copy All Data', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
