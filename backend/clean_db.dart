import 'package:sqlite3/sqlite3.dart';

void main() {
  final dbPath = './data/api_sentinel.db';

  print('🗑️  Cleaning database at $dbPath...');

  final db = sqlite3.open(dbPath);

  // Delete all data
  db.execute('DELETE FROM failover_events');
  db.execute('DELETE FROM api_keys');
  db.execute('DELETE FROM customers');

  print('✅ All demo data removed!');
  print('Database is now empty and ready for real customers.');

  db.dispose();
}
