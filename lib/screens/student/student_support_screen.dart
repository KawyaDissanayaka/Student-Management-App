import 'package:flutter/material.dart';

class StudentSupportScreen extends StatelessWidget {
  const StudentSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            Icon(Icons.support_agent_rounded, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text('Student Support & Helpdesk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Emergency Helpline Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7F1D1D), Color(0xFF991B1B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.redAccent.withAlpha(100)),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.emergency_rounded, color: Colors.white, size: 24),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('24/7 Campus Emergency Hotline', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      SizedBox(height: 2),
                      Text('+94 11 234 9999 • Campus Security & Medical Response', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('University Support Desks', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          _buildSupportCard(
            title: 'Academic Advising & Faculty Office',
            category: 'Coursework, module prerequisites, graduation advising',
            email: 'academic.advisor@university.edu',
            phone: '+94 11 234 5610',
            location: 'Building A, Room 102',
            icon: Icons.school_rounded,
            color: Colors.tealAccent,
          ),
          _buildSupportCard(
            title: 'IT Helpdesk & LMS Technical Support',
            category: 'LMS portal, email password resets, WiFi access, software',
            email: 'ithelpdesk@university.edu',
            phone: '+94 11 234 5620',
            location: 'Tech Block, Ground Floor',
            icon: Icons.computer_rounded,
            color: Colors.cyanAccent,
          ),
          _buildSupportCard(
            title: 'Student Affairs & Welfare Division',
            category: 'Hostel accommodation, student clubs, financial aid, counseling',
            email: 'welfare@university.edu',
            phone: '+94 11 234 5630',
            location: 'Student Center, Level 1',
            icon: Icons.favorite_rounded,
            color: Colors.pinkAccent,
          ),
          _buildSupportCard(
            title: 'Career Guidance & Internship Unit',
            category: 'CV reviews, industry placement, company recruiting events',
            email: 'careers@university.edu',
            phone: '+94 11 234 5640',
            location: 'Building A, Level 2',
            icon: Icons.work_outline_rounded,
            color: Colors.amberAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard({
    required String title,
    required String category,
    required String email,
    required String phone,
    required String location,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(category, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Colors.tealAccent),
              const SizedBox(width: 6),
              Text(location, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(phone, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
