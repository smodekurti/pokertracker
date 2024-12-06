import 'package:cloud_firestore/cloud_firestore.dart';

class ConsentStatus {
  final bool cloudStorage;
  final bool disclaimer;
  final DateTime? updatedAt;

  ConsentStatus({
    required this.cloudStorage,
    required this.disclaimer,
    this.updatedAt,
  });

  bool get hasAcceptedAll => cloudStorage && disclaimer;

  factory ConsentStatus.fromJson(Map<String, dynamic> json) {
    return ConsentStatus(
      cloudStorage: json['cloudStorage'] ?? false,
      disclaimer: json['disclaimer'] ?? false,
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'cloudStorage': cloudStorage,
        'disclaimer': disclaimer,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
