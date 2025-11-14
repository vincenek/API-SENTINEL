import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../services/database_service.dart';

class AuthMiddleware {
  final DatabaseService database;
  final String jwtSecret;
  final publicPaths = [
    '/health',
    '/api/v1/docs',
    '/api/v1/customers/register',
    '/api/v1/customers/login',
    '/api/v1/admin/customers',
    '/api/v1/admin/stats',
    '/api/v1/admin/events',
  ];

  AuthMiddleware(this.database, this.jwtSecret);

  Middleware get handler {
    return (Handler innerHandler) {
      return (Request request) async {
        // Skip auth for public paths
        if (publicPaths.any(
          (path) => request.url.path == path.replaceFirst('/', ''),
        )) {
          return innerHandler(request);
        }

        // Check for API key (for SDK requests)
        final authHeader = request.headers['authorization'];
        if (authHeader != null && authHeader.startsWith('Bearer sk_')) {
          final apiKey = authHeader.replaceFirst('Bearer ', '');
          final customerId = await database.getCustomerIdByApiKey(apiKey);

          if (customerId != null) {
            final newRequest = request.change(
              context: {'customerId': customerId},
            );
            return innerHandler(newRequest);
          }
        }

        // Check for JWT token (for dashboard requests)
        if (authHeader != null && !authHeader.startsWith('Bearer sk_')) {
          final token = authHeader.replaceFirst('Bearer ', '');

          try {
            final jwt = JWT.verify(token, SecretKey(jwtSecret));
            final customerId = jwt.payload['sub'] as String?;

            if (customerId != null) {
              final newRequest = request.change(
                context: {'customerId': customerId},
              );
              return innerHandler(newRequest);
            }
          } catch (e) {
            return Response(401, body: 'Invalid token');
          }
        }

        return Response(401, body: 'Unauthorized');
      };
    };
  }
}
