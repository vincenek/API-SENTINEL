import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/metrics_card.dart';
import '../widgets/revenue_chart.dart';
import '../widgets/events_table.dart';
import '../widgets/api_keys_section.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final companyName = auth.customer?['companyName'] ?? 'Dashboard';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.security),
            const SizedBox(width: 12),
            const Text('API Sentinel'),
            const Spacer(),
            Text(
              companyName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthService>().logout();
              },
              tooltip: 'Logout',
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: Text('Analytics'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.key_outlined),
                selectedIcon: Icon(Icons.key),
                label: Text('API Keys'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const OverviewTab();
      case 1:
        return const AnalyticsTab();
      case 2:
        return const ApiKeysTab();
      case 3:
        return const SettingsTab();
      default:
        return const OverviewTab();
    }
  }
}

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = context.watch<ApiService>();

    return RefreshIndicator(
      onRefresh: () async {
        // Trigger rebuild
        (context as Element).markNeedsBuild();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            
            FutureBuilder<Map<String, dynamic>>(
              future: apiService.getMetricsOverview(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                final metrics = snapshot.data!;
                
                return Column(
                  children: [
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        MetricsCard(
                          title: 'Total Events',
                          value: metrics['totalEvents'].toString(),
                          icon: Icons.event,
                          color: Colors.blue,
                        ),
                        MetricsCard(
                          title: 'Success Rate',
                          value: '${(metrics['failoverRate'] * 100).toStringAsFixed(1)}%',
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                        MetricsCard(
                          title: 'Recovered Revenue',
                          value: '\$${metrics['recoveredRevenue'].toStringAsFixed(2)}',
                          icon: Icons.attach_money,
                          color: Colors.orange,
                        ),
                        MetricsCard(
                          title: 'Avg Recovery Time',
                          value: '${metrics['averageRecoveryTime'].toStringAsFixed(0)}ms',
                          icon: Icons.speed,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const RevenueChart(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Failover Events',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          EventsTable(),
        ],
      ),
    );
  }
}

class ApiKeysTab extends StatelessWidget {
  const ApiKeysTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'API Keys',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          ApiKeysSection(),
        ],
      ),
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final customer = auth.customer;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Company', customer?['companyName'] ?? 'N/A'),
                  const Divider(height: 32),
                  _buildInfoRow('Email', customer?['email'] ?? 'N/A'),
                  const Divider(height: 32),
                  _buildInfoRow('Primary Gateway', customer?['primaryGateway'] ?? 'N/A'),
                  const Divider(height: 32),
                  _buildInfoRow('Secondary Gateway', customer?['secondaryGateway'] ?? 'N/A'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
