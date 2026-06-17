// lib/screens/campaigns/campaign_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/campaign_model.dart';
import '../../providers/campaign_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'campaign_detail_screen.dart';

class CampaignListScreen extends StatefulWidget {
  const CampaignListScreen({super.key});
  @override
  State<CampaignListScreen> createState() => _CampaignListScreenState();
}

class _CampaignListScreenState extends State<CampaignListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CampaignProvider>().loadActive();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kampanye'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.ink200),
        ),
      ),
      body: Column(children: [
        _SearchAndFilter(),
        const Expanded(child: _CampaignResults()),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────
// SEARCH + FILTER
// ─────────────────────────────────────────────────────────

class _SearchAndFilter extends StatefulWidget {
  @override
  State<_SearchAndFilter> createState() => _SearchAndFilterState();
}

class _SearchAndFilterState extends State<_SearchAndFilter> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CampaignProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Colors.white,
      child: Column(children: [
        TextField(
          controller: _ctrl,
          onChanged: provider.setSearch,
          decoration: InputDecoration(
            hintText: 'Cari kampanye...',
            prefixIcon:
                const Icon(Icons.search, color: AppColors.ink500),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _ctrl.clear();
                      provider.setSearch('');
                    })
                : null,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                label: 'Semua',
                selected: provider.filterCategory == null,
                onTap: () => provider.setFilterCategory(null),
              ),
              ...CampaignCategory.values.map((cat) => _FilterChip(
                    label: cat.name[0].toUpperCase() +
                        cat.name.substring(1),
                    selected: provider.filterCategory == cat,
                    onTap: () => provider.setFilterCategory(cat),
                  )),
            ],
          ),
        ),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand700 : AppColors.ink100,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? AppColors.brand700 : AppColors.ink200,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.ink700,
            )),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// RESULTS
// ─────────────────────────────────────────────────────────

class _CampaignResults extends StatelessWidget {
  const _CampaignResults();

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<CampaignProvider>();
    final campaigns = provider.filteredCampaigns;

    if (provider.error != null) {
      return Center(child: Text('Error: ${provider.error}'));
    }
    if (campaigns.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_outlined,
        title: 'Tidak ditemukan',
        subtitle: 'Coba ubah kata kunci atau filter',
        action: TextButton(
          onPressed: () =>
              context.read<CampaignProvider>().clearFilters(),
          child: const Text('Reset Filter'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: campaigns.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (ctx, i) => CampaignCard(
        campaign: campaigns[i],
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                CampaignDetailScreen(campaignId: campaigns[i].id))),
      ),
    );
  }
}
