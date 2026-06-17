// lib/models/donation_model.dart
// Tidak ada import Firebase — murni dari JSON REST

enum PaymentMethod  { transfer, qris, ewallet, kartuKredit }
enum DonationStatus { success, pending, failed }

class DonationModel {
  final int id;
  final String transactionId;
  final String campaignId;
  final String campaignTitle;
  final String donorEmail;
  final String donorName;
  final double amount;
  final PaymentMethod method;
  final bool anon;
  final String message;
  final DateTime date;
  final DonationStatus status;

  const DonationModel({
    required this.id,
    required this.transactionId,
    required this.campaignId,
    required this.campaignTitle,
    required this.donorEmail,
    required this.donorName,
    required this.amount,
    required this.method,
    this.anon = false,
    this.message = '',
    required this.date,
    this.status = DonationStatus.success,
  });

  String get displayName => anon ? 'Anonim' : donorName;

  factory DonationModel.fromJson(Map<String, dynamic> json) => DonationModel(
    id:             (json['id'] as int?) ?? 0,
    transactionId:  json['transaction_id']  as String? ?? '',
    campaignId:     json['campaign_id']?.toString() ?? '',
    campaignTitle:  json['campaign_title']  as String? ?? '',
    donorEmail:     json['donor_email']     as String? ?? '',
    donorName:      json['donor_name']      as String? ?? '',
    amount:         (json['amount']         as num?)?.toDouble() ?? 0,
    method: PaymentMethod.values.firstWhere(
      (m) => m.name == json['method'],
      orElse: () => PaymentMethod.transfer,
    ),
    anon:    (json['anon'] as bool?) ?? false,
    message: json['message'] as String? ?? '',
    date: json['date'] != null
        ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
        : DateTime.now(),
    status: DonationStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => DonationStatus.success,
    ),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DonationModel && other.id == id;
  @override
  int get hashCode => id.hashCode;
}
