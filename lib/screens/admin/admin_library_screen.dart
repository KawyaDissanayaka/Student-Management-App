import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/library_model.dart';

class AdminLibraryScreen extends StatefulWidget {
  const AdminLibraryScreen({super.key});

  @override
  State<AdminLibraryScreen> createState() => _AdminLibraryScreenState();
}

class _AdminLibraryScreenState extends State<AdminLibraryScreen> with SingleTickerProviderStateMixin {
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

  // ---------------------------------------------------------------------------
  // 1. ADD / EDIT BOOK MODAL
  // ---------------------------------------------------------------------------
  void _showBookModal({LibraryBookModel? existing}) {
    final isEditing = existing != null;
    final isbnCtrl = TextEditingController(text: existing?.isbn ?? '978-0132350884');
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final authorCtrl = TextEditingController(text: existing?.author ?? '');
    final pubCtrl = TextEditingController(text: existing?.publisher ?? 'Pearson Education');
    final editionCtrl = TextEditingController(text: existing?.edition ?? '1st Edition');
    final totalCtrl = TextEditingController(text: existing != null ? '${existing.totalCopies}' : '5');
    final availCtrl = TextEditingController(text: existing != null ? '${existing.availableCopies}' : '5');
    final shelfCtrl = TextEditingController(text: existing?.shelfLocation ?? 'Rack C-04');
    String category = existing?.category ?? 'Computer Science';
    String status = existing?.status ?? 'Available';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isEditing ? 'Edit Library Book' : 'Add New Library Book', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Book Title *',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: authorCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Author *',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: isbnCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'ISBN Number *',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  initialValue: category,
                  dropdownColor: const Color(0xFF0F172A),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Category *',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: LibraryBookModel.supportedCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setModalState(() => category = v ?? 'Computer Science'),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pubCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Publisher',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: editionCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Edition',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: totalCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Total Copies *',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: availCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Available Copies *',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: shelfCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Shelf / Rack Location *',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: status,
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Book Status',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: LibraryBookModel.supportedStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setModalState(() => status = v ?? 'Available'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final title = titleCtrl.text.trim();
                            final author = authorCtrl.text.trim();
                            final total = int.tryParse(totalCtrl.text.trim()) ?? 0;
                            final avail = int.tryParse(availCtrl.text.trim()) ?? total;

                            if (title.isEmpty || author.isEmpty || total <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please provide title, author and valid copy counts.')),
                              );
                              return;
                            }

                            setModalState(() => isSaving = true);
                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(ctx);

