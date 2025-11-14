import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import '../models/customer.dart';
import '../models/failover_event.dart';
import '../models/api_key.dart';

class DatabaseService {
  final String dbPath;
  late Database _db;

  DatabaseService(this.dbPath);

  Future<void> initialize() async {
    // Ensure data directory exists
    final file = File(dbPath);
    await file.parent.create(recursive: true);

    _db = sqlite3.open(dbPath);
    await _createTables();
    print('✅ Database initialized: $dbPath');
  }

  Future<void> _createTables() async {
    // Customers table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id TEXT PRIMARY KEY,
        company_name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        primary_gateway TEXT NOT NULL,
        secondary_gateway TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // API Keys table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS api_keys (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        key_value TEXT UNIQUE NOT NULL,
        name TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        last_used_at TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    // Failover Events table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS failover_events (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        primary_gateway TEXT NOT NULL,
        secondary_gateway TEXT NOT NULL,
        error_type TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT DEFAULT 'USD',
        success INTEGER NOT NULL,
        recovery_time_ms INTEGER,
        metadata TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    // Create indexes
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_events_customer ON failover_events(customer_id)',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_events_timestamp ON failover_events(timestamp)',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_api_keys_customer ON api_keys(customer_id)',
    );
  }

  // Customer operations
  Future<Customer?> createCustomer(Customer customer) async {
    try {
      final stmt = _db.prepare('''
        INSERT INTO customers (id, company_name, email, password_hash, primary_gateway, secondary_gateway, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''');

      stmt.execute([
        customer.id,
        customer.companyName,
        customer.email,
        customer.passwordHash,
        customer.primaryGateway,
        customer.secondaryGateway,
        customer.createdAt.toIso8601String(),
        customer.updatedAt.toIso8601String(),
      ]);
      stmt.dispose();

      return customer;
    } catch (e) {
      print('Error creating customer: $e');
      return null;
    }
  }

  Future<Customer?> getCustomerByEmail(String email) async {
    final stmt = _db.prepare('SELECT * FROM customers WHERE email = ?');
    final result = stmt.select([email]);
    stmt.dispose();

    if (result.isEmpty) return null;

    final row = result.first;
    return Customer.fromMap(row);
  }

  Future<Customer?> getCustomerById(String id) async {
    final stmt = _db.prepare('SELECT * FROM customers WHERE id = ?');
    final result = stmt.select([id]);
    stmt.dispose();

    if (result.isEmpty) return null;

    final row = result.first;
    return Customer.fromMap(row);
  }

  Future<bool> updateCustomer(Customer customer) async {
    try {
      final stmt = _db.prepare('''
        UPDATE customers
        SET company_name = ?, primary_gateway = ?, secondary_gateway = ?, updated_at = ?
        WHERE id = ?
      ''');

      stmt.execute([
        customer.companyName,
        customer.primaryGateway,
        customer.secondaryGateway,
        DateTime.now().toIso8601String(),
        customer.id,
      ]);
      stmt.dispose();

      return true;
    } catch (e) {
      print('Error updating customer: $e');
      return false;
    }
  }

  Future<List<Customer>> getAllCustomers() async {
    final result = _db.select(
      'SELECT * FROM customers ORDER BY created_at DESC',
    );
    return result.map((row) => Customer.fromMap(row)).toList();
  } // API Key operations

  Future<ApiKey?> createApiKey(ApiKey apiKey) async {
    try {
      final stmt = _db.prepare('''
        INSERT INTO api_keys (id, customer_id, key_value, name, is_active, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
      ''');

      stmt.execute([
        apiKey.id,
        apiKey.customerId,
        apiKey.keyValue,
        apiKey.name,
        apiKey.isActive ? 1 : 0,
        apiKey.createdAt.toIso8601String(),
      ]);
      stmt.dispose();

      return apiKey;
    } catch (e) {
      print('Error creating API key: $e');
      return null;
    }
  }

  Future<String?> getCustomerIdByApiKey(String apiKey) async {
    final stmt = _db.prepare(
      'SELECT customer_id FROM api_keys WHERE key_value = ? AND is_active = 1',
    );
    final result = stmt.select([apiKey]);
    stmt.dispose();

    if (result.isEmpty) return null;

    // Update last used timestamp
    final updateStmt = _db.prepare(
      'UPDATE api_keys SET last_used_at = ? WHERE key_value = ?',
    );
    updateStmt.execute([DateTime.now().toIso8601String(), apiKey]);
    updateStmt.dispose();

    return result.first['customer_id'] as String;
  }

  Future<List<ApiKey>> getApiKeysByCustomerId(String customerId) async {
    final stmt = _db.prepare(
      'SELECT * FROM api_keys WHERE customer_id = ? ORDER BY created_at DESC',
    );
    final result = stmt.select([customerId]);
    stmt.dispose();

    return result.map((row) => ApiKey.fromMap(row)).toList();
  }

  Future<bool> revokeApiKey(String keyId, String customerId) async {
    try {
      final stmt = _db.prepare(
        'UPDATE api_keys SET is_active = 0 WHERE id = ? AND customer_id = ?',
      );
      stmt.execute([keyId, customerId]);
      stmt.dispose();
      return true;
    } catch (e) {
      print('Error revoking API key: $e');
      return false;
    }
  }

  // Failover Event operations
  Future<bool> createFailoverEvent(
    FailoverEventModel event,
    String customerId,
  ) async {
    try {
      final stmt = _db.prepare('''
        INSERT INTO failover_events 
        (id, customer_id, timestamp, primary_gateway, secondary_gateway, error_type, amount, currency, success, recovery_time_ms, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''');

      stmt.execute([
        event.id,
        customerId,
        event.timestamp.toIso8601String(),
        event.primaryGateway,
        event.secondaryGateway,
        event.errorType,
        event.amount,
        event.currency,
        event.success ? 1 : 0,
        event.recoveryTimeMs,
        event.metadata,
      ]);
      stmt.dispose();

      return true;
    } catch (e) {
      print('Error creating failover event: $e');
      return false;
    }
  }

  Future<List<FailoverEventModel>> getFailoverEvents(
    String customerId, {
    int limit = 100,
    int offset = 0,
  }) async {
    final stmt = _db.prepare('''
      SELECT * FROM failover_events
      WHERE customer_id = ?
      ORDER BY timestamp DESC
      LIMIT ? OFFSET ?
    ''');

    final result = stmt.select([customerId, limit, offset]);
    stmt.dispose();

    return result.map((row) => FailoverEventModel.fromMap(row)).toList();
  }

  Future<List<FailoverEventModel>> getAllFailoverEvents({
    int limit = 100,
  }) async {
    final result = _db.select('''
      SELECT * FROM failover_events
      ORDER BY timestamp DESC
      LIMIT $limit
    ''');

    return result.map((row) => FailoverEventModel.fromMap(row)).toList();
  }

  Future<List<Map<String, dynamic>>> getAllFailoverEventsWithCustomerId({
    int limit = 100,
  }) async {
    final result = _db.select('''
      SELECT * FROM failover_events
      ORDER BY timestamp DESC
      LIMIT $limit
    ''');

    return result.toList();
  } // Metrics operations

  Future<Map<String, dynamic>> getMetricsOverview(
    String customerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start =
        (startDate ?? DateTime.now().subtract(const Duration(days: 30)))
            .toIso8601String();
    final end = (endDate ?? DateTime.now()).toIso8601String();

    final stmt = _db.prepare('''
      SELECT 
        COUNT(*) as total_events,
        SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) as successful_recoveries,
        SUM(CASE WHEN success = 1 THEN amount ELSE 0 END) as recovered_revenue,
        AVG(CASE WHEN success = 1 THEN recovery_time_ms ELSE NULL END) as avg_recovery_time
      FROM failover_events
      WHERE customer_id = ? AND timestamp BETWEEN ? AND ?
    ''');

    final result = stmt.select([customerId, start, end]);
    stmt.dispose();

    if (result.isEmpty) {
      return {
        'totalEvents': 0,
        'successfulRecoveries': 0,
        'recoveredRevenue': 0.0,
        'avgRecoveryTime': 0.0,
      };
    }

    final row = result.first;
    return {
      'totalEvents': row['total_events'],
      'successfulRecoveries': row['successful_recoveries'],
      'recoveredRevenue': row['recovered_revenue'] ?? 0.0,
      'avgRecoveryTime': row['avg_recovery_time'] ?? 0.0,
      'failoverRate': row['total_events'] > 0
          ? (row['successful_recoveries'] / row['total_events'] * 100)
                .toStringAsFixed(2)
          : '0.00',
    };
  }

  Future<Map<String, dynamic>> getGatewayPerformance(String customerId) async {
    final stmt = _db.prepare('''
      SELECT 
        primary_gateway,
        secondary_gateway,
        COUNT(*) as failover_count,
        SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) as successful_count,
        AVG(CASE WHEN success = 1 THEN recovery_time_ms ELSE NULL END) as avg_recovery_time
      FROM failover_events
      WHERE customer_id = ?
      GROUP BY primary_gateway, secondary_gateway
    ''');

    final result = stmt.select([customerId]);
    stmt.dispose();

    return {
      'gateways': result
          .map(
            (row) => {
              'primary': row['primary_gateway'],
              'secondary': row['secondary_gateway'],
              'failoverCount': row['failover_count'],
              'successfulCount': row['successful_count'],
              'avgRecoveryTime': row['avg_recovery_time'] ?? 0.0,
              'successRate': row['failover_count'] > 0
                  ? (row['successful_count'] / row['failover_count'] * 100)
                        .toStringAsFixed(2)
                  : '0.00',
            },
          )
          .toList(),
    };
  }

  Future<void> close() async {
    _db.dispose();
    print('✅ Database closed');
  }
}
