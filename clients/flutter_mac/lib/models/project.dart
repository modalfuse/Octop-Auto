class Project {
  const Project({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;

  factory Project.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'];
    return Project(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      createdAt: created is String
          ? DateTime.tryParse(created) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
