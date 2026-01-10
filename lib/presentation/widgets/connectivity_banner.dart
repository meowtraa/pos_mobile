import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/connectivity_service.dart';

/// Connectivity Banner Widget
/// Shows a banner when device is offline
class ConnectivityBanner extends StatelessWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: ConnectivityService.instance,
      child: Consumer<ConnectivityService>(
        builder: (context, connectivity, _) {
          return Column(
            children: [
              // Offline Banner
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: connectivity.status == ConnectionStatus.offline ? 36 : 0,
                child: connectivity.status == ConnectionStatus.offline
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Colors.orange.shade700,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_off, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Tidak ada koneksi internet - Mode Offline',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              // Main Content
              Expanded(child: child),
            ],
          );
        },
      ),
    );
  }
}
