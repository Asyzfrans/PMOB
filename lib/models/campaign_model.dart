// lib/models/campaign_model.dart
// Tidak ada import Firebase — murni dari JSON REST

enum CampaignStatus   { pending, active, completed, rejected }
enum CampaignCategory { kesehatan, pendidikan, bencana, lingkungan, sosial, lainnya }

class CampaignModel {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final double target;
  final double collected;
  final int donors;
  final String createdBy;
  final String creatorName;
  final CampaignStatus status;
  final CampaignCategory category;
  final DateTime? deadline;
  final DateTime createdAt;
  final double progressPercent;
  final int? daysLeft;

  const CampaignModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.target,
    this.collected = 0,
    this.donors = 0,
    required this.createdBy,
    required this.creatorName,
    this.status = CampaignStatus.pending,
    required this.category,
    this.deadline,
    required this.createdAt,
    this.progressPercent = 0,
    this.daysLeft,
  });

  // Laravel mengembalikan progress_percent & days_left langsung
  factory CampaignModel.fromJson(Map<String, dynamic> json) => CampaignModel(
    id:          (json['id'] as int?) ?? 0,
    title:       json['title']        as String? ?? '',
    description: json['description']  as String? ?? '',
    imageUrl:    json['image_url']    as String? ?? '',
    target:      (json['target']      as num?)?.toDouble() ?? 0,
    collected:   (json['collected']   as num?)?.toDouble() ?? 0,
    donors:      (json['donors']      as int?) ?? 0,
    createdBy:   json['created_by']   as String? ?? '',
    creatorName: json['creator_name'] as String? ?? '',
    status: CampaignStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => CampaignStatus.pending,
    ),
    category: CampaignCategory.values.firstWhere(
      (c) => c.name == json['category'],
      orElse: () => CampaignCategory.lainnya,
    ),
    deadline: json['deadline'] != null
        ? DateTime.tryParse(json['deadline'] as String)
        : null,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
        : DateTime.now(),
    progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0,
    daysLeft:        json['days_left']  as int?,
  );

  bool get isActive => status == CampaignStatus.active;
  int  get progressInt => progressPercent.round();

  CampaignModel copyWith({
    int? id, String? title, String? description, String? imageUrl,
    double? target, double? collected, int? donors,
    String? createdBy, String? creatorName,
    CampaignStatus? status, CampaignCategory? category,
    DateTime? deadline, DateTime? createdAt,
    double? progressPercent, int? daysLeft,
  }) => CampaignModel(
    id:              id              ?? this.id,
    title:           title           ?? this.title,
    description:     description     ?? this.description,
    imageUrl:        imageUrl        ?? this.imageUrl,
    target:          target          ?? this.target,
    collected:       collected       ?? this.collected,
    donors:          donors          ?? this.donors,
    createdBy:       createdBy       ?? this.createdBy,
    creatorName:     creatorName     ?? this.creatorName,
    status:          status          ?? this.status,
    category:        category        ?? this.category,
    deadline:        deadline        ?? this.deadline,
    createdAt:       createdAt       ?? this.createdAt,
    progressPercent: progressPercent ?? this.progressPercent,
    daysLeft:        daysLeft        ?? this.daysLeft,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CampaignModel && other.id == id;
  @override
  int get hashCode => id.hashCode;
}
