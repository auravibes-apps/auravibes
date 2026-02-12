class ToolResponseItem {
  const ToolResponseItem({
    required this.id,
    required this.content,
  });

  final String id;
  final String content;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
    };
  }
}
