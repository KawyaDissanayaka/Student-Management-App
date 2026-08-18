import 'package:cloud_firestore/cloud_firestore.dart';

/// Library Book Model
class LibraryBookModel {
  final String? docId;
  final String bookId;
  final String isbn;
  final String title;
  final String author;
  final String category; // 'Computer Science', 'Software Engineering', 'Mathematics', 'Business', 'Science', 'Literature'
  final String publisher;
  final String edition;
  final int totalCopies;
  final int availableCopies;
  final String shelfLocation; // e.g. "Rack C-04", "Floor 2, Row A"
  final String status; // 'Available', 'Unavailable', 'Archived'
  final String createdAt;

  LibraryBookModel({
    this.docId,
    required this.bookId,
    required this.isbn,
    required this.title,
    required this.author,
    required this.category,
    this.publisher = '',
    this.edition = '1st Edition',
    required this.totalCopies,
    int? availableCopies,
    this.shelfLocation = 'Main Library Floor 1',
    String? status,
    String? createdAt,
  })  : availableCopies = (availableCopies ?? totalCopies).clamp(0, totalCopies),
        status = status ?? ((availableCopies ?? totalCopies) > 0 ? 'Available' : 'Unavailable'),
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  static const List<String> supportedStatuses = ['Available', 'Unavailable', 'Archived'];
  static const List<String> supportedCategories = [
    'Computer Science',
    'Software Engineering',
    'Information Technology',
    'Mathematics & Statistics',
    'Business & Management',
    'Science & Engineering',
    'General Literature',
  ];

  bool get isAvailable => status == 'Available' && availableCopies > 0;
  bool get isArchived => status == 'Archived';

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'isbn': isbn,
      'title': title,
      'author': author,
      'category': category,
      'publisher': publisher,
      'edition': edition,
      'totalCopies': totalCopies,
      'availableCopies': availableCopies,
      'shelfLocation': shelfLocation,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory LibraryBookModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final total = (data['totalCopies'] as num?)?.toInt() ?? 1;
    final avail = (data['availableCopies'] as num?)?.toInt() ?? total;

    return LibraryBookModel(
      docId: doc.id,
      bookId: data['bookId'] ?? doc.id,
      isbn: data['isbn'] ?? '',
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      category: data['category'] ?? 'Computer Science',
      publisher: data['publisher'] ?? '',
      edition: data['edition'] ?? '1st Edition',
      totalCopies: total,
      availableCopies: avail.clamp(0, total),
      shelfLocation: data['shelfLocation'] ?? 'Main Library Floor 1',
      status: data['status'] ?? (avail > 0 ? 'Available' : 'Unavailable'),
      createdAt: data['createdAt'] ?? '',
    );
  }

  factory LibraryBookModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final total = (map['totalCopies'] as num?)?.toInt() ?? 1;
    final avail = (map['availableCopies'] as num?)?.toInt() ?? total;

    return LibraryBookModel(
      docId: id,
      bookId: map['bookId'] ?? '',
      isbn: map['isbn'] ?? '',
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      category: map['category'] ?? 'Computer Science',
      publisher: map['publisher'] ?? '',
      edition: map['edition'] ?? '1st Edition',
      totalCopies: total,
      availableCopies: avail.clamp(0, total),
      shelfLocation: map['shelfLocation'] ?? 'Main Library Floor 1',
      status: map['status'] ?? (avail > 0 ? 'Available' : 'Unavailable'),
      createdAt: map['createdAt'] ?? '',
    );
  }
}

/// Library Borrowing Record Model
class LibraryBorrowingModel {
  final String? docId;
  final String borrowingId;
  final String bookId;
  final String bookTitle;
  final String isbn;
  final String studentId;
  final String studentEmail;
  final String studentName;
  final String borrowDate; // "YYYY-MM-DD"
  final String dueDate; // "YYYY-MM-DD"
  final String? returnDate; // "YYYY-MM-DD" or null
  final String status; // 'Borrowed', 'Returned', 'Overdue'
  final String issuedBy;
  final String? returnedTo;
  final String createdAt;

  LibraryBorrowingModel({
    this.docId,
    required this.borrowingId,
    required this.bookId,
    required this.bookTitle,
    this.isbn = '',
    required this.studentId,
    required this.studentEmail,
    required this.studentName,
    required this.borrowDate,
    required this.dueDate,
    this.returnDate,
    this.status = 'Borrowed',
    this.issuedBy = 'Librarian',
    this.returnedTo,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  /// Computed effective status accounting for overdue dates when not returned
  String get effectiveStatus {
    if (status.toLowerCase() == 'returned') return 'Returned';

    try {
      final due = DateTime.parse(dueDate);
      final now = DateTime.now();
      // If current date is after due date, mark overdue
      if (now.isAfter(DateTime(due.year, due.month, due.day, 23, 59, 59))) {
        return 'Overdue';
      }
    } catch (_) {}

    return status;
  }

  bool get isOverdue => effectiveStatus == 'Overdue';
  bool get isReturned => effectiveStatus == 'Returned';

  Map<String, dynamic> toMap() {
    return {
      'borrowingId': borrowingId,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'isbn': isbn,
      'studentId': studentId,
      'studentEmail': studentEmail,
      'studentName': studentName,
      'borrowDate': borrowDate,
      'dueDate': dueDate,
      'returnDate': returnDate,
      'status': status,
      'issuedBy': issuedBy,
      'returnedTo': returnedTo,
      'createdAt': createdAt,
    };
  }

  factory LibraryBorrowingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return LibraryBorrowingModel(
      docId: doc.id,
      borrowingId: data['borrowingId'] ?? doc.id,
      bookId: data['bookId'] ?? '',
      bookTitle: data['bookTitle'] ?? '',
      isbn: data['isbn'] ?? '',
      studentId: data['studentId'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      studentName: data['studentName'] ?? '',
      borrowDate: data['borrowDate'] ?? '',
      dueDate: data['dueDate'] ?? '',
      returnDate: data['returnDate'],
      status: data['status'] ?? 'Borrowed',
      issuedBy: data['issuedBy'] ?? 'Librarian',
      returnedTo: data['returnedTo'],
      createdAt: data['createdAt'] ?? '',
    );
  }
}
