class FailoverEventModel {
  final String id;
  final DateTime timestamp;
  final String primaryGateway;
  final String secondaryGateway;
  final String errorType;
  final double amount;
  final String currency;
  final bool success;
  final int? recoveryTimeMs;
  final String? metadata;

  FailoverEventModel({
    required this.id,
    required this.timestamp,
    required this.primaryGateway,
    required this.secondaryGateway,
    required this.errorType,
    required this.amount,
    this.currency = 'USD',
    required this.success,
    this.recoveryTimeMs,
    this.metadata,
  });

  factory FailoverEventModel.fromJson(Map<String, dynamic> json) {
    return FailoverEventModel(
      id: json['id'] as String? ?? '',
      timestamp: json['timestamp'] is String
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      primaryGateway: json['primaryGateway'] as String? ?? json['primary_gateway'] as String? ?? '',
      secondaryGateway: json['secondaryGateway'] as String? ?? json['secondary_gateway'] as String? ?? '',
      errorType: json['errorType'] as String? ?? json['error_type'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      success: json['success'] as bool? ?? false,
      recoveryTimeMs: json['recoveryTimeMs'] as int? ?? json['recovery_time_ms'] as int?,
      metadata: json['metadata'] as String?,
    );
  }

  factory FailoverEventModel.fromMap(Map<String, dynamic> map) {
    return FailoverEventModel(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      primaryGateway: map['primary_gateway'] as String,
      secondaryGateway: map['secondary_gateway'] as String,
      errorType: map['error_type'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'USD',
      success: (map['success'] as int) == 1,
      recoveryTimeMs: map['recovery_time_ms'] as int?,
      metadata: map['metadata'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'primaryGateway': primaryGateway,
      'secondaryGateway': secondaryGateway,
      'errorType': errorType,
      'amount': amount,
      'currency': currency,
      'success': success,
      'recoveryTimeMs': recoveryTimeMs,
      'metadata': metadata,
    };
  }
}
