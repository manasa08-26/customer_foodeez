/// Safe JSON value coercion — handles API returning numbers as strings.
class JsonParsers {
  JsonParsers._();

  static double? doubleValue(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static double doubleOrZero(dynamic value) => doubleValue(value) ?? 0;

  static int? intValue(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static int intOr(dynamic value, [int fallback = 0]) =>
      intValue(value) ?? fallback;

  static bool? boolValue(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return null;
  }

  static bool boolOr(dynamic value, [bool fallback = false]) =>
      boolValue(value) ?? fallback;

  static String stringValue(dynamic value, [String fallback = '']) =>
      value?.toString() ?? fallback;

  static Map<String, dynamic> mapValue(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  static List<dynamic> listValue(dynamic value) {
    if (value is List) return value;
    return [];
  }
}
