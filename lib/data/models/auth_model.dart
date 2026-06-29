class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.name,
  });

  final String accessToken;
  final String refreshToken;
  final String? name;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      name: json['name']?.toString() ?? json['customer']?['name']?.toString(),
    );
  }
}

enum OtpPurpose { signup, login, resetPassword }

extension OtpPurposeApi on OtpPurpose {
  String get apiValue => switch (this) {
        OtpPurpose.signup => 'SIGNUP',
        OtpPurpose.login => 'LOGIN',
        OtpPurpose.resetPassword => 'RESET_PASSWORD',
      };
}
