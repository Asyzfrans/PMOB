// lib/services/donation_service.dart
// REST version — tidak ada Firebase

import '../models/donation_model.dart';
import 'api_client.dart';

class DonationService {
  final ApiClient _api;
  DonationService(this._api);

  // ── GET /api/donations ────────────────────────────
  // Backend otomatis filter berdasarkan role user yang login
  Future<List<DonationModel>> getMyDonations() async {
    final res  = await _api.get('/donations');
    final list = res['data'] as List<dynamic>;
    return list
        .map((e) => DonationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── GET /api/campaigns/{id}/donations ─────────────
  Future<List<DonationModel>> getDonationsByCampaign(int campaignId) async {
    final res  = await _api.get('/campaigns/$campaignId/donations');
    final list = res['data'] as List<dynamic>;
    return list
        .map((e) => DonationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── POST /api/donations ───────────────────────────
  Future<DonationModel> recordDonation({
    required int campaignId,
    required double amount,
    required PaymentMethod method,
    bool anon = false,
    String message = '',
  }) async {
    final res = await _api.post('/donations', body: {
      'campaign_id': campaignId,
      'amount':      amount,
      'method':      method.name,
      'anon':        anon,
      'message':     message,
    });
    return DonationModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ── Stats helpers (dihitung di client dari list) ──
  double totalDonated(List<DonationModel> donations) =>
      donations.fold(0.0, (s, d) => s + d.amount);

  int uniqueDonors(List<DonationModel> donations) =>
      donations.map((d) => d.donorEmail).toSet().length;
}
