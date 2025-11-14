class ApiKey {
  final String id;
  final String customerId;
  final String keyValue;
  final String? name;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  ApiKey({
    required this.id,
    required this.customerId,
    required this.keyValue,
    this.name,
    this.isActive = true,
    required this.createdAt,
    this.lastUsedAt,
  });

  factory ApiKey.fromMap(Map<String, dynamic> map) {
    return ApiKey(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      keyValue: map['key_value'] as String,
      name: map['name'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastUsedAt: map['last_used_at'] != null
          ? DateTime.parse(map['last_used_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'keyValue': keyValue,
      'name': name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }

  // Safe version with masked key
  Map<String, dynamic> toSafeJson() {
    final json = toJson();
    json['keyValue'] = '${keyValue.substring(0, 12)}${'*' * 20}';
    return json;
  }
}
