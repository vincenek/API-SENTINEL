import 'package:flutter/material.dart';
import 'package:apisentinei/api_sentinel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API Sentinel Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PaymentDemoPage(
        title: 'API Sentinel - Payment Failover Demo',
      ),
    );
  }
}

class PaymentDemoPage extends StatefulWidget {
  const PaymentDemoPage({super.key, required this.title});

  final String title;

  @override
  State<PaymentDemoPage> createState() => _PaymentDemoPageState();
}

class _PaymentDemoPageState extends State<PaymentDemoPage> {
  late APISentinel _sentinel;
  bool _isInitialized = false;
  bool _isProcessing = false;
  SentinelResponse<Map<String, dynamic>>? _lastResponse;

  final TextEditingController _amountController = TextEditingController(
    text: '100.00',
  );
  final TextEditingController _currencyController = TextEditingController(
    text: 'USD',
  );

  @override
  void initState() {
    super.initState();
    _initializeSentinel();
  }

  Future<void> _initializeSentinel() async {
    try {
      _sentinel = APISentinel(
        baseUrl: 'https://api.apisentinel.com', // Replace with your backend URL
        apiKey:
            'demo-api-key-replace-with-real-key', // Replace with your API key
        primaryGateway: 'stripe',
        secondaryGateway: 'paypal',
        enableAnalytics: true,
        customerId: 'demo-customer-123',
        enableDebugLogging: true,
      );

      await _sentinel.init();

      setState(() {
        _isInitialized = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API Sentinel initialized successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processPayment() async {
    if (!_isInitialized) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('SDK not initialized yet')));
      return;
    }

    setState(() {
      _isProcessing = true;
      _lastResponse = null;
    });

    try {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final currency = _currencyController.text.toUpperCase();

      final response = await _sentinel.postWithFailover(
        endpoint: '/process-payment',
        data: {
          'amount': amount,
          'currency': currency,
          'paymentMethod': 'pm_card_visa',
          'customerEmail': 'demo@example.com',
        },
      );

      setState(() {
        _lastResponse = response;
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.success
                  ? 'Payment successful! ${response.failoverUsed ? "(Recovered via failover)" : ""}'
                  : 'Payment failed: ${response.errorMessage}',
            ),
            backgroundColor: response.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _currencyController.dispose();
    if (_isInitialized) {
      _sentinel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: LoadingOverlay(
        isLoading: _isProcessing,
        message: 'Processing payment with failover protection...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isInitialized ? Icons.check_circle : Icons.pending,
                            color: _isInitialized
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SDK Status: ${_isInitialized ? "Initialized" : "Initializing..."}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isInitialized) ...[
                        const FailoverIndicatorBadge(isActive: true),
                        const SizedBox(height: 12),
                        const GatewayStatusIndicator(
                          gatewayName: 'Stripe (Primary)',
                          isOnline: true,
                          statusMessage: 'Ready',
                        ),
                        const SizedBox(height: 8),
                        const GatewayStatusIndicator(
                          gatewayName: 'PayPal (Secondary)',
                          isOnline: true,
                          statusMessage: 'Backup ready',
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Payment Form
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Payment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _currencyController,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isInitialized && !_isProcessing
                              ? _processPayment
                              : null,
                          icon: const Icon(Icons.payment),
                          label: const Text('Process Payment'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Last Response
              if (_lastResponse != null)
                PaymentStatusWidget(
                  success: _lastResponse!.success,
                  message: _lastResponse!.success
                      ? 'Payment processed successfully!'
                      : _lastResponse!.errorMessage ?? 'Unknown error',
                  failoverUsed: _lastResponse!.failoverUsed,
                  gatewayUsed: _lastResponse!.gatewayUsed,
                  onDismiss: () {
                    setState(() {
                      _lastResponse = null;
                    });
                  },
                ),

              const SizedBox(height: 24),

              // Info Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'How It Works',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '1. Payment is first attempted with the primary gateway (Stripe)\n'
                        '2. If it fails with a recoverable error, it automatically fails over to the secondary gateway (PayPal)\n'
                        '3. All events are tracked and sent to your API Sentinel dashboard\n'
                        '4. You get detailed analytics on recovery rates and revenue saved',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
