// lib/screens/dashboard/fundraiser_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/campaign_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/donation_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_widgets.dart';
import '../campaigns/campaign_detail_screen.dart';
import 'create_campaign_screen.dart';

class FundraiserDashboardScreen extends StatefulWidget {
  const FundraiserDashboardScreen({super.key});
  @override
  State<FundraiserDashboardScreen> createState() =>
      _FundraiserDashboardScreenState();
}

class _FundraiserDashboardScreenState
    extends State<FundraiserDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final email = context.read<AuthProvider>().currentUser!.email;
      context.read<CampaignProvider>().loadMyCampaigns(email);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<AuthProvider>();
    final user      = auth.currentUser!;
    final campaigns = context.watch<CampaignProvider>();
    final tt        = Theme.of(context).textTheme;

    final myCampaigns    = campaigns.myCampaigns;
    final totalCollected = myCampaigns.fold(0.0, (s, c) => s + c.collected);
    final totalDonors    = myCampaigns.fold(0, (s, c) => s + c.donors);
    final campaignIds    = myCampaigns.map((c) => c.id).toList();

    return Scaffold(
      body: Column(
        children: [
          Container(height: 4, color: AppColors.brand700),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  leading: Padding(
                    padding: const EdgeInsets.all(8),
                    child: UserAvatar(initial: user.initial, size: 36),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Halo, ${user.name.split(' ').first}! 🙌',
                          style: tt.headlineSmall),
                      Text('Dashboard Fundraiser', style: tt.bodySmall),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: AppColors.brand700),
                      onPressed: () => _openCreate(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: AppColors.ink600),
                      onPressed: () async {
                        await auth.logout();
                        if (context.mounted) {
                          Navigator.of(context)
                              .pushNamedAndRemoveUntil('/', (_) => false);
                        }
                      },
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(height: 1, color: AppColors.ink200),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Stats
                      Row(children: [
                        Expanded(child: StatCard(
                          label: 'Dana Terkumpul',
                          value: fmtMoney(totalCollected),
                          icon: Icons.savings_outlined,
                          iconColor: AppColors.brand700,
                          iconBg: AppColors.brand50,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: StatCard(
                          label: 'Total Donatur',
                          value: '$totalDonors',
                          icon: Icons.people_outline,
                          iconColor: const Color(0xFF1E40AF),
                          iconBg: const Color(0xFFDBEAFE),
                        )),
                      ]),
                      const SizedBox(height: 12),
                      StatCard(
                        label: 'Jumlah Kampanye',
                        value: '${myCampaigns.length}',
                        icon: Icons.campaign_outlined,
                        iconColor: const Color(0xFF065F46),
                        iconBg: const Color(0xFFD1FAE5),
                      ),
                      const SizedBox(height: 28),

                      // Kampanyeku
                      SectionHeader(
                        title: 'Kampanyeku',
                        actionLabel: '+ Buat Baru',
                        onAction: () => _openCreate(context),
                      ),
                      const SizedBox(height: 12),
                      if (myCampaigns.isEmpty)
                        EmptyState(
                          icon: Icons.campaign_outlined,
                          title: 'Belum ada kampanye',
                          subtitle:
                              'Buat kampanye pertamamu dan mulai menggalang dana!',
                          action: ElevatedButton(
                            onPressed: () => _openCreate(context),
                            child: const Text('Buat Kampanye'),
                          ),
                        )
                      else
                        ...myCampaigns.map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _MyCampaignTile(
                                campaign: c,
                                onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) => CampaignDetailScreen(
                                            campaignId: c.id))),
                              ),
                            )),
                      const SizedBox(height: 28),

                      // Donasi terbaru (stream)
                      const SectionHeader(title: 'Donasi Terbaru'),
                      const SizedBox(height: 12),
                      if (campaignIds.isEmpty)
                        const EmptyState(
                          icon: Icons.inbox_outlined,
                          title: 'Belum ada donasi',
                          subtitle:
                              'Donasi ke kampanyemu akan tampil di sini',
                        )
                      else
                        _DonationsSection(campaignIds: campaignIds),
                      const SizedBox(height: 20),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openCreate(BuildContext context) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreateCampaignScreen()));
  }
}

class _MyCampaignTile extends StatelessWidget {
  final CampaignModel campaign;
  final VoidCallback onTap;
  const _MyCampaignTile({required this.campaign, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.ink200),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56, height: 56,
              child: campaign.imageUrl.startsWith('http')
                  ? Image.network(campaign.imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppColors.ink100))
                  : Container(color: AppColors.ink100),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(campaign.title,
                        style: tt.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(campaign.status),
                ]),
                const SizedBox(height: 4),
                Text(
                  '${fmtMoney(campaign.collected)} / ${fmtMoney(campaign.target)}',
                  style: tt.bodySmall
                      ?.copyWith(color: AppColors.brand700),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: campaign.progressPercent,
                    backgroundColor: AppColors.ink100,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.brand700),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.ink500),
        ]),
      ),
    );
  }
}

// ── Donations section (loads per campaign via REST) ───────────────────────────
class _DonationsSection extends StatefulWidget {
  final List<String> campaignIds;
  const _DonationsSection({required this.campaignIds});

  @override
  State<_DonationsSection> createState() => _DonationsSectionState();
}

class _DonationsSectionState extends State<_DonationsSection> {
  List<DonationModel> _donations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = context.read<DonationProvider>();
    await provider.loadDonations();
    if (mounted) {
      setState(() {
        _donations = provider.donations
            .where((d) => widget.campaignIds.contains(d.campaignId))
            .toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingOverlay();
    if (_donations.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_outlined,
        title: 'Belum ada donasi',
        subtitle: 'Donasi ke kampanyemu akan tampil di sini',
      );
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.ink200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: _donations.map((d) => DonationTile(donation: d)).toList(),
        ),
      ),
    );
  }
}
