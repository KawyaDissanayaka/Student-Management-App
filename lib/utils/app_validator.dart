import 'package:flutter/foundation.dart';

class AppValidator {
  /// Validates that a string value is not empty or blank
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  /// Validates standard email address format
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required.';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  /// Validates phone number format
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.';
    }
    final phoneRegex = RegExp(r'^\+?[0-9\s\-()]{7,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number.';
    }
    return null;
  }

  /// Validates that input is a strictly positive number (> 0)
  static String? validatePositiveNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    final numValue = num.tryParse(value.trim());
    if (numValue == null) {
      return '$fieldName must be a valid number.';
    }
    if (numValue <= 0) {
      return '$fieldName must be greater than zero.';
    }
    return null;
  }

  /// Validates that input is a non-negative number (>= 0)
  static String? validateNonNegativeNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    final numValue = num.tryParse(value.trim());
    if (numValue == null) {
      return '$fieldName must be a valid number.';
    }
    if (numValue < 0) {
      return '$fieldName cannot be negative.';
    }
    return null;
  }

  /// Validates exam/assignment marks between 0 and maximum marks
  static String? validateMarks(String? value, {double maxMarks = 100.0}) {
    if (value == null || value.trim().isEmpty) {
      return 'Marks are required.';
    }
    final numValue = double.tryParse(value.trim());
    if (numValue == null) {
      return 'Marks must be a valid number.';
    }
    if (numValue < 0.0) {
      return 'Marks cannot be negative.';
    }
    if (numValue > maxMarks) {
      return 'Marks cannot exceed $maxMarks.';
    }
    return null;
  }

  /// Validates that credits are between minimum and maximum bounds
  static String? validateCreditBounds(int credits, {int minCredits = 1, int maxCredits = 30}) {
    if (credits < minCredits) {
      return 'Credits must be at least $minCredits.';
    }
    if (credits > maxCredits) {
      return 'Credits cannot exceed $maxCredits per semester.';
    }
    return null;
  }

  /// Validates chronological order: startDate must be strictly before endDate
  static String? validateDateRange(DateTime? startDate, DateTime? endDate, {String startLabel = 'Start Date', String endLabel = 'End Date'}) {
    if (startDate == null) {
      return '$startLabel is required.';
    }
    if (endDate == null) {
      return '$endLabel is required.';
    }
    if (endDate.isBefore(startDate)) {
      return '$endLabel cannot be before $startLabel.';
    }
    if (endDate.isAtSameMomentAs(startDate)) {
      return '$endLabel must be after $startLabel.';
    }
    return null;
  }

  /// Sanitizes cryptic Firebase and network exception codes into clean, user-friendly messages
  static String sanitizeFirebaseError(dynamic error) {
    debugPrint('[ERROR_LOG] Technical details: $error');

    final errStr = error.toString().toLowerCase();

    if (errStr.contains('permission-denied') || errStr.contains('permission denied')) {
      return 'Access Denied: You do not have permission to perform this action.';
    }
    if (errStr.contains('user-not-found') || errStr.contains('wrong-password') || errStr.contains('invalid-credential')) {
      return 'Invalid credentials. Please verify your email and password.';
    }
    if (errStr.contains('not-found') || errStr.contains('document does not exist')) {
      return 'Requested resource was not found. It may have been removed.';
    }
    if (errStr.contains('network-request-failed') || errStr.contains('socketexception') || errStr.contains('offline') || errStr.contains('unavailable')) {
      return 'Network Error: Please check your internet connection and try again.';
    }
    if (errStr.contains('user-not-found') || errStr.contains('wrong-password') || errStr.contains('invalid-credential')) {
      return 'Invalid credentials. Please verify your email and password.';
    }
    if (errStr.contains('email-already-in-use')) {
      return 'This email address is already registered in the system.';
    }
    if (errStr.contains('weak-password')) {
      return 'Password is too weak. Please use at least 6 characters.';
    }
    if (errStr.contains('already-exists') || errStr.contains('duplicate')) {
      return 'A record with this identifier already exists.';
    }
    if (errStr.contains('deadline-exceeded') || errStr.contains('timeout')) {
      return 'Operation timed out. Please try again.';
    }

    return 'An unexpected error occurred. Please try again or contact support.';
  }
}
