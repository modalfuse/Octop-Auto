class Agent {
  const Agent({
    required this.agentId,
    required this.name,
    required this.state,
    this.description,
  });

  final String agentId;
  final String name;
  final String state;
  final String? description;

  bool get isRunning => state == 'running';

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      agentId: json['agent_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      state: json['state'] as String? ?? 'unknown',
      description: json['description'] as String?,
    );
  }
}

/// Prefer `main` / 小通, then the first listed agent.
Agent? pickDefaultAgent(List<Agent> agents) {
  for (final agent in agents) {
    if (agent.agentId == 'main') return agent;
  }
  for (final agent in agents) {
    if (agent.name == 'main' || agent.name == '小通') return agent;
  }
  if (agents.isEmpty) return null;
  return agents.first;
}
