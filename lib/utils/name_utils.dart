String extractFullName(Map<String, dynamic> user) {
  final fullName = user['FULL_NAME'] ?? user['fullName'] ?? user['NAME'] ?? user['name'];
  if (fullName == null) return '';
  return fullName.toString().trim();
}

String extractFirstName(Map<String, dynamic> user) {
  final firstName = user['FIRST_NAME']?.toString().trim();
  if (firstName != null && firstName.isNotEmpty) return firstName;

  final fullName = extractFullName(user);
  if (fullName.isEmpty) {
    final username = user['USERNAME']?.toString().trim() ?? '';
    if (username.isNotEmpty) {
      return username.split(RegExp(r'\s+')).first;
    }
    return '';
  }

  final parts = fullName.split(RegExp(r'\s+'));
  return parts.isNotEmpty ? parts.first : fullName;
}

int extractIsDean(Map<String, dynamic> user) {
  final isDean = user['IS_DEAN'] ?? user['isDean'];
  if (isDean == null) return 0;
  if (isDean is bool) return isDean ? 1 : 0;
  return int.tryParse(isDean.toString()) ?? 0;
}
