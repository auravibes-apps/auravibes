enum CloudAuthMode { login, register, forgotPassword }

typedef CloudAuthNavigation = ({
  CloudAuthMode mode,
  String email,
  bool passwordChanged,
});
