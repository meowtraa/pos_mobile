import 'package:flutter/material.dart';

/// Error Dialog Widget
/// Standard dialog for showing errors with retry option
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onClose;

  const ErrorDialog({super.key, this.title = 'Terjadi Kesalahan', required this.message, this.onRetry, this.onClose});

  /// Show error dialog
  static Future<void> show(
    BuildContext context, {
    String title = 'Terjadi Kesalahan',
    required String message,
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) =>
          ErrorDialog(title: title, message: message, onRetry: onRetry, onClose: () => Navigator.pop(ctx)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colorScheme.errorContainer, shape: BoxShape.circle),
        child: Icon(Icons.error_outline, size: 32, color: colorScheme.error),
      ),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        if (onRetry != null)
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onRetry?.call();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        FilledButton(onPressed: onClose ?? () => Navigator.pop(context), child: const Text('Tutup')),
      ],
    );
  }
}
