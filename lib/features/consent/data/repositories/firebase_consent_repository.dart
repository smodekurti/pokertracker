import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poker_tracker/features/consent/data/models/consent_status.dart';
import 'package:poker_tracker/features/consent/data/repositories/consent_repository.dart';

class FirebaseConsentRepository implements ConsentRepository {
  final FirebaseFirestore _firestore;

  FirebaseConsentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<ConsentStatus> getConsentStatus(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('consent')
          .doc('latest')
          .get();

      if (!doc.exists) {
        return ConsentStatus(cloudStorage: false, disclaimer: false);
      }

      return ConsentStatus.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get consent status: $e');
    }
  }

  @override
  Future<void> saveConsentStatus(String userId, ConsentStatus status) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('consent')
          .doc('latest')
          .set(status.toJson());
    } catch (e) {
      throw Exception('Failed to save consent status: $e');
    }
  }
}
