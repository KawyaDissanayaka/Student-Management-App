import 'package:flutter/material.dart';

class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({super.key});

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  String _selectedCategory = 'All';

  final List<Map<String, dynamic>> _buildings = [
    {
      'code': 'BLD-A',
      'name': 'Main Administration Complex',
      'category': 'Administration',
      'floors': 'Ground + 3 Floors',
      'facilities': ['Student Affairs', 'Examination Division', 'Dean\'s Office', 'Finance & Payments'],
      'color': Colors.indigoAccent,
    },
    {
      'code': 'BLD-B',
      'name': 'Faculty of Computing & IT Block',
      'category': 'Academic',
      'floors': 'Ground + 4 Floors',
      'facilities': ['AI Labs 01-04', 'Lecture Halls B101-B205', 'Cybersecurity Lab', 'Server Room'],
      'color': Colors.tealAccent,
    },
    {
      'code': 'BLD-C',
      'name': 'Central Academic Library',
      'category': 'Library',
      'floors': 'Ground + 2 Floors',
      'facilities': ['Digital Research Commons', 'Silent Study Pods', 'Book Lending', 'Discussion Rooms'],
      'color': Colors.amberAccent,
    },
    {
      'code': 'BLD-D',
      'name': 'Engineering & Electronics Labs',
      'category': 'Academic',
      'floors': 'Ground + 3 Floors',
      'facilities': ['Robotics Lab', 'Circuits & Embedded Systems', 'Makerspace 3D Printing', 'Workshop'],
      'color': Colors.cyanAccent,
    },
    {
      'code': 'BLD-E',
      'name': 'Student Life Center & Cafeteria',
      'category': 'Amenities',
      'floors': 'Ground + 1 Floor',
      'facilities': ['Food Court', 'Student Lounge', 'ATM & Bank Kiosk', 'Stationery Store'],
      'color': Colors.orangeAccent,
    },
    {
      'code': 'BLD-F',
      'name': 'Indoor Sports Arena & Gymnasium',
      'category': 'Sports',
      'floors': 'Ground + 1 Floor',
      'facilities': ['Badminton Courts', 'Fitness Gym', 'Table Tennis Arena', 'Locker Rooms'],
      'color': Colors.greenAccent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _buildings.where((b) {
      if (_selectedCategory == 'All') return true;
      return b['category'] == _selectedCategory;
    }).toList();

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
            Icon(Icons.map_rounded, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text('Campus Navigation Map', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: const Color(0xFF1E293B),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Academic', 'Administration', 'Library', 'Amenities', 'Sports'].map((cat) {
                  final isSel = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSel,
                      onSelected: (val) {
                        if (val) setState(() => _selectedCategory = cat);
                      },
                      selectedColor: Colors.teal,
                      backgroundColor: const Color(0xFF0F172A),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : Colors.grey,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      side: BorderSide(color: isSel ? Colors.tealAccent : Colors.white10),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Visual Campus Grid & Building Directory
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Campus Map Visual Overview Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF334155)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.tealAccent.withAlpha(80)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.explore_rounded, color: Colors.tealAccent, size: 20),
                          SizedBox(width: 8),
                          Text('MAIN UNIVERSITY CAMPUS GROUNDS', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text('Navigate across academic halls, computing blocks, laboratories, and student service hubs.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                const Text('Campus Zones & Buildings', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                ...filtered.map((b) {
                  final color = b['color'] as Color;
                  final facilities = b['facilities'] as List<String>;

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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: color.withAlpha(80)),
                              ),
                              child: Text(
                                b['code'],
                                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                            Text(b['floors'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(b['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Zone: ${b['category']}', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 10),
                        const Text('Key Facilities Inside:', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: facilities.map((f) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
                              child: Text(f, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
