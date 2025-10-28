import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/session.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService authService;

  bool _isLoading = false;
  String? _error;
  User? _user;

  LoginViewModel({required this.authService});

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final u = await authService.login(email, password);
      _user = u;
      // Si el backend devuelve un token, guardarlo en sesión
      if (u.token != null && u.token!.isNotEmpty) {
        await Session.saveToken(u.token!);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
