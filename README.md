# API Sentinel 🛡️# API Sentinel - Flutter SDK



**Stop losing money to payment failures.** Automatic failover system that recovers failed transactions in real-time.![API Sentinel Logo](https://apisentinel.com/logo.png)



---**Automatic Payment Failover Recovery for B2B FinTech Applications**



## 🚀 Production API (Live Now!)API Sentinel is a powerful Flutter SDK that provides intelligent payment gateway failover, automatically switching to a backup gateway when the primary fails, ensuring maximum payment success rates and revenue recovery.



```## 🚀 Features

https://95477e84-9911-4614-bb62-52ba832fcb90-00-1a973zog8mm4f.janeway.replit.dev:8080

```- ✅ **Automatic Failover**: Seamlessly switch to secondary gateway on primary failure

- ✅ **Real-time Analytics**: Track all failover events and recovery metrics

**Health:** https://95477e84-9911-4614-bb62-52ba832fcb90-00-1a973zog8mm4f.janeway.replit.dev:8080/health- ✅ **Secure Storage**: API keys stored securely using flutter_secure_storage

- ✅ **Customizable Configuration**: Flexible setup for multiple payment gateways

---- ✅ **Optional UI Components**: Pre-built widgets for loading states and payment status

- ✅ **Comprehensive Error Handling**: Smart error classification and recovery

## 📦 Installation- ✅ **Recovery Time Metrics**: Measure and optimize failover performance

- ✅ **Debug Logging**: Built-in logger for development and troubleshooting

```yaml

dependencies:## 📦 Installation

  apisentinei:

    git:Add this to your `pubspec.yaml`:

      url: https://github.com/vincenek/API-SENTINEL.git

``````yaml

dependencies:

```bash  apisentinei: ^1.0.0

flutter pub get```

```

Then run: `flutter pub get`

---

## 🔑 Getting Your API Key

## ⚡ Quick Start

1. Visit [API Sentinel Dashboard](https://dashboard.apisentinel.com)

```dart2. Sign up for a free account

import 'package:apisentinei/api_sentinel.dart';3. Create a new project and configure your payment gateways

4. Copy your API key from the dashboard

final sentinel = APISentinel(

  config: SentinelConfig(## 🎯 Quick Start

    baseUrl: 'https://95477e84-9911-4614-bb62-52ba832fcb90-00-1a973zog8mm4f.janeway.replit.dev:8080',

    apiKey: 'YOUR_API_KEY',  // Get from signup### 1. Initialize the SDK

    primaryGateway: GatewayConfig(

      name: 'Stripe',```dart

      endpoint: 'https://api.stripe.com',import 'package:apisentinei/api_sentinel.dart';

      apiKey: 'sk_live_...',

    ),final sentinel = APISentinel(

    fallbackGateways: [  baseUrl: 'https://api.apisentinel.com',

      GatewayConfig(  apiKey: 'your-api-key-here',

        name: 'Paystack',  primaryGateway: 'stripe',

        endpoint: 'https://api.paystack.co',  secondaryGateway: 'paypal',

        apiKey: 'sk_live_...',  enableAnalytics: true,

      ),  customerId: 'your-company-id',

    ],);

  ),

);await sentinel.init();

```

// If Stripe fails, automatically tries Paystack

final result = await sentinel.processPayment(### 2. Process Payments with Failover

  amount: 5000.0,

  currency: 'USD',```dart

  customerEmail: 'customer@example.com',final response = await sentinel.postWithFailover(

);  endpoint: '/process-payment',

  data: {

print('Success: ${result.success}');    'amount': 100.0,

print('Revenue Saved: \$${result.revenueSaved}');    'currency': 'USD',

```    'paymentMethod': 'pm_card_visa',

  },

---);



## 🎯 What Problem Does This Solve?if (response.success) {

  if (response.failoverUsed) {

**3% of online payments fail** due to temporary gateway issues, network problems, or rate limits.    print('✨ Recovered via failover in ${response.recoveryTimeMs}ms');

  }

For a business processing **$500K/month**, that's **$15,000 lost monthly** ($180K/year).}

```

**API Sentinel** catches these failures and retries with backup gateways **instantly** - recovering 80%+ of failed transactions.

## 📚 Documentation

---

- **Full API Reference**: See inline documentation in code

## 💰 Pricing- **UI Components**: LoadingOverlay, PaymentStatusWidget, FailoverIndicatorBadge

- **Examples**: Check `lib/main.dart` for a complete demo

- **$0 monthly fee**

- **2% of recovered transactions only**## 🔒 Security

- **No setup costs**

- API keys stored using `flutter_secure_storage`

**Example:** We recover $10,000 → You pay $200. We recover $0 → You pay $0.- HTTPS-only communication

- No sensitive payment data stored locally

---

## 🤝 Support

## 🔑 Get API Key

- 📧 Email: support@apisentinel.com

1. Visit landing page *(link needed)*- 📚 Docs: [docs.apisentinel.com](https://docs.apisentinel.com)

2. Enter your email

3. Get instant API key---

4. Integrate in 30 minutes

5. Start recovering revenue**Built with ❤️ for Flutter developers**


---

## 📊 Dashboard Features

- Real-time success/failure rates
- Revenue recovery tracking
- Gateway performance metrics
- Downtime alerts
- Transaction logs

---

## 🛠️ Support

- **Docs:** https://95477e84-9911-4614-bb62-52ba832fcb90-00-1a973zog8mm4f.janeway.replit.dev:8080/api/v1/docs
- **Issues:** https://github.com/vincenek/API-SENTINEL/issues
- **Email:** support@apisentinel.com

---

**Built to save your revenue** 💰
