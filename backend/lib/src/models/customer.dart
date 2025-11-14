class Customer {
  final String id;
  final String companyName;
  final String email;
  final String passwordHash;
  final String primaryGateway;
  final String secondaryGateway;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.companyName,
    required this.email,
    required this.passwordHash,
    required this.primaryGateway,
    required this.secondaryGateway,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      companyName: map['company_name'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      primaryGateway: map['primary_gateway'] as String,
      secondaryGateway: map['secondary_gateway'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'email': email,
      'primaryGateway': primaryGateway,
      'secondaryGateway': secondaryGateway,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Safe version without password hash
  Map<String, dynamic> toSafeJson() {
    final json = toJson();
    json.remove('passwordHash');
    return json;
  }
}
