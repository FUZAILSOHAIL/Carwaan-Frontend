import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/connection_status_service.dart';

class ConnectionStatusWidget extends StatelessWidget {
  final bool showOnlyWhenDisconnected;
  
  const ConnectionStatusWidget({
    super.key,
    this.showOnlyWhenDisconnected = true,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final connectionService = ConnectionStatusService.instance;
      final isConnected = connectionService.isConnected.value;
      final statusDescription = connectionService.getStatusDescription();
      
      // Show only when disconnected if showOnlyWhenDisconnected is true
      if (showOnlyWhenDisconnected && isConnected) {
        return const SizedBox.shrink();
      }
      
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isConnected 
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isConnected ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isConnected ? Icons.wifi : Icons.wifi_off,
              color: isConnected ? Colors.green : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                statusDescription,
                style: TextStyle(
                  color: isConnected ? Colors.green[700] : Colors.red[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (!isConnected) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  await connectionService.checkConnectionNow();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class ConnectionStatusBar extends StatelessWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final connectionService = ConnectionStatusService.instance;
      final isConnected = connectionService.isConnected.value;
      
      if (isConnected) {
        return const SizedBox.shrink();
      }
      
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.red,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            const Text(
              'No connection to server',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () async {
                await connectionService.checkConnectionNow();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
