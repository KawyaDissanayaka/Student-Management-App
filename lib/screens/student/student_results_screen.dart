import 'package:flutter/material.dart';
import '../../services/student_portal_service.dart';
import '../../models/result_model.dart';

class StudentResultsScreen extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const StudentResultsScreen({super.key, this.userData});

  void _showGradingScale(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.military_tech_rounded, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text('University Grading Scale', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _scaleRow('85 - 100%', 'A+', '4.00 (High Distinction)'),
              _scaleRow('80 - 84%', 'A', '4.00 (Distinction)'),
              _scaleRow('75 - 79%', 'A-', '3.70 (Distinction)'),
              _scaleRow('70 - 74%', 'B+', '3.30 (Credit)'),
              _scaleRow('65 - 69%', 'B', '3.00 (Credit)'),
              _scaleRow('60 - 64%', 'B-', '2.70 (Credit)'),
              _scaleRow('55 - 59%', 'C+', '2.30 (Pass)'),
              _scaleRow('50 - 54%', 'C', '2.00 (Pass)'),
              _scaleRow('45 - 49%', 'C-', '1.70 (Conditional Pass)'),
              _scaleRow('40 - 44%', 'D', '1.00 (Marginal Pass)'),
              _scaleRow('0 - 39%', 'F', '0.00 (Fail)'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.tealAccent))),
        ],
      ),
    );
  }

  Widget _scaleRow(String marks, String grade, String points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(marks, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(grade, style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(points, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = userData?['email'] ?? '';
    final portalService = StudentPortalService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.grade_rounded, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text('Academic Results & GPA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.tealAccent),
            tooltip: 'Grading Scale',
            onPressed: () => _showGradingScale(context),
          ),
        ],
      ),
      body: StreamBuilder<List<ResultModel>>(
        stream: portalService.getStudentResultsStream(email),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
          }

          final results = snapshot.data ?? [];
          final cumulativeGpa = StudentPortalService.calculateGPA(results);
          final completedCredits = StudentPortalService.calculateCompletedCredits(results);

          // Group results by semester
          final Map<String, List<ResultModel>> semesterMap = {};
          for (var r in results) {
            if (!semesterMap.containsKey(r.semester)) {
              semesterMap[r.semester] = [];
            }
            semesterMap[r.semester]!.add(r);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // GPA Showcase Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF334155)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.amberAccent.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.amber.withAlpha(30),
                      child: Text(
                        cumulativeGpa > 0 ? cumulativeGpa.toStringAsFixed(2) : '3.85',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cumulative GPA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                          const SizedBox(height: 4),
                          Text('$completedCredits Earned Credits (Passing Grade ≥ C)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.teal.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                            child: const Text('CLASS: FIRST CLASS HONOURS', style: TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              if (results.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.workspace_premium_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 10),
                        Text('No published exam results for this academic period yet.', style: TextStyle(color: Colors.white70)),
                        SizedBox(height: 4),
                        Text('Results will be posted after official faculty board approval.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                )
              else
                ...semesterMap.entries.map((entry) {
                  final semResults = entry.value;
                  final semGpa = StudentPortalService.calculateGPA(semResults);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Semester GPA: ${semGpa.toStringAsFixed(2)}', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 8),

                        ...semResults.map((r) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r.subjectName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                      Text('${r.subjectCode} • ${r.credits} Credits', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.teal.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                                      child: Text(r.grade, style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text('GP: ${r.gradePoint.toStringAsFixed(1)}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
