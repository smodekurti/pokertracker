import 'package:flutter/foundation.dart';

class ConsentProvider with ChangeNotifier {
  bool _hasAcceptedForSession = false;
  bool _isLoading = false;

  bool get hasAcceptedForSession => _hasAcceptedForSession;
  bool get isLoading => _isLoading;

  void acceptConsent() {
    _hasAcceptedForSession = true;
    notifyListeners();
  }

  void reset() {
    _hasAcceptedForSession = false;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
