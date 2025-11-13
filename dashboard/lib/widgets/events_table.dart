import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class EventsTable extends StatelessWidget {
  const EventsTable({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = context.watch<ApiService>();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: apiService.getEvents(limit: 100),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No failover events yet'),
            ),
          );
        }

        return Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Timestamp')),
                DataColumn(label: Text('Primary Gateway')),
                DataColumn(label: Text('Secondary Gateway')),
                DataColumn(label: Text('Error Type')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Recovery Time')),
              ],
              rows: events.map((event) {
                final timestamp = DateTime.parse(event['timestamp']);
                final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

                return DataRow(
                  cells: [
                    DataCell(Text(dateFormat.format(timestamp))),
                    DataCell(Text(event['primaryGateway'] ?? 'N/A')),
                    DataCell(Text(event['secondaryGateway'] ?? 'N/A')),
                    DataCell(
                      Chip(
                        label: Text(
                          event['errorType'] ?? 'unknown',
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.orange[100],
                      ),
                    ),
                    DataCell(Text(
                        '\$${event['amount']?.toStringAsFixed(2) ?? '0.00'} ${event['currency'] ?? 'USD'}')),
                    DataCell(
                      Icon(
                        event['success'] == true
                            ? Icons.check_circle
                            : Icons.error,
                        color: event['success'] == true
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    DataCell(Text('${event['recoveryTimeMs'] ?? 0}ms')),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
