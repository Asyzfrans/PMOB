// lib/providers/donation_provider.dart
// Tidak ada Firestore stream — fetch REST on-demand

import 'package:flutter/foundation.dart';
import '../models/donation_model.dart';
import '../services/donation_service.dart';

class DonationProvider extends ChangeNotifier {
  final DonationService _service;

  List<DonationModel> _myDonations  = [];
  List<DonationModel> _allDonations = [];
  bool    _loading = false;
  String? _error;

  DonationProvider(this._service);

  bool    get loading      => _loading;
  String? get error        => _error;
  List<DonationModel> get myDonations  => _myDonations;
  List<DonationModel> get allDonations => _allDonations;

  // Total dari list yang sudah di-fetch
  double get totalDonated =>
      _service.totalDonated(_myDonations);

  // ── Load riwayat donasi (Donatur & Fundraiser) ────
  // GET /api/donations — backend filter by role otomatis
  Future<void> loadMyDonations() async {
    _loading = true; _error = null; notifyListeners();
    try {
      _myDonations = await _service.getMyDonations();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false; notifyListeners();
    }
  }

  // ── Load semua donasi (Admin) ─────────────────────
  Future<void> loadAll() async {
    _loading = true; _error = null; notifyListeners();
    try {
      _allDonations = await _service.getMyDonations(); // sama endpoint, admin lihat semua
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false; notifyListeners();
    }
  }

  // ── Donasi per kampanye (CampaignDetailScreen) ────
  Future<List<DonationModel>> getDonationsByCampaign(int campaignId) async {
    try {
      return await _service.getDonationsByCampaign(campaignId);
    } catch (_) {
      return [];
    }
  }

  // ── Record donasi baru ────────────────────────────
  Future<DonationModel?> donate({
    required int campaignId,
    required double amount,
    required PaymentMethod method,
    bool anon = false,
    String message = '',
  }) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final donation = await _service.recordDonation(
        campaignId: campaignId,
        amount:     amount,
        method:     method,
        anon:       anon,
        message:    message,
      );
      // Prepend ke list lokal tanpa refetch
      _myDonations = [donation, ..._myDonations];
      return donation;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _loading = false; notifyListeners();
    }
  }
}
