import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../services/database_service.dart';

class MetricsHandler {
  final DatabaseService database;

  MetricsHandler(this.database);

  Future<Response> getOverview(Request request) async {
    final customerId = request.context['customerId'] as String?;
    if (customerId == null) {
      return Response(401, body: json.encode({'error': 'Unauthorized'}));
    }

    final metrics = await database.getMetricsOverview(customerId);

    return Response.ok(
      json.encode(metrics),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> getRecoveredRevenue(Request request) async {
    final customerId = request.context['customerId'] as String?;
    if (customerId == null) {
      return Response(401, body: json.encode({'error': 'Unauthorized'}));
    }

    final metrics = await database.getMetricsOverview(customerId);

    return Response.ok(
      json.encode({'recoveredRevenue': metrics['recoveredRevenue']}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> getFailoverRate(Request request) async {
    final customerId = request.context['customerId'] as String?;
    if (customerId == null) {
      return Response(401, body: json.encode({'error': 'Unauthorized'}));
    }

    final metrics = await database.getMetricsOverview(customerId);

    return Response.ok(
      json.encode({'failoverRate': metrics['failoverRate']}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> getGatewayPerformance(Request request) async {
    final customerId = request.context['customerId'] as String?;
    if (customerId == null) {
      return Response(401, body: json.encode({'error': 'Unauthorized'}));
    }

    final performance = await database.getGatewayPerformance(customerId);

    return Response.ok(
      json.encode(performance),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
