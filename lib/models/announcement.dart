class Announcement {
  final String id;
  final String title;
  final String content;
  final String createdBy;
  final String? targetRole;
  final String? courseId;
  final bool isPublished;
  final DateTime? scheduledFor;
  final DateTime createdAt;
  final DateTime updatedAt;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.createdBy,
    this.targetRole,
    this.courseId,
    required this.isPublished,
    this.scheduledFor,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdBy: json['created_by'] ?? '',
      targetRole: json['target_role'],
      courseId: json['course_id'],
      isPublished: json['is_published'] ?? true,
      scheduledFor: json['scheduled_for'] != null 
          ? DateTime.parse(json['scheduled_for']) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_by': createdBy,
      'target_role': targetRole,
      'course_id': courseId,
      'is_published': isPublished,
      'scheduled_for': scheduledFor?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    String? createdBy,
    String? targetRole,
    String? courseId,
    bool? isPublished,
    DateTime? scheduledFor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdBy: createdBy ?? this.createdBy,
      targetRole: targetRole ?? this.targetRole,
      courseId: courseId ?? this.courseId,
      isPublished: isPublished ?? this.isPublished,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Announcement(id: $id, title: $title, content: $content, createdBy: $createdBy, targetRole: $targetRole, courseId: $courseId, isPublished: $isPublished, scheduledFor: $scheduledFor, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Announcement &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.createdBy == createdBy &&
        other.targetRole == targetRole &&
        other.courseId == courseId &&
        other.isPublished == isPublished &&
        other.scheduledFor == scheduledFor &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        content.hashCode ^
        createdBy.hashCode ^
        targetRole.hashCode ^
        courseId.hashCode ^
        isPublished.hashCode ^
        scheduledFor.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
