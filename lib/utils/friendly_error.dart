typedef TranslateMessage = String Function(String key);

/// Builds an end-user-friendly error message from a thrown error.
/// - Hides raw exception details
/// - Detects common network issues
/// - Falls back to a supplied default message
String friendlyErrorMessage({
  required String defaultMessage,
  dynamic error,
  String? connectionMessage,
  List<String> knownMessages = const [],
}) {
  if (error == null) return defaultMessage;

  final raw = error.toString();
  final lower = raw.toLowerCase();

  const networkHints = [
    'connection refused',
    'failed host lookup',
    'socketexception',
    'network is unreachable',
    'timed out',
    'timeout',
    'connection timed out',
  ];

  final hasNetworkIssue = networkHints.any(lower.contains);
  if (hasNetworkIssue && connectionMessage != null && connectionMessage.isNotEmpty) {
    return connectionMessage;
  }

  for (final message in knownMessages) {
    if (message.isNotEmpty && raw.contains(message)) {
      return message;
    }
  }

  return defaultMessage;
}
