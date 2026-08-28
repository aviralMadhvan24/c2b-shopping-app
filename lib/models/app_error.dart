enum AppErrorType {
  noConnection,
  timeout,
  apiValidation,
  notFound,
  unknown,
}

class AppError {
  final AppErrorType type;
  final String? apiMessage;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppError({
    required this.type,
    this.apiMessage,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'AppError(type: $type, apiMessage: $apiMessage)';
  }
}
