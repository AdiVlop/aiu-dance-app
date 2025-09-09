class PaymentModel {
  final String id;
  final String userId;
  final String? courseId;
  final double amount;
  final String currency;
  final String status; // 'pending', 'completed', 'failed', 'refunded'
  final String paymentMethod; // 'stripe', 'wallet', 'card'
  final String? stripePaymentIntentId;
  final String? stripeCustomerId;
  final String description;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic> metadata;
  final String? failureReason;
  final double? feeAmount;
  final String? receiptUrl;

  PaymentModel({
    required this.id,
    required this.userId,
    this.courseId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    this.stripePaymentIntentId,
    this.stripeCustomerId,
    required this.description,
    required this.createdAt,
    this.completedAt,
    required this.metadata,
    this.failureReason,
    this.feeAmount,
    this.receiptUrl,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      courseId: json['courseId'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'RON',
      status: json['status'] ?? 'pending',
      paymentMethod: json['paymentMethod'] ?? 'stripe',
      stripePaymentIntentId: json['stripePaymentIntentId'],
      stripeCustomerId: json['stripeCustomerId'],
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      failureReason: json['failureReason'],
      feeAmount: json['feeAmount'] != null ? (json['feeAmount'] as num).toDouble() : null,
      receiptUrl: json['receiptUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'courseId': courseId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'paymentMethod': paymentMethod,
      'stripePaymentIntentId': stripePaymentIntentId,
      'stripeCustomerId': stripeCustomerId,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'metadata': metadata,
      'failureReason': failureReason,
      'feeAmount': feeAmount,
      'receiptUrl': receiptUrl,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? userId,
    String? courseId,
    double? amount,
    String? currency,
    String? status,
    String? paymentMethod,
    String? stripePaymentIntentId,
    String? stripeCustomerId,
    String? description,
    DateTime? createdAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
    String? failureReason,
    double? feeAmount,
    String? receiptUrl,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
      failureReason: failureReason ?? this.failureReason,
      feeAmount: feeAmount ?? this.feeAmount,
      receiptUrl: receiptUrl ?? this.receiptUrl,
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
  bool get isRefunded => status == 'refunded';
  bool get isWalletPayment => paymentMethod == 'wallet';
  bool get isStripePayment => paymentMethod == 'stripe';
  String get formattedAmount => '${amount.toStringAsFixed(2)} $currency';
  String get statusDisplay {
    switch (status) {
      case 'completed':
        return 'Completat';
      case 'pending':
        return 'În așteptare';
      case 'failed':
        return 'Eșuat';
      case 'refunded':
        return 'Rambursat';
      default:
        return 'Necunoscut';
    }
  }
} 