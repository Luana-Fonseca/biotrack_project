class TrilhaSummary {
  final int id;
  final String title;
  final String description;
  final String icon;
  final String? coverImage;
  final int totalModules;
  final int completedModules;
  final int progressPercent;

  TrilhaSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.coverImage,
    required this.totalModules,
    required this.completedModules,
    required this.progressPercent,
  });

  factory TrilhaSummary.fromJson(Map<String, dynamic> json) => TrilhaSummary(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        icon: json['icon'] as String? ?? 'book',
        coverImage: json['coverImage'] as String?,
        totalModules: json['totalModules'] as int? ?? 0,
        completedModules: json['completedModules'] as int? ?? 0,
        progressPercent: json['progressPercent'] as int? ?? 0,
      );
}

class ModuleSummary {
  final int id;
  final int trilhaId;
  final int orderIndex;
  final String title;
  final int durationMinutes;
  final String content;
  final bool completed;

  ModuleSummary({
    required this.id,
    required this.trilhaId,
    required this.orderIndex,
    required this.title,
    required this.durationMinutes,
    required this.content,
    required this.completed,
  });

  factory ModuleSummary.fromJson(Map<String, dynamic> json) => ModuleSummary(
        id: json['id'] as int,
        trilhaId: json['trilhaId'] as int,
        orderIndex: json['orderIndex'] as int? ?? 0,
        title: json['title'] as String? ?? '',
        durationMinutes: json['durationMinutes'] as int? ?? 0,
        content: json['content'] as String? ?? '',
        completed: json['completed'] as bool? ?? false,
      );
}
