import 'package:flutter/foundation.dart';
import '../services/backend_api.dart';

class AuthProvider extends ChangeNotifier {
  bool _ready = false;
  bool _authenticated = false;

  bool get isReady => _ready;
  bool get isAuthenticated => _authenticated;

  Future<void> load() async {
    final ok = await BackendApi.instance.loadToken();
    _authenticated = ok;
    _ready = true;
    notifyListeners();
  }

  void signInSucceeded() {
    _authenticated = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    await BackendApi.instance.clearToken();
    _authenticated = false;
    notifyListeners();
  }
}
