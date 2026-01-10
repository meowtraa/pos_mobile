import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

/// Helper Functions
/// Utility functions used throughout the app

/// Format currency
String formatCurrency(num amount, {bool showSymbol = true}) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: showSymbol ? AppConstants.currencySymbol : '',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

/// Format date
String formatDate(DateTime date, {String? format}) {
  return DateFormat(format ?? AppConstants.dateFormat).format(date);
}

/// Format time
String formatTime(DateTime time, {String? format}) {
  return DateFormat(format ?? AppConstants.timeFormat).format(time);
}

/// Format date and time
String formatDateTime(DateTime dateTime, {String? format}) {
  return DateFormat(format ?? AppConstants.dateTimeFormat).format(dateTime);
}

/// Show snackbar
void showSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
  Duration duration = const Duration(seconds: 3),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ),
  );
}

/// Show loading dialog
void showLoadingDialog(BuildContext context, {String? message}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [const CircularProgressIndicator(), const SizedBox(width: 20), Text(message ?? 'Loading...')],
        ),
      ),
    ),
  );
}

/// Hide loading dialog
void hideLoadingDialog(BuildContext context) {
  Navigator.of(context).pop();
}

/// Show confirmation dialog
Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Yes',
  String cancelText = 'No',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(cancelText)),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(confirmText)),
      ],
    ),
  );
  return result ?? false;
}

/// Truncate text
String truncateText(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}...';
}

/// Validate email
bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}

/// Validate phone
bool isValidPhone(String phone) {
  return RegExp(r'^[0-9]{10,13}$').hasMatch(phone);
}
