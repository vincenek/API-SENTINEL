import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';
import '../services/database_service.dart';
import '../models/failover_event.dart';

class AnalyticsHandler {
  final DatabaseService database;
  final _uuid = const Uuid();

  AnalyticsHandler(this.database);

  Future<Response> receiveEvent(Request request) async {
    final customerId = request.context['customerId'] as String?;
    if (customerId == null) {
      return Response(401, body: json.encode({'error': 'Unauthorized'}));
    }

    try {
      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;

      final event = FailoverEventModel.fromJson({...data, 'id': _uuid.v4()});

      await database.createFailoverEvent(event, customerId);

      return Response.ok(
        json.encode({
          'message': 'Event recorded successfully',
          'eventId': event.id,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Analytics error: $e');
      return Response(
        500,
        body: json.encode({'error': 'Failed to record event'}),
      );
    }
  }

  Future<Response> getEvents(Request request) async {
    final customerId = request.context['customerId'] as String?;
    if (customerId == null) {
      return Response(401, body: json.encode({'error': 'Unauthorized'}));
    }

    final limit =
        int.tryParse(request.url.queryParameters['limit'] ?? '100') ?? 100;
    final offset =
        int.tryParse(request.url.queryParameters['offset'] ?? '0') ?? 0;

    final events = await database.getFailoverEvents(
      customerId,
      limit: limit,
      offset: offset,
    );

    return Response.ok(
      json.encode({'events': events.map((e) => e.toJson()).toList()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
