// lib/providers/campaign_provider.dart
// Tidak ada Firestore stream — fetch REST on-demand

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/campaign_model.dart';
import '../models/user_model.dart';
import '../services/campaign_service.dart';

class CampaignProvider extends ChangeNotifier {
  final CampaignService _service;

  List<CampaignModel> _all     = [];
  List<CampaignModel> _active  = [];
  List<CampaignModel> _my      = [];
  List<CampaignModel> _pending = [];

  bool    _loading = false;
  String? _error;
  String  _searchQuery     = '';
  CampaignCategory? _filterCategory;

  CampaignProvider(this._service);

  // ── Getters ───────────────────────────────────────
  bool    get loading          => _loading;
  String? get error            => _error;
  String  get searchQuery      => _searchQuery;
  CampaignCategory? get filterCategory => _filterCategory;

  List<CampaignModel> get allCampaigns     => _all;
  List<CampaignModel> get activeCampaigns  => _active;
  List<CampaignModel> get myCampaigns      => _my;
  List<CampaignModel> get pendingCampaigns => _pending;

  List<CampaignModel> get filteredCampaigns {
    var list = _active;
    if (_filterCategory != null) {
      list = list.where((c) => c.category == _filterCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) =>
          c.title.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q) ||
          c.creatorName.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  CampaignModel? getById(int id) {
    try { return _all.firstWhere((c) => c.id == id); }
    catch (_) { return null; }
  }

  // ── Load: active campaigns (HomeScreen, CampaignListScreen) ──
  Future<void> loadActive() async {
    _loading = true; _error = null; notifyListeners();
    try {
      _active = await _service.getCampaigns(status: 'active');
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false; notifyListeners();
    }
  }

  // ── Load: all campaigns (AdminDashboard) ─────────
  Future<void> loadAll() async {
    _loading = true; _error = null; notifyListeners();
    try {
      _all     = await _service.getCampaigns();
      _pending = _all.where((c) => c.status == CampaignStatus.pending).toList();
      _active  = _all.where((c) => c.status == CampaignStatus.active).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false; notifyListeners();
    }
  }

  // ── Load: my campaigns (FundraiserDashboard) ─────
  Future<void> loadMyCampaigns(String email) async {
    _loading = true; _error = null; notifyListeners();
    try {
      _my = await _service.getMyCampaigns(email);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false; notifyListeners();
    }
  }

  // ── Refresh campaign tunggal setelah donasi ───────
  Future<void> refreshCampaign(int id) async {
    try {
      final updated = await _service.getCampaignById(id);
      // Update di semua list
      _all     = _replaceIn(_all,    updated);
      _active  = _replaceIn(_active, updated);
      _my      = _replaceIn(_my,     updated);
      _pending = _replaceIn(_pending, updated);
      notifyListeners();
    } catch (_) {}
  }

  List<CampaignModel> _replaceIn(List<CampaignModel> list, CampaignModel updated) =>
      list.map((c) => c.id == updated.id ? updated : c).toList();

  // ── Filters ───────────────────────────────────────
  void setSearch(String q)                    { _searchQuery = q;   notifyListeners(); }
  void setFilterCategory(CampaignCategory? c) { _filterCategory = c; notifyListeners(); }
  void clearFilters() {
    _searchQuery = ''; _filterCategory = null; notifyListeners();
  }

  // ── Create ────────────────────────────────────────
  Future<bool> createCampaign({
    required String title,
    required String description,
    required double target,
    required CampaignCategory category,
    required UserSession creator,
    File? imageFile,
    DateTime? deadline,
  }) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final campaign = await _service.createCampaign(
        title: title, description: description,
        target: target, category: category,
        creator: creator, imageFile: imageFile, deadline: deadline,
      );
      _my = [campaign, ..._my];
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  // ── Admin: approve / reject ───────────────────────
  Future<void> approveCampaign(int id) async {
    try {
      final updated = await _service.updateStatus(id, CampaignStatus.active);
      _replaceInAll(updated);
      notifyListeners();
    } catch (e) { _error = e.toString(); notifyListeners(); }
  }

  Future<void> rejectCampaign(int id) async {
    try {
      final updated = await _service.updateStatus(id, CampaignStatus.rejected);
      _replaceInAll(updated);
      notifyListeners();
    } catch (e) { _error = e.toString(); notifyListeners(); }
  }

  Future<void> deleteCampaign(int id) async {
    try {
      await _service.deleteCampaign(id);
      _all     = _all.where((c)     => c.id != id).toList();
      _active  = _active.where((c)  => c.id != id).toList();
      _pending = _pending.where((c) => c.id != id).toList();
      _my      = _my.where((c)      => c.id != id).toList();
      notifyListeners();
    } catch (e) { _error = e.toString(); notifyListeners(); }
  }

  void _replaceInAll(CampaignModel updated) {
    _all     = _replaceIn(_all,     updated);
    _active  = _replaceIn(_active,  updated);
    _pending = _replaceIn(_pending, updated);
    _my      = _replaceIn(_my,      updated);
  }
}
