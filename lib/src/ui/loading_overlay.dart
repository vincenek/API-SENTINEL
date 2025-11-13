import 'package:flutter/material.dart';

/// Loading overlay widget for payment processing
///
/// Shows a modal overlay with loading indicator and optional message
/// while payment is being processed with failover protection.
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? overlayColor;
  final Color? indicatorColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.overlayColor,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: overlayColor ?? Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          indicatorColor ?? Theme.of(context).primaryColor,
                        ),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          message!,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Payment status widget
///
/// Shows payment status with icon and message
class PaymentStatusWidget extends StatelessWidget {
  final bool success;
  final String message;
  final bool failoverUsed;
  final String? gatewayUsed;
  final VoidCallback? onDismiss;

  const PaymentStatusWidget({
    super.key,
    required this.success,
    required this.message,
    this.failoverUsed = false,
    this.gatewayUsed,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              success ? 'Payment Successful' : 'Payment Failed',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (failoverUsed) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 16,
                      color: Colors.orange.shade900,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Recovered via failover',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (gatewayUsed != null) ...[
              const SizedBox(height: 8),
              Text(
                'Gateway: $gatewayUsed',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ],
            if (onDismiss != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onDismiss,
                child: const Text('Dismiss'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Failover indicator badge
///
/// Small badge to show that failover protection is active
class FailoverIndicatorBadge extends StatelessWidget {
  final bool isActive;
  final VoidCallback? onTap;

  const FailoverIndicatorBadge({super.key, this.isActive = true, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.green.shade400 : Colors.grey.shade400,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield,
              size: 14,
              color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              'Failover ${isActive ? 'Active' : 'Inactive'}',
              style: TextStyle(
                color: isActive ? Colors.green.shade900 : Colors.grey.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gateway status indicator
///
/// Shows the status of a payment gateway
class GatewayStatusIndicator extends StatelessWidget {
  final String gatewayName;
  final bool isOnline;
  final String? statusMessage;

  const GatewayStatusIndicator({
    super.key,
    required this.gatewayName,
    required this.isOnline,
    this.statusMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gatewayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (statusMessage != null)
                  Text(
                    statusMessage!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: isOnline ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
