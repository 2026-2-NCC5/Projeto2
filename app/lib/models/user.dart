class UserModel {
  final int id;
  final String raOrEmail;
  final String? email;
  final String fullName;
  final String profileType; // ALUNO, ATENDENTE_ASA, ADMINISTRADOR, etc.
  final String? ra;
  final String? course;
  final int? semester;
  final String? campus;
  final String fontSizeFactor;
  final bool highContrast;
  final bool notificationsEnabled;
  final bool isActive;

  UserModel({
    required this.id,
    required this.raOrEmail,
    this.email,
    required this.fullName,
    required this.profileType,
    this.ra,
    this.course,
    this.semester,
    this.campus,
    this.fontSizeFactor = "normal",
    this.highContrast = false,
    this.notificationsEnabled = true,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      raOrEmail: json['ra_or_email'] ?? '',
      email: json['email'],
      fullName: json['full_name'] ?? 'Estudante',
      profileType: json['profile_type'] ?? 'ALUNO',
      ra: json['ra'] ?? json['ra_or_email'],
      course: json['course'] ?? 'Ciência da Computação',
      semester: json['semester'] ?? 5,
      campus: json['campus'] ?? 'Campus Liberdade',
      fontSizeFactor: json['font_size_factor'] ?? 'normal',
      highContrast: json['high_contrast'] ?? false,
      notificationsEnabled: json['notifications_enabled'] ?? true,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ra_or_email': raOrEmail,
      'email': email,
      'full_name': fullName,
      'profile_type': profileType,
      'ra': ra,
      'course': course,
      'semester': semester,
      'campus': campus,
      'font_size_factor': fontSizeFactor,
      'high_contrast': highContrast,
      'notifications_enabled': notificationsEnabled,
      'is_active': isActive,
    };
  }
}
