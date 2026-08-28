/// Holds the outcome of an address validation check.
class ValidationResult {
  final bool isValid;
  final Map<String, String> fieldErrors;

  const ValidationResult({
    required this.isValid,
    this.fieldErrors = const {},
  });

  factory ValidationResult.valid() {
    return const ValidationResult(isValid: true);
  }

  factory ValidationResult.invalid(Map<String, String> fieldErrors) {
    return ValidationResult(isValid: false, fieldErrors: fieldErrors);
  }
}
