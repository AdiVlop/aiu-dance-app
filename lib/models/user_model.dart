class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  
  // Computed property for full name
  String get name => '$firstName $lastName';
  final String? profileImageUrl;
  final String userType; // 'student', 'instructor', 'admin'
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final List<String> enrolledCourses;
  final double walletBalance;
  final Map<String, dynamic> preferences;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.profileImageUrl,
    required this.userType,
    required this.createdAt,
    this.lastLoginAt,
    required this.isActive,
    required this.enrolledCourses,
    required this.walletBalance,
    required this.preferences,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNumber: json['phoneNumber'],
      profileImageUrl: json['profileImageUrl'],
      userType: json['userType'] ?? 'student',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt']) 
          : null,
      isActive: json['isActive'] ?? true,
      enrolledCourses: List<String>.from(json['enrolledCourses'] ?? []),
      walletBalance: (json['walletBalance'] ?? 0.0).toDouble(),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'userType': userType,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isActive': isActive,
      'enrolledCourses': enrolledCourses,
      'walletBalance': walletBalance,
      'preferences': preferences,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImageUrl,
    String? userType,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    List<String>? enrolledCourses,
    double? walletBalance,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
      walletBalance: walletBalance ?? this.walletBalance,
      preferences: preferences ?? this.preferences,
    );
  }

  String get fullName => '$firstName $lastName';
  bool get isInstructor => userType == 'instructor';
  bool get isAdmin => userType == 'admin';
  bool get isStudent => userType == 'student';
} 