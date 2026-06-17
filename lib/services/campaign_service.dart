// lib/services/campaign_service.dart
// REST version — tidak ada Firebase / Firestore

import 'dart:io';
import '../models/campaign_model.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class CampaignService {
  final ApiClient _api;
  CampaignService(this._api);

  // ── GET /api/campaigns ────────────────────────────
  Future<List<CampaignModel>> getCampaigns({
    String? status,
    String? category,
    String? search,
  }) async {
    final query = <String, String>{};
    if (status   != null) query['status']   = status;
    if (category != null) query['category'] = category;
    if (search   != null && search.isNotEmpty) query['search'] = search;

    final res  = await _api.get('/campaigns', query: query);
    final list = res['data'] as List<dynamic>;
    return list
        .map((e) => CampaignModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── GET /api/campaigns/{id} ───────────────────────
  Future<CampaignModel> getCampaignById(int id) async {
    final res = await _api.get('/campaigns/$id');
    return CampaignModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ── GET campaigns milik fundraiser ────────────────
  Future<List<CampaignModel>> getMyCampaigns(String email) async {
    // Backend filter by creator_email via GET /campaigns?created_by=email
    // Atau ambil semua lalu filter di client (lebih simple untuk sekarang)
    final all = await getCampaigns();
    return all.where((c) => c.createdBy == email).toList();
  }

  // ── POST /api/campaigns ───────────────────────────
  // Memakai multipart karena ada file upload gambar
  Future<CampaignModel> createCampaign({
    required String title,
    required String description,
    required double target,
    required CampaignCategory category,
    required UserSession creator,
    File? imageFile,
    DateTime? deadline,
  }) async {
    final fields = <String, String>{
      'title':       title.trim(),
      'description': description.trim(),
      'target':      target.toStringAsFixed(0),
      'category':    category.name,
      if (deadline != null)
        'deadline': '${deadline.year}-${deadline.month.toString().padLeft(2,'0')}-${deadline.day.toString().padLeft(2,'0')}',
    };

    final res = await _api.postMultipart(
      '/campaigns',
      fields:    fields,
      imageFile: imageFile,
    );
    return CampaignModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ── PUT /api/campaigns/{id} — admin update status ─
  Future<CampaignModel> updateStatus(int id, CampaignStatus status) async {
    final res = await _api.put('/campaigns/$id', body: {
      'status': status.name,
    });
    return CampaignModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ── PUT /api/campaigns/{id} — fundraiser update ───
  Future<CampaignModel> updateCampaign(
    int id, {
    String? title,
    String? description,
    DateTime? deadline,
    File? imageFile,
  }) async {
    if (imageFile != null) {
      // Perlu multipart kalau ada gambar baru
      final fields = <String, String>{
        '_method': 'PUT',
        if (title       != null) 'title':       title,
        if (description != null) 'description': description,
        if (deadline    != null)
          'deadline': '${deadline.year}-${deadline.month.toString().padLeft(2,'0')}-${deadline.day.toString().padLeft(2,'0')}',
      };
      final res = await _api.postMultipart(
        '/campaigns/$id',
        fields:    fields,
        imageFile: imageFile,
      );
      return CampaignModel.fromJson(res['data'] as Map<String, dynamic>);
    }

    final body = <String, dynamic>{
      if (title       != null) 'title':       title,
      if (description != null) 'description': description,
      if (deadline    != null)
        'deadline': '${deadline.year}-${deadline.month.toString().padLeft(2,'0')}-${deadline.day.toString().padLeft(2,'0')}',
    };
    final res = await _api.put('/campaigns/$id', body: body);
    return CampaignModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ── DELETE /api/campaigns/{id} ────────────────────
  Future<void> deleteCampaign(int id) async {
    await _api.delete('/campaigns/$id');
  }
}
