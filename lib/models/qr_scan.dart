class QRScan {
  final String id;
  final String qrCodeId;
  final String userId;
  final String courseId;
  final DateTime scannedAt;

  QRScan({
    required this.id,
    required this.qrCodeId,
    required this.userId,
    required this.courseId,
    required this.scannedAt,
  });

  factory QRScan.fromJson(Map<String, dynamic> json) {
    return QRScan(
      id: json['id'] ?? '',
      qrCodeId: json['qr_code_id'] ?? '',
      userId: json['user_id'] ?? '',
      courseId: json['course_id'] ?? '',
      scannedAt: json['scanned_at'] != null 
          ? DateTime.parse(json['scanned_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'qr_code_id': qrCodeId,
      'user_id': userId,
      'course_id': courseId,
      'scanned_at': scannedAt.toIso8601String(),
    };
  }

  QRScan copyWith({
    String? id,
    String? qrCodeId,
    String? userId,
    String? courseId,
    DateTime? scannedAt,
  }) {
    return QRScan(
      id: id ?? this.id,
      qrCodeId: qrCodeId ?? this.qrCodeId,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      scannedAt: scannedAt ?? this.scannedAt,
    );
  }

  @override
  String toString() {
    return 'QRScan(id: $id, qrCodeId: $qrCodeId, userId: $userId, courseId: $courseId, scannedAt: $scannedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QRScan &&
        other.id == id &&
        other.qrCodeId == qrCodeId &&
        other.userId == userId &&
        other.courseId == courseId &&
        other.scannedAt == scannedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        qrCodeId.hashCode ^
        userId.hashCode ^
        courseId.hashCode ^
        scannedAt.hashCode;
  }
}
