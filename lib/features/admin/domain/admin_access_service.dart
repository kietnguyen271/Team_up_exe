class AdminIdentity {
  const AdminIdentity({required this.uid, required this.email});

  final String uid;
  final String email;
}

abstract interface class AdminAuthGateway {
  Future<AdminIdentity> signIn(String email, String password);
  Future<AdminIdentity?> currentIdentity();
  Future<void> signOut();
}

abstract interface class AdminDirectory {
  Future<bool> containsEmail(String emailLowercase);
}

class AdminAccessService {
  const AdminAccessService(this.auth, this.directory);

  final AdminAuthGateway auth;
  final AdminDirectory directory;

  Future<bool> signIn(String email, String password) async {
    final identity = await auth.signIn(email, password);
    return _check(identity);
  }

  Future<bool> currentIsAdmin() async {
    final identity = await auth.currentIdentity();
    if (identity == null) return false;
    return _check(identity);
  }

  Future<bool> _check(AdminIdentity identity) async {
    final allowed =
        await directory.containsEmail(identity.email.trim().toLowerCase());
    if (!allowed) await auth.signOut();
    return allowed;
  }
}
