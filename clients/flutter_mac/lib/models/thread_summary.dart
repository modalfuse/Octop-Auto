class ThreadSummary {
  const ThreadSummary({
    required this.threadId,
    required this.title,
    this.isActive = false,
  });

  final String threadId;
  final String title;
  final bool isActive;

  factory ThreadSummary.fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    return ThreadSummary(
      threadId: json['thread_id'] as String? ?? '',
      title: title is String && title.trim().isNotEmpty ? title : '未命名对话',
      isActive: json['is_active'] == true,
    );
  }
}
