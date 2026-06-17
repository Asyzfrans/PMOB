// lib/screens/dashboard/donor_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/donation_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_widgets.dart';
import '../campaigns/campaign_list_screen.dart';
import '../campaigns/campaign_detail_screen.dart';

class DonorDashboardScreen extends StatefulWidget {
  const DonorDashboardScreen({super.key});
  @override
  State<DonorDashboardScreen> createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DonationProvider>().loadMyDonations();
      context.read<CampaignProvider>().loadActive();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<DonationProvider>().loadMyDonations();
    await context.read<CampaignProvider>().loadActive();
  }

  @override
  Widget build(BuildContext context) {
    final auth         = context.watch<AuthProvider>();
    final user          = auth.currentUser!;
    final donProvider  = context.watch<DonationProvider>();
    final campProvider = context.watch<CampaignProvider>();
    final tt           = Theme.of(context).textTheme;

    final myDonations  = donProvider.myDonations;
    final totalDonated = myDonations.fold(0.0, (s, d) => s + d.amount);

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
                    leading: Padding(
                      padding: const EdgeInsets.all(8),
                      child: UserAvatar(initial: user.initial, size: 36),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Halo, ${user.name.split(' ').first}! 👋',
                            style: tt.headlineSmall),
                        Text('Dashboard Donatur', style: tt.bodySmall),
                      ],
                    ),
                    actions: [
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
                          Expanded(child: StatCard(
                            label: 'Total Donasi',
                            value: fmtMoney(totalDonated),
                            icon: Icons.favorite_outline,
                            iconColor: AppColors.brand700,
                            iconBg: AppColors.brand50,
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: StatCard(
                            label: 'Kampanye Didukung',
                            value: '${myDonations.length}',
                            icon: Icons.campaign_outlined,
                            iconColor: const Color(0xFF1E40AF),
                            iconBg: const Color(0xFFDBEAFE),
                          )),
                        ]),
                        const SizedBox(height: 28),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.brand800, AppColors.brand600],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(children: [
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Mulai Berdonasi',
                                    style: tt.headlineSmall
                                        ?.copyWith(color: Colors.white)),
                                const SizedBox(height: 4),
                                Text('Temukan kampanye yang membutuhkan bantuanmu',
                                    style: tt.bodySmall
                                        ?.copyWith(color: Colors.white70)),
                                const SizedBox(height: 14),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.brand700,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 10),
                                  ),
                                  onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const CampaignListScreen())),
                                  child: const Text('Lihat Kampanye'),
                                ),
                              ],
                            )),
                            const Icon(Icons.volunteer_activism,
                                color: Colors.white24, size: 56),
                          ]),
                        ),
                        const SizedBox(height: 28),

                        const SectionHeader(title: 'Riwayat Donasiku'),
                        const SizedBox(height: 12),
                        if (myDonations.isEmpty)
                          const EmptyState(
                            icon: Icons.history_outlined,
                            title: 'Belum ada donasi',
                            subtitle: 'Yuk, mulai berdonasi dan bantu sesama!',
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
                        const SizedBox(height: 28),

                        SectionHeader(
                          title: 'Kampanye Untukmu',
                          actionLabel: 'Lihat semua',
                          onAction: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const CampaignListScreen())),
                        ),
                        const SizedBox(height: 12),
                        if (campProvider.loading)
                          const LoadingOverlay()
                        else
                          ...campProvider.activeCampaigns.take(3).map((c) =>
                              Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: CampaignCard(
                                  campaign: c,
                                  onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) => CampaignDetailScreen(
                                              campaignId: c.id))),
                                ),
                              )),
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
