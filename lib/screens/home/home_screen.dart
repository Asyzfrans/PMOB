// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/campaign_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_widgets.dart';
import '../auth/login_screen.dart';
import '../campaigns/campaign_list_screen.dart';
import '../campaigns/campaign_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CampaignProvider>().loadActive();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Column(
        children: [
          Container(height: 4, color: AppColors.brand700),
          Expanded(
            child: NestedScrollView(
              headerSliverBuilder: (ctx, _) => [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  title: const DonateIDLogo(),
                  actions: [
                    if (auth.isAuthenticated)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => _showUserMenu(context, auth),
                          child: UserAvatar(
                              initial: auth.currentUser!.initial, size: 36),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: TextButton(
                          onPressed: () => Navigator.of(context)
                              .push(LoginScreen.route()),
                          child: const Text('Masuk',
                              style: TextStyle(
                                  color: AppColors.brand700,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(height: 1, color: AppColors.ink200),
                  ),
                ),
              ],
              body: RefreshIndicator(
                color: AppColors.brand700,
                onRefresh: () async =>
                    context.read<CampaignProvider>().loadActive(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeroSection(auth: auth),
                      const SizedBox(height: 32),
                      const _StatsBar(),
                      const SizedBox(height: 32),
                      SectionHeader(
                        title: 'Kampanye Aktif',
                        actionLabel: 'Lihat semua',
                        onAction: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const CampaignListScreen()),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _CampaignGrid(),
                      const SizedBox(height: 40),
                      const _HowItWorks(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserMenu(BuildContext context, AuthProvider auth) {
    final user = auth.currentUser!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.ink200,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Row(children: [
              UserAvatar(initial: user.initial, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(user.email,
                        style: const TextStyle(
                            color: AppColors.ink600, fontSize: 13)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.brand50,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(user.roleLabel,
                          style: const TextStyle(
                              color: AppColors.brand700,
                              fontWeight: FontWeight.w700,
                              fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 20),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined,
                  color: AppColors.brand700),
              title: const Text('Dashboard'),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onTap: () {
                Navigator.pop(context);
                final route = auth.isAdmin
                    ? '/admin'
                    : auth.isFundraiser
                        ? '/fundraiser'
                        : '/donor';
                Navigator.of(context).pushNamed(route);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.logout, color: AppColors.ink600),
              title: const Text('Keluar'),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onTap: () async {
                Navigator.pop(context);
                await auth.logout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// HERO
// ─────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final AuthProvider auth;
  const _HeroSection({required this.auth});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brand800, AppColors.brand600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.volunteer_activism,
              color: Colors.white54, size: 32),
          const SizedBox(height: 12),
          Text(
            'Bersama Kita\nBisa Mengubah\nHidup',
            style: tt.displaySmall?.copyWith(
                color: Colors.white, height: 1.2),
          ),
          const SizedBox(height: 12),
          Text(
            'Donasikan sebagian rezekimu untuk mereka yang membutuhkan.',
            style: tt.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Row(children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.brand700,
              ),
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const CampaignListScreen())),
              child: const Text('Donasi Sekarang'),
            ),
            if (!auth.isAuthenticated) ...[
              const SizedBox(width: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                onPressed: () => Navigator.of(context)
                    .push(LoginScreen.route()),
                child: const Text('Masuk'),
              ),
            ],
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// STATS BAR
// ─────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  const _StatsBar();

  @override
  Widget build(BuildContext context) {
    final campaigns = context.watch<CampaignProvider>().activeCampaigns;
    final totalCollected = campaigns.fold(0.0, (s, c) => s + c.collected);
    final totalDonors    = campaigns.fold(0, (s, c) => s + c.donors);

    return Row(children: [
      Expanded(child: _StatItem(
          value: '${campaigns.length}',
          label: 'Kampanye Aktif',
          icon: Icons.campaign_outlined)),
      _VDivider(),
      Expanded(child: _StatItem(
          value: '$totalDonors',
          label: 'Total Donatur',
          icon: Icons.people_outline)),
      _VDivider(),
      Expanded(child: _StatItem(
          value: _shortMoney(totalCollected),
          label: 'Dana Terkumpul',
          icon: Icons.savings_outlined)),
    ]);
  }

  String _shortMoney(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}M';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(0)}jt';
    return '${(v / 1000).toStringAsFixed(0)}rb';
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _StatItem(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(children: [
      Icon(icon, color: AppColors.brand700, size: 22),
      const SizedBox(height: 6),
      Text(value,
          style: tt.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800, fontSize: 20)),
      Text(label, style: tt.bodySmall, textAlign: TextAlign.center),
    ]);
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1,
      height: 48,
      color: AppColors.ink200,
      margin: const EdgeInsets.symmetric(horizontal: 4));
}

// ─────────────────────────────────────────────────────────
// CAMPAIGN GRID (4 kampanye pertama)
// ─────────────────────────────────────────────────────────

class _CampaignGrid extends StatelessWidget {
  const _CampaignGrid();

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<CampaignProvider>();
    final campaigns = provider.activeCampaigns.take(4).toList();

    if (campaigns.isEmpty) {
      return const EmptyState(
        icon: Icons.campaign_outlined,
        title: 'Belum ada kampanye',
        subtitle: 'Kampanye aktif akan muncul di sini',
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
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

// ─────────────────────────────────────────────────────────
// HOW IT WORKS
// ─────────────────────────────────────────────────────────

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final steps = [
      (Icons.search_outlined, 'Pilih Kampanye',
          'Temukan kampanye yang sesuai dengan kepedulianmu'),
      (Icons.payment_outlined, 'Lakukan Donasi',
          'Donasikan dengan mudah melalui berbagai metode pembayaran'),
      (Icons.volunteer_activism_outlined, 'Buat Dampak',
          'Donasimu membantu kehidupan nyata orang yang membutuhkan'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cara Kerja DonateID', style: tt.headlineLarge),
        const SizedBox(height: 16),
        ...steps.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.brand50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(s.$1,
                        color: AppColors.brand700, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.$2,
                            style: tt.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(s.$3, style: tt.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
