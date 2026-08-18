import 'package:cloud_firestore/cloud_firestore.dart';

/// Stop / Pickup Point Model
class TransportStopModel {
  final String stopId;
  final String pointName;
  final String address; // or location coordinates
  final String pickupTime; // e.g. "06:45 AM"
  final String dropOffTime; // e.g. "05:15 PM"
  final int sequence;

  TransportStopModel({
    required this.stopId,
    required this.pointName,
    this.address = '',
    required this.pickupTime,
    required this.dropOffTime,
    required this.sequence,
  });

  Map<String, dynamic> toMap() {
    return {
      'stopId': stopId,
      'pointName': pointName,
      'address': address,
      'location': address,
      'pickupTime': pickupTime,
      'dropOffTime': dropOffTime,
      'sequence': sequence,
    };
  }

  factory TransportStopModel.fromMap(Map<String, dynamic> map) {
    return TransportStopModel(
      stopId: map['stopId'] ?? '',
      pointName: map['pointName'] ?? '',
      address: map['address'] ?? (map['location'] ?? ''),
      pickupTime: map['pickupTime'] ?? '',
      dropOffTime: map['dropOffTime'] ?? '',
      sequence: (map['sequence'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Transport Route Model
class TransportRouteModel {
  final String? docId;
  final String routeId;
  final String routeName;
  final String startPoint;
  final String destination;
  final double distance; // km
  final String status; // 'Active' | 'Inactive'
  final List<TransportStopModel> stops;
  final String createdAt;

  TransportRouteModel({
    this.docId,
    required this.routeId,
    required this.routeName,
    required this.startPoint,
    required this.destination,
    this.distance = 0.0,
    this.status = 'Active',
    this.stops = const [],
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  bool get isActive => status.toLowerCase() == 'active';

  List<String> get pickupPointNames => stops.map((s) => s.pointName).toList();

  Map<String, dynamic> toMap() {
    return {
      'routeId': routeId,
      'routeName': routeName,
      'startPoint': startPoint,
      'destination': destination,
      'distance': distance,
      'status': status,
      'stops': stops.map((s) => s.toMap()).toList(),
      'pickupPoints': pickupPointNames,
      'createdAt': createdAt,
    };
  }

  factory TransportRouteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawStops = (data['stops'] as List<dynamic>?) ?? [];
    final stopsList = rawStops.map((s) => TransportStopModel.fromMap(Map<String, dynamic>.from(s as Map))).toList();
    stopsList.sort((a, b) => a.sequence.compareTo(b.sequence));

    return TransportRouteModel(
      docId: doc.id,
      routeId: data['routeId'] ?? doc.id,
      routeName: data['routeName'] ?? '',
      startPoint: data['startPoint'] ?? '',
      destination: data['destination'] ?? '',
      distance: (data['distance'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'Active',
      stops: stopsList,
      createdAt: data['createdAt'] ?? '',
    );
  }
}

/// Transport Bus Model
class TransportBusModel {
  final String? docId;
  final String busId;
  final String registrationNumber;
  final String busNameOrNumber;
  final int capacity;
  final String driver;
  final String contactNumber;
  final String status; // 'Available' | 'Maintenance' | 'Inactive'
  final String createdAt;

  TransportBusModel({
    this.docId,
    required this.busId,
    required this.registrationNumber,
    required this.busNameOrNumber,
    required this.capacity,
    required this.driver,
    required this.contactNumber,
    this.status = 'Available',
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  bool get isAvailable => status.toLowerCase() == 'available';

  Map<String, dynamic> toMap() {
    return {
      'busId': busId,
      'registrationNumber': registrationNumber,
      'busNameOrNumber': busNameOrNumber,
      'capacity': capacity,
      'driver': driver,
      'contactNumber': contactNumber,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory TransportBusModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TransportBusModel(
      docId: doc.id,
      busId: data['busId'] ?? doc.id,
      registrationNumber: data['registrationNumber'] ?? '',
      busNameOrNumber: data['busNameOrNumber'] ?? (data['busNumber'] ?? ''),
      capacity: (data['capacity'] as num?)?.toInt() ?? 45,
      driver: data['driver'] ?? (data['driverName'] ?? ''),
      contactNumber: data['contactNumber'] ?? (data['driverPhone'] ?? ''),
      status: data['status'] ?? 'Available',
      createdAt: data['createdAt'] ?? '',
    );
  }
}

/// Transport Schedule Model
class TransportScheduleModel {
  final String? docId;
  final String scheduleId;
  final String routeId;
  final String routeName;
  final String busId;
  final String busRegistration;
  final List<String> operatingDays; // ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
  final String departureTime; // "06:30 AM" or "06:30"
  final String arrivalTime; // "08:15 AM" or "08:15"
  final String status; // 'Active' | 'Suspended'
  final String createdAt;

  TransportScheduleModel({
    this.docId,
    required this.scheduleId,
    required this.routeId,
    required this.routeName,
    required this.busId,
    required this.busRegistration,
    this.operatingDays = const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
    required this.departureTime,
    required this.arrivalTime,
    this.status = 'Active',
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  /// Detects whether candidate schedule conflicts with an existing schedule for the same bus
  static bool isBusScheduleConflicting({
    required TransportScheduleModel existing,
    required TransportScheduleModel candidate,
  }) {
    // If different bus, no conflict
    if (existing.busId != candidate.busId) return false;

    // Check operating days overlap
    final commonDays = existing.operatingDays
        .map((d) => d.trim().toLowerCase())
        .toSet()
        .intersection(candidate.operatingDays.map((d) => d.trim().toLowerCase()).toSet());

    if (commonDays.isEmpty) return false;

    // Helper to parse time strings like "06:30 AM" or "14:30" to minutes from midnight
    int parseToMinutes(String timeStr) {
      final clean = timeStr.trim().toUpperCase();
      final isPm = clean.contains('PM');
      final isAm = clean.contains('AM');
      final parts = clean.replaceAll('AM', '').replaceAll('PM', '').trim().split(':');
      int h = int.tryParse(parts[0]) ?? 0;
      int m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      if (isPm && h < 12) h += 12;
      if (isAm && h == 12) h = 0;
      return h * 60 + m;
    }

    final start1 = parseToMinutes(existing.departureTime);
    final end1 = parseToMinutes(existing.arrivalTime);
    final start2 = parseToMinutes(candidate.departureTime);
    final end2 = parseToMinutes(candidate.arrivalTime);

    // Overlapping condition: start1 < end2 && start2 < end1
    return start1 < end2 && start2 < end1;
  }

  Map<String, dynamic> toMap() {
    return {
      'scheduleId': scheduleId,
      'routeId': routeId,
      'routeName': routeName,
      'busId': busId,
      'busRegistration': busRegistration,
      'operatingDays': operatingDays,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory TransportScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TransportScheduleModel(
      docId: doc.id,
      scheduleId: data['scheduleId'] ?? doc.id,
      routeId: data['routeId'] ?? '',
      routeName: data['routeName'] ?? '',
      busId: data['busId'] ?? '',
      busRegistration: data['busRegistration'] ?? '',
      operatingDays: List<String>.from(data['operatingDays'] ?? ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']),
      departureTime: data['departureTime'] ?? '',
      arrivalTime: data['arrivalTime'] ?? '',
      status: data['status'] ?? 'Active',
      createdAt: data['createdAt'] ?? '',
    );
  }
}

/// Student Transport Preference Model
class StudentTransportPreferenceModel {
  final String? docId;
  final String studentId;
  final String studentEmail;
  final String selectedRouteId;
  final String selectedRouteName;
  final String selectedStopId;
  final String selectedStopName;
  final String updatedAt;

  StudentTransportPreferenceModel({
    this.docId,
    required this.studentId,
    required this.studentEmail,
    required this.selectedRouteId,
    required this.selectedRouteName,
    required this.selectedStopId,
    required this.selectedStopName,
    String? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentEmail': studentEmail,
      'selectedRouteId': selectedRouteId,
      'selectedRouteName': selectedRouteName,
      'selectedStopId': selectedStopId,
      'selectedStopName': selectedStopName,
      'updatedAt': updatedAt,
    };
  }

  factory StudentTransportPreferenceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StudentTransportPreferenceModel(
      docId: doc.id,
      studentId: data['studentId'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      selectedRouteId: data['selectedRouteId'] ?? '',
      selectedRouteName: data['selectedRouteName'] ?? '',
      selectedStopId: data['selectedStopId'] ?? '',
      selectedStopName: data['selectedStopName'] ?? '',
      updatedAt: data['updatedAt'] ?? '',
    );
  }
}

/// Backwards Compatible Transport Model
class TransportModel {
  final String? docId;
  final String routeId;
  final String routeName;
  final String busNumber;
  final String driverName;
  final String driverPhone;
  final List<String> pickupPoints;
  final String departureTime;
  final String arrivalTime;
  final String status;

  TransportModel({
    this.docId,
    required this.routeId,
    required this.routeName,
    required this.busNumber,
    required this.driverName,
    required this.driverPhone,
    required this.pickupPoints,
    required this.departureTime,
    required this.arrivalTime,
    this.status = 'on_time',
  });

  factory TransportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TransportModel(
      docId: doc.id,
      routeId: data['routeId'] ?? doc.id,
      routeName: data['routeName'] ?? '',
      busNumber: data['busNumber'] ?? (data['busRegistration'] ?? ''),
      driverName: data['driverName'] ?? (data['driver'] ?? ''),
      driverPhone: data['driverPhone'] ?? (data['contactNumber'] ?? ''),
      pickupPoints: List<String>.from(data['pickupPoints'] ?? []),
      departureTime: data['departureTime'] ?? '06:30 AM',
      arrivalTime: data['arrivalTime'] ?? '08:15 AM',
      status: data['status'] ?? 'on_time',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'routeId': routeId,
      'routeName': routeName,
      'busNumber': busNumber,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'pickupPoints': pickupPoints,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'status': status,
    };
  }
}
