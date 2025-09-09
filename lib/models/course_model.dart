class CourseModel {
  final String id;
  final String title;
  final String description;
  final String instructorId;
  final String instructorName;
  final String category; // 'salsa', 'bachata', 'kizomba', etc.
  final String level; // 'beginner', 'intermediate', 'advanced'
  final double price; // Price for the course
  final int duration; // in minutes
  final int maxStudents;
  final int currentStudents;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> schedule; // ['Monday 18:00', 'Wednesday 18:00']
  final String location;
  final List<String> imageUrls;
  final bool isActive;
  final DateTime createdAt;
  final Map<String, dynamic> requirements;
  final List<String> enrolledStudents;
  final DateTime? nextSessionDate;
  final bool announcementPosted;
  final DateTime? announcementPostedAt;
  final bool urgentReminderSent;
  final DateTime? lastReminderSent;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.instructorId,
    required this.instructorName,
    required this.category,
    required this.level,
    required this.price,
    required this.duration,
    required this.maxStudents,
    required this.currentStudents,
    required this.startDate,
    required this.endDate,
    required this.schedule,
    required this.location,
    required this.imageUrls,
    required this.isActive,
    required this.createdAt,
    required this.requirements,
    required this.enrolledStudents,
    this.nextSessionDate,
    this.announcementPosted = false,
    this.announcementPostedAt,
    this.urgentReminderSent = false,
    this.lastReminderSent,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      instructorId: json['instructorId'] ?? '',
      instructorName: json['instructorName'] ?? '',
      category: json['category'] ?? '',
      level: json['level'] ?? 'beginner',
      price: (json['price'] ?? 0.0).toDouble(),
      duration: json['duration'] ?? 60,
      maxStudents: json['maxStudents'] ?? 20,
      currentStudents: json['currentStudents'] ?? 0,
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().add(Duration(days: 30)).toIso8601String()),
      schedule: List<String>.from(json['schedule'] ?? []),
      location: json['location'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      requirements: Map<String, dynamic>.from(json['requirements'] ?? {}),
      enrolledStudents: List<String>.from(json['enrolledStudents'] ?? []),
      nextSessionDate: json['nextSessionDate'] != null ? DateTime.parse(json['nextSessionDate']) : null,
      announcementPosted: json['announcementPosted'] ?? false,
      announcementPostedAt: json['announcementPostedAt'] != null ? DateTime.parse(json['announcementPostedAt']) : null,
      urgentReminderSent: json['urgentReminderSent'] ?? false,
      lastReminderSent: json['lastReminderSent'] != null ? DateTime.parse(json['lastReminderSent']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'category': category,
      'level': level,
      'price': price,
      'duration': duration,
      'maxStudents': maxStudents,
      'currentStudents': currentStudents,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'schedule': schedule,
      'location': location,
      'imageUrls': imageUrls,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'requirements': requirements,
      'enrolledStudents': enrolledStudents,
      'nextSessionDate': nextSessionDate?.toIso8601String(),
      'announcementPosted': announcementPosted,
      'announcementPostedAt': announcementPostedAt?.toIso8601String(),
      'urgentReminderSent': urgentReminderSent,
      'lastReminderSent': lastReminderSent?.toIso8601String(),
    };
  }

  CourseModel copyWith({
    String? id,
    String? title,
    String? description,
    String? instructorId,
    String? instructorName,
    String? category,
    String? level,
    double? price,
    int? duration,
    int? maxStudents,
    int? currentStudents,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? schedule,
    String? location,
    List<String>? imageUrls,
    bool? isActive,
    DateTime? createdAt,
    Map<String, dynamic>? requirements,
    List<String>? enrolledStudents,
    DateTime? nextSessionDate,
    bool? announcementPosted,
    DateTime? announcementPostedAt,
    bool? urgentReminderSent,
    DateTime? lastReminderSent,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      category: category ?? this.category,
      level: level ?? this.level,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      maxStudents: maxStudents ?? this.maxStudents,
      currentStudents: currentStudents ?? this.currentStudents,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      schedule: schedule ?? this.schedule,
      location: location ?? this.location,
      imageUrls: imageUrls ?? this.imageUrls,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      requirements: requirements ?? this.requirements,
      enrolledStudents: enrolledStudents ?? this.enrolledStudents,
      nextSessionDate: nextSessionDate ?? this.nextSessionDate,
      announcementPosted: announcementPosted ?? this.announcementPosted,
      announcementPostedAt: announcementPostedAt ?? this.announcementPostedAt,
      urgentReminderSent: urgentReminderSent ?? this.urgentReminderSent,
      lastReminderSent: lastReminderSent ?? this.lastReminderSent,
    );
  }

  bool get isFull => currentStudents >= maxStudents;
  bool get hasSpots => currentStudents < maxStudents;
  double get availabilityPercentage => (currentStudents / maxStudents) * 100;
  bool get isUpcoming => startDate.isAfter(DateTime.now());
  bool get isOngoing => startDate.isBefore(DateTime.now()) && endDate.isAfter(DateTime.now());
  bool get isCompleted => endDate.isBefore(DateTime.now());
} 