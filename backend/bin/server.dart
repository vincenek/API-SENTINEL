import 'dart:io';
import '../lib/src/server.dart';
import 'package:dotenv/dotenv.dart';

Future<void> main() async {
  // Load environment variables
  final env = DotEnv()..load();

  final port = int.parse(env.getOrElse('PORT', () => '8080'));
  final host = env.getOrElse('HOST', () => 'localhost');

  print('🚀 Starting API Sentinel Backend...');
  print('📍 Environment: ${env.getOrElse('ENVIRONMENT', () => 'development')}');

  // Create and start server
  final server = APISentinelServer(
    port: port,
    host: host,
    jwtSecret: env.getOrElse('JWT_SECRET', () => 'dev-secret-key'),
    dbPath: env.getOrElse('DATABASE_PATH', () => './data/api_sentinel.db'),
  );

  await server.start();

  print('✅ API Sentinel Backend running on http://$host:$port');
  print('📊 Health check: http://$host:$port/health');
  print('📚 API Docs: http://$host:$port/api/v1/docs');

  // Handle graceful shutdown
  ProcessSignal.sigint.watch().listen((signal) async {
    print('\n⏹️  Shutting down gracefully...');
    await server.stop();
    exit(0);
  });
}
