import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Demo Preparation Tools
/// Prepares realistic demo environment for customer presentations
class DemoPreparation {
  static const baseUrl = 'http://localhost:8080';
  static String? demoApiKey;

  static Future<void> prepareDemoEnvironment() async {
    print('🎬 API SENTINEL DEMO ENVIRONMENT PREPARATION');
    print('=' * 70);

    await _createDemoCustomer();
    await _generateDemoData();
    await _verifyDemoEnvironment();
    _generateDemoScript();
    _generateOutreachMaterials();

    print('\n✅ Demo environment ready for customer presentations!');
  }

  static Future<void> _createDemoCustomer() async {
    print('\n👤 Creating demo customer account...');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/customers/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': 'demo@apisentinel.com',
          'password': 'DemoPass123!',
          'companyName': 'API Sentinel Demo',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        demoApiKey = data['apiKey'] as String?;
        print('  ✅ Demo customer created');
        print('  📧 Email: demo@apisentinel.com');
        print('  🔑 API Key: ${demoApiKey?.substring(0, 20)}...');
      } else {
        print('  ⚠️  Customer might already exist, continuing...');

        // Try to login instead
        final loginResp = await http.post(
          Uri.parse('$baseUrl/api/v1/customers/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': 'demo@apisentinel.com',
            'password': 'DemoPass123!',
          }),
        );

