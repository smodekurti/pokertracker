import 'package:flutter/foundation.dart';

class ConsentProvider extends ChangeNotifier {
  bool _hasAcceptedCurrentSession = false;
  bool _isLoading = false;

  bool get hasAcceptedCurrentSession => _hasAcceptedCurrentSession;
  bool get isLoading => _isLoading;

  void setAccepted() {
    _hasAcceptedCurrentSession = true;
    notifyListeners();
  }

  void acceptConsent() {
    _isLoading = true;
    notifyListeners();

    // Simulate any async work if needed
    _hasAcceptedCurrentSession = true;
    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _hasAcceptedCurrentSession = false;
    notifyListeners();
  }
}
