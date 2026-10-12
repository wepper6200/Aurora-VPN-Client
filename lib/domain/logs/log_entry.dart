enum LogLevel {
  trace,
  debug,
  info,
  warn,
  error;

  static LogLevel parse(String s) => switch (s.toLowerCase()) {
    'trace' => trace,
    'debug' => debug,
    'warn' || 'warning' => warn,
    'error' || 'fatal' || 'panic' => error,
    _ => info,
  };
}

class LogEntry {
  const LogEntry({required this.time, required this.level, required this.message});

  final DateTime time;
  final LogLevel level;

  /// Already masked: UUIDs, passwords and tokens never reach the UI.
  final String message;
}
