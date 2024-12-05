import 'package:poker_tracker/features/consent/data/models/consent_status.dart';

abstract class ConsentRepository {
  Future<ConsentStatus> getConsentStatus(String userId);
  Future<void> saveConsentStatus(String userId, ConsentStatus status);
}
