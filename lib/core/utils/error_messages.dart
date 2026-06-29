import '../constants/env.dart';
import '../network/api_exception.dart';

/// Maps technical errors to user-friendly messages for UI.
class ErrorMessages {
  ErrorMessages._();

  static String userFriendly(Object error) {
    if (error is ApiException) return error.message;

    final message = error.toString();

    if (message.contains('is not a subtype of type') ||
        message.contains('type cast')) {
      return 'We received unexpected data from the server. Please try again.';
    }
    if (message.contains('SocketException') ||
        message.contains('Connection refused') ||
        message.contains('Failed host lookup') ||
        message.contains('Cannot connect to') ||
        message.contains('Cannot reach Foodeez')) {
      if (Env.isProductionHost) {
        return 'Cannot reach Foodeez servers. '
            'Check your internet connection and try again.';
      }
      return 'Cannot reach the server at ${Env.apiBaseUrl}. '
          'Start the local backend on port 4004.';
    }
    if (message.contains('TimeoutException') ||
        message.contains('timed out') ||
        message.contains('Connection timed out')) {
      if (Env.isProductionHost) {
        return 'Connection timed out. Check your internet and try again.';
      }
      return 'Connection timed out reaching ${Env.apiBaseUrl}. '
          'Ensure the backend is running on port 4004.';
    }
    if (message.contains('HandshakeException') ||
        message.contains('TlsException') ||
        message.contains('Secure connection')) {
      return 'Secure connection failed. Check your network and try again.';
    }
    if (message.contains('FormatException')) {
      return 'Invalid response from the server. Please try again.';
    }

    return message.replaceFirst('Exception: ', '').trim();
  }
}