                            try {
                              final bookId = existing?.bookId ?? 'BK-${DateTime.now().millisecondsSinceEpoch}';
                              final model = LibraryBookModel(
                                docId: existing?.docId,
                                bookId: bookId,
                                isbn: isbnCtrl.text.trim(),
                                title: title,
                                author: author,
                                category: category,
                                publisher: pubCtrl.text.trim(),
                                edition: editionCtrl.text.trim(),
                                totalCopies: total,
                                availableCopies: avail.clamp(0, total),
                                shelfLocation: shelfCtrl.text.trim(),
                                status: status,
                              );

                              if (isEditing && existing.docId != null) {
                                await _firestore.collection('libraryBooks').doc(existing.docId).update(model.toMap());
                              } else {
                                await _firestore.collection('libraryBooks').add(model.toMap());
                              }

                              nav.pop();
                              messenger.showSnackBar(SnackBar(content: Text('Book "$title" saved successfully!'), backgroundColor: Colors.green));
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              messenger.showSnackBar(SnackBar(content: Text('Failed to save book: $e'), backgroundColor: Colors.redAccent));
                            }
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    icon: isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded, color: Colors.white, size: 16),
                    label: Text(isEditing ? 'Save Book Changes' : 'Add Book to Catalog', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. ISSUE BOOK MODAL (DECREASES AVAILABLE COPIES)
  // ---------------------------------------------------------------------------
  void _showIssueModal(List<LibraryBookModel> books) {
    final availableBooks = books.where((b) => b.isAvailable && !b.isArchived).toList();

    if (availableBooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No books currently available for borrowing.')),
      );
      return;
    }

    LibraryBookModel selectedBook = availableBooks.first;
    final stuIdCtrl = TextEditingController(text: 'STU-1001');
    final stuEmailCtrl = TextEditingController(text: 'student@uni.lk');
    final stuNameCtrl = TextEditingController(text: 'Kasun Bandara');

    final now = DateTime.now();
    final defaultDue = now.add(const Duration(days: 14));
    final borrowDateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final dueDateStr = '${defaultDue.year}-${defaultDue.month.toString().padLeft(2, '0')}-${defaultDue.day.toString().padLeft(2, '0')}';

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Issue Book to Student', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: selectedBook.bookId,
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Select Book to Issue *',
                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: availableBooks
                    .map((b) => DropdownMenuItem(value: b.bookId, child: Text('${b.title} (${b.availableCopies} available)')))
                    .toList(),
                onChanged: (v) {
                  final found = availableBooks.firstWhere((b) => b.bookId == v);
                  setModalState(() => selectedBook = found);
                },
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: stuIdCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Student ID *',
                        labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: stuNameCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Student Name *',
                        labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              TextField(
                controller: stuEmailCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Student Email *',
                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Borrow Date: $borrowDateStr', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('Due Date: $dueDateStr', style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final stuEmail = stuEmailCtrl.text.trim().toLowerCase();
                          final stuId = stuIdCtrl.text.trim();
                          final stuName = stuNameCtrl.text.trim();

                          if (stuEmail.isEmpty || stuId.isEmpty || stuName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all student details.')));
                            return;
                          }

                          if (selectedBook.availableCopies <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: No available copies left for this book.')));
                            return;
                          }

                          setModalState(() => isSaving = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(ctx);

                          try {
                            final borrowingId = 'BRW-${DateTime.now().millisecondsSinceEpoch}';
                            final borrowing = LibraryBorrowingModel(
                              borrowingId: borrowingId,
                              bookId: selectedBook.bookId,
                              bookTitle: selectedBook.title,
                              isbn: selectedBook.isbn,
                              studentId: stuId,
                              studentEmail: stuEmail,
                              studentName: stuName,
                              borrowDate: borrowDateStr,
                              dueDate: dueDateStr,
                              status: 'Borrowed',
                              issuedBy: 'Admin Librarian',
                            );

                            // 1. Create Borrowing Record
                            await _firestore.collection('libraryBorrowings').add(borrowing.toMap());

                            // 2. Decrement available copies in libraryBooks
                            if (selectedBook.docId != null) {
                              final newAvail = (selectedBook.availableCopies - 1).clamp(0, selectedBook.totalCopies);
                              await _firestore.collection('libraryBooks').doc(selectedBook.docId).update({
                                'availableCopies': newAvail,
                                'status': newAvail > 0 ? 'Available' : 'Unavailable',
                              });
                            }

                            nav.pop();
                            messenger.showSnackBar(SnackBar(content: Text('Book "${selectedBook.title}" issued to $stuName!'), backgroundColor: Colors.green));
                          } catch (e) {
                            setModalState(() => isSaving = false);
                            messenger.showSnackBar(SnackBar(content: Text('Failed to issue book: $e'), backgroundColor: Colors.redAccent));
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  icon: const Icon(Icons.outbox_rounded, color: Colors.white, size: 16),
                  label: const Text('Confirm & Issue Book', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. RETURN BOOK ACTION (INCREASES AVAILABLE COPIES)
  // ---------------------------------------------------------------------------
  void _returnBook(LibraryBorrowingModel borrowing, List<LibraryBookModel> allBooks) async {
    final now = DateTime.now();
    final returnDateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (borrowing.docId != null) {
        await _firestore.collection('libraryBorrowings').doc(borrowing.docId).update({
          'status': 'Returned',
          'returnDate': returnDateStr,
          'returnedTo': 'Admin Librarian',
        });
      }

      // Find matching book and increment available copies
      final book = allBooks.cast<LibraryBookModel?>().firstWhere(
            (b) => b?.bookId == borrowing.bookId,
            orElse: () => null,
          );

      if (book != null && book.docId != null) {
        final newAvail = (book.availableCopies + 1).clamp(0, book.totalCopies);
        await _firestore.collection('libraryBooks').doc(book.docId).update({
          'availableCopies': newAvail,
          'status': 'Available',
        });
      }

      messenger.showSnackBar(SnackBar(content: Text('Book "${borrowing.bookTitle}" marked as Returned!'), backgroundColor: Colors.green));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to return book: $e'), backgroundColor: Colors.redAccent));
    }
  }

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
            Icon(Icons.local_library_rounded, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text('Library & Books Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.tealAccent,
          labelColor: Colors.tealAccent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Book Catalog', icon: Icon(Icons.menu_book_rounded, size: 18)),
            Tab(text: 'Borrowings & Returns', icon: Icon(Icons.assignment_ind_rounded, size: 18)),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('libraryBooks').snapshots(),
        builder: (context, bookSnap) {
          final books = (bookSnap.data?.docs ?? []).map((d) => LibraryBookModel.fromFirestore(d)).toList();

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('libraryBorrowings').snapshots(),
            builder: (context, borrowSnap) {
              final borrowings = (borrowSnap.data?.docs ?? []).map((d) => LibraryBorrowingModel.fromFirestore(d)).toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Book Catalog
                  _buildCatalogTab(books),

                  // Tab 2: Borrowings & Returns
                  _buildBorrowingsTab(borrowings, books),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCatalogTab(List<LibraryBookModel> books) {
    final filtered = books.where((b) {
      final matchesSearch = b.title.toLowerCase().contains(_searchQuery) ||
          b.author.toLowerCase().contains(_searchQuery) ||
          b.isbn.toLowerCase().contains(_searchQuery);
      final matchesCat = _selectedCategory == 'All' || b.category == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBookModal(),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Book', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search by title, author or ISBN...',
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
            child: filtered.isEmpty
                ? const Center(child: Text('No library books found.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
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
                                    '${b.availableCopies} / ${b.totalCopies} Available',
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
                            Text('ISBN: ${b.isbn} • Location: ${b.shelfLocation}', style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showBookModal(existing: b),
                                  icon: const Icon(Icons.edit, size: 14, color: Colors.tealAccent),
                                  label: const Text('Edit Book', style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBorrowingsTab(List<LibraryBorrowingModel> borrowings, List<LibraryBookModel> books) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showIssueModal(books),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.outbox_rounded, color: Colors.white),
        label: const Text('Issue Book', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: borrowings.isEmpty
          ? const Center(child: Text('No book borrowing records.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
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
                      Text(br.bookTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Student: ${br.studentName} (${br.studentId})', style: const TextStyle(color: Colors.tealAccent, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('Borrowed: ${br.borrowDate} • Due: ${br.dueDate}', style: TextStyle(color: isOver ? Colors.redAccent : Colors.grey, fontSize: 11, fontWeight: isOver ? FontWeight.bold : FontWeight.normal)),
                      if (br.returnDate != null)
                        Text('Returned: ${br.returnDate}', style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
                      if (!isRet) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _returnBook(br, books),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              icon: const Icon(Icons.assignment_turned_in_rounded, size: 14, color: Colors.white),
                              label: const Text('Mark as Returned', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}
