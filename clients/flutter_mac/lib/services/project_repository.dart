import 'dart:convert';

import '../models/project.dart';
import 'credential_store.dart';

class ProjectSpace {
  const ProjectSpace({
    required this.projects,
    required this.collapsed,
    required this.activeId,
  });

  final List<Project> projects;
  final bool collapsed;
  final String? activeId;
}

class ProjectRepository {
  ProjectRepository(this._store);

  static const storageKey = 'octop.projects';

  final CredentialStore _store;

  Future<ProjectSpace> load() async {
    final raw = await _store.read(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const ProjectSpace(projects: [], collapsed: false, activeId: null);
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const ProjectSpace(
          projects: [],
          collapsed: false,
          activeId: null,
        );
      }
      final list = decoded['projects'];
      final projects = <Project>[
        if (list is List)
          for (final item in list)
            if (item is Map) Project.fromJson(Map<String, dynamic>.from(item)),
      ];
      final active = decoded['active_id'];
      return ProjectSpace(
        projects: projects,
        collapsed: decoded['collapsed'] == true,
        activeId: active is String && active.isNotEmpty ? active : null,
      );
    } on FormatException {
      return const ProjectSpace(projects: [], collapsed: false, activeId: null);
    }
  }

  Future<ProjectSpace> create(String name) async {
    final current = await load();
    final project = Project(
      id: 'p_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      name: name.trim(),
      createdAt: DateTime.now(),
    );
    final next = ProjectSpace(
      projects: [project, ...current.projects],
      collapsed: current.collapsed,
      activeId: project.id,
    );
    await _save(next);
    return next;
  }

  Future<ProjectSpace> select(String id) async {
    final current = await load();
    final next = ProjectSpace(
      projects: current.projects,
      collapsed: current.collapsed,
      activeId: id,
    );
    await _save(next);
    return next;
  }

  Future<ProjectSpace> delete(String id) async {
    final current = await load();
    final next = ProjectSpace(
      projects: [
        for (final project in current.projects)
          if (project.id != id) project,
      ],
      collapsed: current.collapsed,
      activeId: current.activeId == id ? null : current.activeId,
    );
    await _save(next);
    return next;
  }

  Future<ProjectSpace> setCollapsed(bool collapsed) async {
    final current = await load();
    final next = ProjectSpace(
      projects: current.projects,
      collapsed: collapsed,
      activeId: current.activeId,
    );
    await _save(next);
    return next;
  }

  Future<void> _save(ProjectSpace space) {
    return _store.write(
      storageKey,
      jsonEncode(<String, Object?>{
        'projects': [for (final project in space.projects) project.toJson()],
        'collapsed': space.collapsed,
        'active_id': space.activeId,
      }),
    );
  }
}