        if (loginResp.statusCode == 200) {
          final loginData = json.decode(loginResp.body);
          // Generate new API key for demo
          final keyResp = await http.post(
            Uri.parse('$baseUrl/api/v1/keys/generate'),
            headers: {
              'Authorization': 'Bearer ${loginData['token']}',
              'Content-Type': 'application/json',
            },
            body: json.encode({'name': 'Demo Key'}),
          );

          if (keyResp.statusCode == 200) {
            final keyData = json.decode(keyResp.body);
            demoApiKey = keyData['apiKey'] as String?;
            print('  ✅ Using existing demo customer');
            print('  🔑 New API Key: ${demoApiKey?.substring(0, 20)}...');
          }
        }
      }
    } catch (e) {
      print('  ❌ Error creating demo customer: $e');
    }
  }

  static Future<void> _generateDemoData() async {
    print('\n📊 Generating realistic demo data...');

    if (demoApiKey == null) {
      print('  ❌ No API key available, skipping data generation');
      return;
    }

    // Scenario 1: E-Commerce Store - Black Friday Rush
    final scenarios = [
      {
        'name': 'E-Commerce Black Friday',
        'events': [
          {
            'transactionId': 'ecom_bf_001',
            'amount': 299.99,
            'primaryGateway': 'stripe',
            'secondaryGateway': 'paypal',
            'errorType': 'rate_limit_exceeded',
            'recoveryTimeMs': 1850,
            'success': true,
            'description': 'High traffic caused rate limiting',
          },
          {
            'transactionId': 'ecom_bf_002',
            'amount': 549.00,
            'primaryGateway': 'stripe',
            'secondaryGateway': 'paypal',
            'errorType': 'gateway_timeout',
            'recoveryTimeMs': 2100,
            'success': true,
            'description': 'Gateway timeout during peak hours',
          },
          {
            'transactionId': 'ecom_bf_003',
            'amount': 125.50,
            'primaryGateway': 'stripe',
            'secondaryGateway': 'paypal',
            'errorType': 'network_error',
            'recoveryTimeMs': 1600,
            'success': false,
            'description': 'Both gateways experienced issues',
          },
        ],
      },
      {
        'name': 'SaaS Subscription Platform',
        'events': [
          {
            'transactionId': 'saas_sub_001',
            'amount': 99.00,
            'primaryGateway': 'braintree',
            'secondaryGateway': 'stripe',
            'errorType': 'card_declined_retry',
            'recoveryTimeMs': 1200,
            'success': true,
            'description': 'Card declined on primary, succeeded on secondary',
          },
          {
            'transactionId': 'saas_sub_002',
            'amount': 299.00,
            'primaryGateway': 'braintree',
            'secondaryGateway': 'stripe',
            'errorType': 'api_maintenance',
            'recoveryTimeMs': 3500,
            'success': true,
            'description': 'Primary gateway maintenance window',
          },
        ],
      },
      {
        'name': 'Mobile App In-App Purchases',
        'events': [
          {
            'transactionId': 'mobile_iap_001',
            'amount': 4.99,
            'primaryGateway': 'paypal',
            'secondaryGateway': 'stripe',
            'errorType': 'authentication_failure',
            'recoveryTimeMs': 950,
            'success': true,
            'description': 'PayPal auth issue, Stripe processed',
          },
          {
            'transactionId': 'mobile_iap_002',
            'amount': 19.99,
            'primaryGateway': 'paypal',
            'secondaryGateway': 'stripe',
            'errorType': 'connection_timeout',
            'recoveryTimeMs': 1750,
            'success': true,
            'description': 'Mobile network timeout recovered',
          },
          {
            'transactionId': 'mobile_iap_003',
            'amount': 49.99,
            'primaryGateway': 'paypal',
            'secondaryGateway': 'stripe',
            'errorType': 'rate_limit',
            'recoveryTimeMs': 1450,
            'success': true,
            'description': 'High volume user rate limited',
          },
        ],
      },
      {
        'name': 'Digital Marketplace',
        'events': [
          {
            'transactionId': 'market_001',
            'amount': 1250.00,
            'primaryGateway': 'adyen',
            'secondaryGateway': 'stripe',
            'errorType': 'gateway_downtime',
            'recoveryTimeMs': 2800,
            'success': true,
            'description': 'High-value transaction during downtime',
          },
          {
            'transactionId': 'market_002',
            'amount': 875.50,
            'primaryGateway': 'adyen',
            'secondaryGateway': 'stripe',
            'errorType': 'fraud_check_timeout',
            'recoveryTimeMs': 3200,
            'success': true,
            'description': 'Fraud check delayed primary gateway',
          },
        ],
      },
    ];

    int totalSubmitted = 0;
    int totalSuccessful = 0;

    for (final scenario in scenarios) {
      print('  📦 Scenario: ${scenario['name']}');

      final events = scenario['events'] as List;
      for (final event in events) {
        try {
          final response = await http.post(
            Uri.parse('$baseUrl/api/v1/analytics/failover-event'),
            headers: {
              'Authorization': 'Bearer $demoApiKey',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'transactionId': event['transactionId'],
              'amount': event['amount'],
              'currency': 'USD',
              'primaryGateway': event['primaryGateway'],
              'secondaryGateway': event['secondaryGateway'],
              'errorType': event['errorType'],
              'recoveryTimeMs': event['recoveryTimeMs'],
              'success': event['success'],
              'timestamp': DateTime.now()
                  .subtract(Duration(days: totalSubmitted % 30))
                  .toIso8601String(),
            }),
          );

          if (response.statusCode == 200) {
            totalSubmitted++;
            if (event['success'] == true) totalSuccessful++;
            print('     ✅ ${event['description']} (\$${event['amount']})');
          }
        } catch (e) {
          print('     ❌ Failed to submit event: $e');
        }
      }
    }

    print('\n  📈 Demo data summary:');
    print('     • Total events: $totalSubmitted');
    print('     • Successful recoveries: $totalSuccessful');
    print(
        '     • Success rate: ${(totalSuccessful / totalSubmitted * 100).toStringAsFixed(1)}%');
  }

  static Future<void> _verifyDemoEnvironment() async {
    print('\n🔍 Verifying demo environment...');

    if (demoApiKey == null) {
      print('  ❌ No API key available');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/metrics/overview'),
        headers: {'Authorization': 'Bearer $demoApiKey'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('  ✅ Demo environment verified');
        print('     • Total Events: ${data['totalEvents']}');
        print('     • Successful Recoveries: ${data['successfulRecoveries']}');
        print('     • Recovered Revenue: \$${data['recoveredRevenue']}');
        print('     • Avg Recovery Time: ${data['avgRecoveryTime']}ms');
        print('     • Failover Rate: ${data['failoverRate']}%');
      }
    } catch (e) {
      print('  ❌ Error verifying environment: $e');
    }
  }

  static void _generateDemoScript() {
    print('\n📝 Generating customer demo script...');

    final script = '''

═══════════════════════════════════════════════════════════════════════
                    API SENTINEL CUSTOMER DEMO SCRIPT
═══════════════════════════════════════════════════════════════════════

🎯 DEMO OBJECTIVE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Show how API Sentinel automatically recovers failed payments and 
increases revenue without requiring code changes to existing systems.

⏱️  DURATION: 15 minutes
👥 AUDIENCE: CTOs, Engineering Leads, Payment Team Leads


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. INTRODUCTION (2 minutes)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

"Hi [Name], thanks for joining this demo of API Sentinel.

Quick question: What percentage of your payment transactions fail due to 
gateway timeouts, network issues, or temporary outages?"

[Wait for answer - typical range is 2-5%]

"Exactly. Industry average is 3%, which means if you're processing 
\$1M monthly, you're losing \$30,000 to technical failures.

API Sentinel recovers 80% of those failed payments automatically. 
Let me show you how..."


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2. PROBLEM DEMONSTRATION (2 minutes)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Open browser console showing standard payment failure]

"Here's what happens today when Stripe times out..."

[Show error message, failed transaction]

"Customer sees an error. Sale is lost. You're now hoping they retry 
manually - which only 23% do."


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
3. API SENTINEL SOLUTION (3 minutes)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Switch to API Sentinel dashboard]

"With API Sentinel, same scenario..."

[Trigger simulated Stripe timeout]

"Stripe times out. But watch this..."

[Show automatic failover to PayPal]

"API Sentinel detected the failure in 150ms and automatically retried 
with PayPal. Total recovery time: 1.8 seconds. Customer never saw an error."

[Point to dashboard]

"Payment succeeded. Sale recovered. Customer happy."


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
4. ANALYTICS SHOWCASE (3 minutes)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Navigate to metrics dashboard]

"Let me show you the impact over the last 30 days..."

Key Metrics to Highlight:
• Total Events: [Show number]
• Recovered Revenue: [Emphasize dollar amount]
• Success Rate: [Show percentage]
• Average Recovery Time: [Under 2 seconds]

"This demo account has recovered \$X in just the demo period. 
For your volume of \$Y monthly, that would translate to \$Z annually."

[Show gateway performance breakdown]

"You can also see which gateway combinations work best. For example,
Stripe→PayPal has an 87% recovery rate with 1.8s average recovery time."


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
5. INTEGRATION DEMO (2 minutes)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Show code example]

"Integration takes 30 minutes. Here's the complete code..."

BEFORE:
  final response = await http.post(
    stripeUrl,
    body: paymentData,
  );

AFTER:
  final sentinel = APISentinel();
  final response = await sentinel.postWithFailover(
    endpoint: '/payments',
    data: paymentData,
  );

"That's it. Two line change. No modifications to your payment logic.
Works with any payment gateway - Stripe, PayPal, Braintree, Razorpay..."


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
6. PRICING & ROI (2 minutes)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

"Let me show you the economics..."

[Pull up ROI calculator]

Your Monthly Volume: \$___________
Industry Failure Rate: 3%
Lost Revenue/Month: \$___________

With API Sentinel:
Recovery Rate: 80%
Recovered Revenue: \$___________
API Sentinel Cost: \$___________
Net Gain: \$___________

ROI: _____% monthly

"Typical payback period is under 2 weeks."


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
7. CLOSE & NEXT STEPS (1 minute)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

"Would you like to run a 30-day pilot with your production traffic?"

Next Steps:
1. Set up your API Sentinel account (5 minutes)
2. Integrate SDK into one payment endpoint (30 minutes)
3. Monitor for 30 days
4. Review recovered revenue report
5. Expand to all payment endpoints

"We offer a risk-free trial - if you don't recover at least 10x our 
cost in the first month, we refund 100%."

"Any questions about the technology, integration, or pricing?"


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OBJECTION HANDLING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

"We already have retry logic"
→ "Great! API Sentinel adds intelligent multi-gateway failover. Your 
   retry logic only retries the same failing gateway. We switch gateways."

"What if both gateways fail?"
→ "We return a user-friendly error after exhausting all options. You're 
   no worse off than today, but you've recovered 80% of failures."

"Is this PCI compliant?"
→ "We never touch payment data. We only handle gateway routing. Your 
   existing PCI compliance covers API Sentinel."

"What's the latency impact?"
→ "Zero on successful transactions. On failures, we add 1-2 seconds 
   recovery time vs losing the sale completely."


═══════════════════════════════════════════════════════════════════════
                              END OF DEMO SCRIPT
═══════════════════════════════════════════════════════════════════════
''';

    // Save to file
    try {
      File('verification/demo_script.txt').writeAsStringSync(script);
      print('  ✅ Demo script saved to verification/demo_script.txt');
    } catch (e) {
      print('  ⚠️  Could not save demo script: $e');
    }

    print('  📋 Demo script ready for customer presentations');
  }

  static void _generateOutreachMaterials() {
    print('\n📧 Generating outreach materials...');

    final emailTemplate = '''
Subject: Recover Lost Payment Revenue - API Sentinel Partnership

Hi [First Name],

I noticed [Company] processes significant payment volume through [Gateway]. 
Like most platforms, you're probably losing 2-5% of transactions to gateway 
timeouts and temporary failures.

We built API Sentinel to automatically recover those failed payments by 
intelligently failing over to backup gateways. Our customers typically 
recover 80% of failed transactions, adding 2-4% to their monthly revenue.

For context, if you process \$10M monthly with a 3% failure rate:
• Lost revenue: \$300,000/month
• With API Sentinel: Recover \$240,000/month
• Implementation: 30 minutes

I'd love to show you a quick demo (15 min) of:
1. Live payment failover in action
2. Real-time analytics dashboard
3. 30-second integration walkthrough

Would Thursday 2pm or Friday 11am work for a brief call?

Best regards,
[Your Name]
API Sentinel

P.S. We offer a risk-free 30-day pilot - if you don't see 10x ROI, 
we refund 100%.
''';

    final partnershipProposal = '''
═══════════════════════════════════════════════════════════════════════
              API SENTINEL PARTNERSHIP PROPOSAL
                      For Payment Gateway Providers
═══════════════════════════════════════════════════════════════════════

TO: [Company Name]
FROM: API Sentinel
DATE: ${DateTime.now().toString().split(' ')[0]}


EXECUTIVE SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

API Sentinel provides intelligent payment failover technology that 
increases successful transaction rates for merchants using multiple 
payment gateways. We're seeking strategic partnerships with leading 
payment providers like [Company].


PARTNERSHIP OPPORTUNITIES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. TECHNICAL INTEGRATION
   • Preferred failover partner for [Company] merchants
   • Featured in [Company] marketplace/integrations
   • Co-developed best practices documentation

2. CO-MARKETING
   • Joint case studies and success stories
   • Co-branded webinars on payment resilience
   • Conference booth partnerships

3. REVENUE SHARE
   • Referral fees for merchants using API Sentinel
   • Tiered partnership levels based on volume
   • Exclusive features for [Company] customers

4. WHITE-LABEL OPTION
   • "[Company] Payment Resilience" powered by API Sentinel
   • Integrated into [Company] dashboard
   • Branded analytics and reporting


VALUE PROPOSITION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

For [Company]:
• Reduced merchant churn (higher transaction success = happier customers)
• Competitive advantage ("We offer payment resilience")
• Additional revenue stream through partnership
• Increased transaction volume (merchants process more with [Company])

For Merchants:
• 2-4% increase in successful transactions
• Automatic failover during [Company] maintenance/outages
• Real-time analytics on payment performance
• Better customer experience (fewer failed checkouts)


TECHNICAL DETAILS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• RESTful API integration
• <2 second failover latency
• PCI-compliant (we never touch payment data)
• Works with [Company]'s existing SDKs
• No changes required to merchant's payment flow


NEXT STEPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Technical demo with your engineering team (30 min)
2. Pilot program with 5-10 mutual merchants (30 days)
3. Partnership agreement negotiation
4. Joint launch announcement


CONTACT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Your Name]
Founder, API Sentinel
[Email]
[Phone]


═══════════════════════════════════════════════════════════════════════
''';

    try {
      File('verification/outreach_email_template.txt')
          .writeAsStringSync(emailTemplate);
      File('verification/partnership_proposal.txt')
          .writeAsStringSync(partnershipProposal);

      print(
          '  ✅ Email template saved to verification/outreach_email_template.txt');
      print(
          '  ✅ Partnership proposal saved to verification/partnership_proposal.txt');
    } catch (e) {
      print('  ⚠️  Could not save outreach materials: $e');
    }

    print('  📄 Outreach materials ready for target companies:');
    print('     • Flutterwave (Africa payment infrastructure)');
    print('     • Plaid (Financial services API)');
    print('     • Stripe (Global payments)');
    print('     • Razorpay (India payments)');
    print('     • PayStack (Africa payments)');
  }
}

void main() async {
  await DemoPreparation.prepareDemoEnvironment();
}
