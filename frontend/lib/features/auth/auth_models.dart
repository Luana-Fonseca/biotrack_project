class UserModel {
  final int id;
  final String email;
  final String name;
  final String? profession;
  final String? education;
  final String? city;
  final DateTime? birthDate;
  final String role;
  final bool notificationsEnabled;
  final String language;
  final int xp;
  final int streakDays;
  final bool hasPhoto;
  final String? profilePhotoBase64;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.profession,
    this.education,
    this.city,
    this.birthDate,
    required this.role,
    required this.notificationsEnabled,
    required this.language,
    required this.xp,
    required this.streakDays,
    required this.hasPhoto,
    this.profilePhotoBase64,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        email: json['email'] as String,
        name: json['name'] as String,
        profession: json['profession'] as String?,
        education: json['education'] as String?,
        city: json['city'] as String?,
        birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate'] as String) : null,
        role: json['role'] as String? ?? 'OPERACIONAL',
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        language: json['language'] as String? ?? 'pt-BR',
        xp: json['xp'] as int? ?? 0,
        streakDays: json['streakDays'] as int? ?? 0,
        hasPhoto: json['hasPhoto'] as bool? ?? false,
        profilePhotoBase64: json['profilePhotoBase64'] as String?,
      );
}

class AuthResult {
  final String accessToken;
  final UserModel user;

  AuthResult({required this.accessToken, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        accessToken: json['accessToken'] as String,
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      );
}
