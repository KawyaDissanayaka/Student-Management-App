import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/library_model.dart';

class StudentLibraryScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const StudentLibraryScreen({super.key, this.userData});

  @override
  State<StudentLibraryScreen> createState() => _StudentLibraryScreenState();
}

class _StudentLibraryScreenState extends State<StudentLibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showBookDetailModal(BuildContext context, LibraryBookModel book) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.indigo.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                  child: Text(book.category, style: const TextStyle(color: Colors.indigoAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 8),
            Text(book.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 4),
            Text('Author: ${book.author}', style: const TextStyle(color: Colors.tealAccent, fontSize: 13)),
            const SizedBox(height: 2),
            Text('Publisher: ${book.publisher} • ${book.edition}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 10),
            const Divider(color: Colors.white10),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SHELF / LOCATION', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 2),
                    Text(book.shelfLocation, style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('AVAILABILITY', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 2),
                    Text(
                      '${book.availableCopies} of ${book.totalCopies} Copies',
                      style: TextStyle(color: book.isAvailable ? Colors.greenAccent : Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.tealAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'To borrow this physical book, please visit the library counter with your student ID card.',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = (widget.userData?['email'] ?? 'student@uni.lk').toString().trim().toLowerCase();

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
            Icon(Icons.local_library_rounded, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text('University Library & Books', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.tealAccent,
          labelColor: Colors.tealAccent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Book Catalog', icon: Icon(Icons.menu_book_rounded, size: 18)),
            Tab(text: 'My Library (Loans)', icon: Icon(Icons.bookmark_added_rounded, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Books Search & Catalog
          _buildCatalogTab(),

          // Tab 2: My Borrowed Books
          _buildMyLibraryTab(email),
        ],
      ),
    );
  }

  Widget _buildCatalogTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF1E293B),
          child: Column(
            children: [
              TextField(
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search title, author or ISBN...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              ),
              const SizedBox(height: 8),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', ...LibraryBookModel.supportedCategories].map((cat) {
                    final isSel = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(cat, style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                        selected: isSel,
                        selectedColor: Colors.tealAccent,
                        backgroundColor: const Color(0xFF0F172A),
                        onSelected: (sel) {
                          if (sel) setState(() => _selectedCategory = cat);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('libraryBooks').where('status', isNotEqualTo: 'Archived').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
              }

              final docs = snapshot.data?.docs ?? [];
              final allBooks = docs.map((d) => LibraryBookModel.fromFirestore(d)).toList();

              final filtered = allBooks.where((b) {
                final matchesSearch = b.title.toLowerCase().contains(_searchQuery) ||
                    b.author.toLowerCase().contains(_searchQuery) ||
                    b.isbn.toLowerCase().contains(_searchQuery);
                final matchesCat = _selectedCategory == 'All' || b.category == _selectedCategory;
                return matchesSearch && matchesCat;
              }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('No matching books found in catalog.', style: TextStyle(color: Colors.grey)));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final b = filtered[index];
                  final isAvail = b.isAvailable;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
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
                              decoration: BoxDecoration(color: Colors.indigo.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                              child: Text(b.category, style: const TextStyle(color: Colors.indigoAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isAvail ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isAvail ? '${b.availableCopies} Available' : 'Out of Stock',
                                style: TextStyle(color: isAvail ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(b.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text('by ${b.author} • ${b.edition}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('Shelf: ${b.shelfLocation}', style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _showBookDetailModal(context, b),
                              icon: const Icon(Icons.info_outline, size: 14, color: Colors.tealAccent),
                              label: const Text('View Details', style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMyLibraryTab(String studentEmail) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('libraryBorrowings').where('studentEmail', isEqualTo: studentEmail).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
        }

        final docs = snapshot.data?.docs ?? [];
        final borrowings = docs.map((d) => LibraryBorrowingModel.fromFirestore(d)).toList();

        if (borrowings.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_stories_rounded, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('You have no active or past library book loans.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: borrowings.length,
          itemBuilder: (context, index) {
            final br = borrowings[index];
            final effStatus = br.effectiveStatus;
            final isRet = br.isReturned;
            final isOver = br.isOverdue;

            Color stColor = Colors.tealAccent;
            if (isRet) stColor = Colors.grey;
            if (isOver) stColor = Colors.redAccent;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isOver ? Colors.redAccent.withAlpha(100) : Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(br.borrowingId, style: const TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'monospace')),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: stColor.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                        child: Text(effStatus.toUpperCase(), style: TextStyle(color: stColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(br.bookTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text('Borrowed: ${br.borrowDate} • Due: ${br.dueDate}', style: TextStyle(color: isOver ? Colors.redAccent : Colors.grey, fontSize: 11, fontWeight: isOver ? FontWeight.bold : FontWeight.normal)),
                  if (br.returnDate != null) ...[
                    const SizedBox(height: 2),
                    Text('Returned on: ${br.returnDate}', style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
