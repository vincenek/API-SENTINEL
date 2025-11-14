import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../services/database_service.dart';

class AdminHandler {
  final DatabaseService database;

  AdminHandler(this.database);

  /// GET /api/v1/admin/customers - Get all customers
  Future<Response> getAllCustomers(Request request) async {
    try {
      final customers = await database.getAllCustomers();

      final customersData = customers.map((customer) {
        return {
          'id': customer.id,
          'company_name': customer.companyName,
          'email': customer.email,
          'primary_gateway': customer.primaryGateway,
          'secondary_gateway': customer.secondaryGateway,
          'created_at': customer.createdAt.toIso8601String(),
        };
      }).toList();

      return Response.ok(
        json.encode({'customers': customersData}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to get customers: $e'}),
      );
    }
  }

  /// GET /api/v1/admin/stats - Get aggregate statistics
  Future<Response> getAdminStats(Request request) async {
    try {
      // Get all customers
      final customers = await database.getAllCustomers();
      final activeCustomers = customers.length;

      // Get all failover events
      final allEvents = await database.getAllFailoverEvents();
      final successfulEvents = allEvents.where((e) => e.success).toList();

      // Calculate total recovered revenue
      double totalRevenue = 0;
      for (final event in successfulEvents) {
        totalRevenue += event.amount;
      }

      // Calculate success rate
      final successRate = allEvents.isEmpty
          ? 0.0
          : (successfulEvents.length / allEvents.length * 100);

      // Get events from this month
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final thisMonthEvents = allEvents
          .where((e) => e.timestamp.isAfter(monthStart))
          .toList();

      final stats = {
        'total_revenue': totalRevenue,
        'active_customers': activeCustomers,
        'total_recovered': successfulEvents.length,
        'success_rate': successRate.toStringAsFixed(1),
        'transactions_this_month': thisMonthEvents.length,
        'timestamp': DateTime.now().toIso8601String(),
      };

      return Response.ok(
        json.encode(stats),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to get stats: $e'}),
      );
    }
  }

  /// GET /api/v1/admin/events - Get all failover events across all customers
  Future<Response> getAllEvents(Request request) async {
    try {
      final eventsWithCustomers = await database
          .getAllFailoverEventsWithCustomerId();

      final eventsData = eventsWithCustomers.take(50).map((eventData) {
        return {
          'id': eventData['id'],
          'customer_id': eventData['customer_id'],
          'timestamp': eventData['timestamp'],
          'primary_gateway': eventData['primary_gateway'],
          'secondary_gateway': eventData['secondary_gateway'],
          'amount': eventData['amount'],
          'currency': eventData['currency'],
          'success': eventData['success'] == 1,
          'error_type': eventData['error_type'],
        };
      }).toList();

      return Response.ok(
        json.encode({'events': eventsData}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to get events: $e'}),
      );
    }
  }
}
