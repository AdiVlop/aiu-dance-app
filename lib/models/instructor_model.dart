class InstructorModel {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String bio;
  final List<String> specializations; // ['salsa', 'bachata', 'kizomba']
  final List<String> certifications;
  final int yearsOfExperience;
  final double rating;
  final int totalReviews;
  final bool isActive;
  final DateTime createdAt;
  final Map<String, dynamic> socialMedia;
  final List<String> courseIds;
  final String? availability;

  InstructorModel({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    required this.bio,
    required this.specializations,
    required this.certifications,
    required this.yearsOfExperience,
    required this.rating,
    required this.totalReviews,
    required this.isActive,
    required this.createdAt,
    required this.socialMedia,
    required this.courseIds,
    this.availability,
  });

  factory InstructorModel.fromJson(Map<String, dynamic> json) {
    return InstructorModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      profileImageUrl: json['profileImageUrl'],
      bio: json['bio'] ?? '',
      specializations: List<String>.from(json['specializations'] ?? []),
      certifications: List<String>.from(json['certifications'] ?? []),
      yearsOfExperience: json['yearsOfExperience'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      socialMedia: Map<String, dynamic>.from(json['socialMedia'] ?? {}),
      courseIds: List<String>.from(json['courseIds'] ?? []),
      availability: json['availability'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'specializations': specializations,
      'certifications': certifications,
      'yearsOfExperience': yearsOfExperience,
      'rating': rating,
      'totalReviews': totalReviews,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'socialMedia': socialMedia,
      'courseIds': courseIds,
      'availability': availability,
    };
  }

  InstructorModel copyWith({
    String? id,
    String? userId,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    String? bio,
    List<String>? specializations,
    List<String>? certifications,
    int? yearsOfExperience,
    double? rating,
    int? totalReviews,
    bool? isActive,
    DateTime? createdAt,
    Map<String, dynamic>? socialMedia,
    List<String>? courseIds,
    String? availability,
  }) {
    return InstructorModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      specializations: specializations ?? this.specializations,
      certifications: certifications ?? this.certifications,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      socialMedia: socialMedia ?? this.socialMedia,
      courseIds: courseIds ?? this.courseIds,
      availability: availability ?? this.availability,
    );
  }

  String get fullName => '$firstName $lastName';
  String get displayName => '$firstName $lastName';
  String get ratingDisplay => rating.toStringAsFixed(1);
  String get experienceDisplay => '$yearsOfExperience ani de experiență';
  String get specializationsDisplay => specializations.join(', ');
  bool get hasProfileImage => profileImageUrl != null && profileImageUrl!.isNotEmpty;
  String get contactInfo => phoneNumber ?? email;
} 