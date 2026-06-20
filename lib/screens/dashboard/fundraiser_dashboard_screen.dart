// lib/screens/dashboard/fundraiser_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/campaign_model.dart';
import '../../models/donation_model.dart';
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

class _FundraiserDashboardScreenState extends State<FundraiserDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final email = context.read<AuthProvider>().currentUser!.email;
      context.read<CampaignProvider>().loadMyCampaigns(email);
      context.read<DonationProvider>().loadMyDonations();
    });
  }

  Future<void> _onRefresh() async {
    final email = context.read<AuthProvider>().currentUser!.email;
    await context.read<CampaignProvider>().loadMyCampaigns(email);
    await context.read<DonationProvider>().loadMyDonations();
  }

  void _openCreate(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CreateCampaignScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser!;
    final campaigns = context.watch<CampaignProvider>();
    final donations = context.watch<DonationProvider>();
    final tt = Theme.of(context).textTheme;

    final myCampaigns = campaigns.myCampaigns;
    final totalCollected = myCampaigns.fold(0.0, (s, c) => s + c.collected);
    final totalDonors = myCampaigns.fold(0, (s, c) => s + c.donors);

    // Donasi yang masuk ke kampanye milik fundraiser ini saja
    final myCampaignIds = myCampaigns.map((c) => c.id).toSet();
    final myDonations = donations.allDonations.isNotEmpty
        ? donations.allDonations
            .where((d) => myCampaignIds.contains(int.tryParse(d.campaignId)))
            .toList()
        : <DonationModel>[];

    return Scaffold(
      body: Column(
        children: [
          Container(height: 4, color: AppColors.brand700),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brand700,
              onRefresh: _onRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    leading: IconButton(
                      icon:
                          const Icon(Icons.arrow_back, color: AppColors.ink900),
                      tooltip: 'Kembali ke Beranda',
                      onPressed: () => Navigator.of(context).pop(),
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
                        Row(children: [
                          Expanded(
                              child: StatCard(
                            label: 'Dana Terkumpul',
                            value: fmtMoney(totalCollected),
                            icon: Icons.savings_outlined,
                            iconColor: AppColors.brand700,
                            iconBg: AppColors.brand50,
                          )),
                          const SizedBox(width: 12),
                          Expanded(
                              child: StatCard(
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
                        SectionHeader(
                          title: 'Kampanyeku',
                          actionLabel: '+ Buat Baru',
                          onAction: () => _openCreate(context),
                        ),
                        const SizedBox(height: 12),
                        if (campaigns.loading)
                          const LoadingOverlay()
                        else if (myCampaigns.isEmpty)
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
                        const SectionHeader(title: 'Donasi Terbaru'),
                        const SizedBox(height: 12),
                        if (myDonations.isEmpty)
                          const EmptyState(
                            icon: Icons.inbox_outlined,
                            title: 'Belum ada donasi',
                            subtitle:
                                'Donasi ke kampanyemu akan tampil di sini',
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.ink200),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Column(
                                children: myDonations
                                    .map((d) => DonationTile(donation: d))
                                    .toList(),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
              width: 56,
              height: 56,
              child: campaign.imageUrl.isNotEmpty
                  ? Image.network(campaign.imageUrl,
                      fit: BoxFit.cover,
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
                  style: tt.bodySmall?.copyWith(color: AppColors.brand700),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: campaign.progressPercent / 100,
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
