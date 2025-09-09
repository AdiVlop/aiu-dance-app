class QRCode {
  final String id;
  final String courseId;
  final String code;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final String? createdBy;
  final int? scans;
  final DateTime? lastScanned;

  QRCode({
    required this.id,
    required this.courseId,
    required this.code,
    required this.isActive,
    this.expiresAt,
    required this.createdAt,
    this.createdBy,
    this.scans,
    this.lastScanned,
  });

  factory QRCode.fromJson(Map<String, dynamic> json) {
    return QRCode(
      id: json['id'] ?? '',
      courseId: json['course_id'] ?? '',
      code: json['code'] ?? '',
      isActive: json['is_active'] ?? true,
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at']) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      createdBy: json['created_by'],
      scans: json['scans'] ?? 0,
      lastScanned: json['last_scanned'] != null 
          ? DateTime.parse(json['last_scanned']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'code': code,
      'is_active': isActive,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'scans': scans,
      'last_scanned': lastScanned?.toIso8601String(),
    };
  }

  QRCode copyWith({
    String? id,
    String? courseId,
    String? code,
    bool? isActive,
    DateTime? expiresAt,
    DateTime? createdAt,
    String? createdBy,
    int? scans,
    DateTime? lastScanned,
  }) {
    return QRCode(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      code: code ?? this.code,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      scans: scans ?? this.scans,
      lastScanned: lastScanned ?? this.lastScanned,
    );
  }

  @override
  String toString() {
    return 'QRCode(id: $id, courseId: $courseId, code: $code, isActive: $isActive, expiresAt: $expiresAt, createdAt: $createdAt, createdBy: $createdBy, scans: $scans, lastScanned: $lastScanned)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QRCode &&
        other.id == id &&
        other.courseId == courseId &&
        other.code == code &&
        other.isActive == isActive &&
        other.expiresAt == expiresAt &&
        other.createdAt == createdAt &&
        other.createdBy == createdBy &&
        other.scans == scans &&
        other.lastScanned == lastScanned;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        courseId.hashCode ^
        code.hashCode ^
        isActive.hashCode ^
        expiresAt.hashCode ^
        createdAt.hashCode ^
        createdBy.hashCode ^
        scans.hashCode ^
        lastScanned.hashCode;
  }
}
