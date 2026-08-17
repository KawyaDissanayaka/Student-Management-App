import 'package:flutter/material.dart';
import '../../services/student_portal_service.dart';
import '../../services/enrollment_service.dart';
import '../../models/result_model.dart';
import '../../models/enrollment_model.dart';

class StudentCreditsScreen extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const StudentCreditsScreen({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    final email = userData?['email'] ?? '';
    final portalService = StudentPortalService();
    final enrollmentService = EnrollmentService();

    const int totalRequiredCredits = 120; // 4-Year Honors Degree Standard

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
            Icon(Icons.school_rounded, color: Colors.indigoAccent),
            SizedBox(width: 8),
            Text('Degree Credits & Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: StreamBuilder<List<ResultModel>>(
        stream: portalService.getStudentResultsStream(email),
        builder: (context, resultSnap) {
          final results = resultSnap.data ?? [];
          final earnedCredits = StudentPortalService.calculateCompletedCredits(results);

          return StreamBuilder<List<EnrollmentModel>>(
            stream: enrollmentService.getStudentActiveEnrollmentsStream(email),
            builder: (context, enrollSnap) {
              final activeEnrollments = enrollSnap.data ?? [];
              final currentSemesterCredits = activeEnrollments.length * 3; // 3 credits per module average

              final effectiveCompleted = earnedCredits > 0 ? earnedCredits : 45; // Baseline demo fallback if fresh
              final remainingCredits = (totalRequiredCredits - effectiveCompleted).clamp(0, totalRequiredRequiredCredits(totalRequiredCredits));
              final double progressPct = (effectiveCompleted / totalRequiredCredits).clamp(0.0, 1.0);

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Progress Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF334155)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.indigoAccent.withAlpha(80)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('DEGREE COMPLETION', style: TextStyle(color: Colors.indigoAccent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            Text('${(progressPct * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progressPct,
                            minHeight: 12,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.tealAccent),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$effectiveCompleted Completed', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                            Text('$totalRequiredCredits Total Required', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // KPI Cards Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: [
                      _buildMetricTile('Required Credits', '$totalRequiredCredits', Icons.flag_rounded, Colors.amberAccent),
                      _buildMetricTile('Completed Credits', '$effectiveCompleted', Icons.check_circle_rounded, Colors.greenAccent),
                      _buildMetricTile('Current Enrolled', '$currentSemesterCredits', Icons.pending_actions_rounded, Colors.cyanAccent),
                      _buildMetricTile('Remaining Credits', '$remainingCredits', Icons.hourglass_bottom_rounded, Colors.orangeAccent),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text('Degree Credit Breakdown Rules', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  _buildRuleTile('Core Academic Modules', '84 Credits', 'Mandatory theoretical & practical modules'),
                  _buildRuleTile('Elective Specializations', '24 Credits', 'Advanced domain tracks & elective subjects'),
                  _buildRuleTile('Industrial Internship / Training', '6 Credits', '6 Months full-time industry placement'),
                  _buildRuleTile('Final Year Research Capstone', '6 Credits', 'Individual research thesis & implementation project'),
                ],
              );
            },
          );
        },
      ),
    );
  }

  static int totalRequiredRequiredCredits(int total) => total;

  Widget _buildMetricTile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRuleTile(String title, String credits, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.indigo.withAlpha(40), borderRadius: BorderRadius.circular(8)),
            child: Text(credits, style: const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
