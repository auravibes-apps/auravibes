String formatRelativeTime(DateTime date, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final difference = current.difference(date);

  if (difference.inMinutes < 1) {
    return 'Just now';
  }

  if (difference.inHours < 1) {
    return '${difference.inMinutes}m ago';
  }

  if (difference.inDays < 1) {
    return '${difference.inHours}h ago';
  }

  if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  }

  return '${date.day}/${date.month}/${date.year}';
}
