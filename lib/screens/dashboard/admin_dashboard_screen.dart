// lib/screens/dashboard/admin_dashboard_screen.dart

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

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CampaignProvider>().loadAll();
      
      context.read<DonationProvider>().loadDonations();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<AuthProvider>();
    final user      = auth.currentUser!;
    final campaigns = context.watch<CampaignProvider>();
    final donations = context.watch<DonationProvider>();
    final tt        = Theme.of(context).textTheme;

    final allCampaigns = campaigns.allCampaigns;
    final allDonations = donations.allDonations;
    final totalFunds   = allCampaigns.fold(0.0, (s, c) => s + c.collected);

    return Scaffold(
      body: Column(
        children: [
          Container(height: 4, color: AppColors.brand700),
          Expanded(
            child: NestedScrollView(
              headerSliverBuilder: (ctx, _) => [
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
                      Text('Admin Panel', style: tt.headlineSmall),
                      Text(user.email, style: tt.bodySmall),
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
                  bottom: TabBar(
                    controller: _tabs,
                    labelColor: AppColors.brand700,
                    unselectedLabelColor: AppColors.ink600,
                    indicatorColor: AppColors.brand700,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    tabs: [
                      Tab(
                        text: 'Review',
                        icon: campaigns.pendingCampaigns.isNotEmpty
                            ? Badge(
                                label: Text(
                                    '${campaigns.pendingCampaigns.length}'),
                                child: const Icon(Icons.pending_outlined,
                                    size: 20))
                            : const Icon(Icons.pending_outlined, size: 20),
                      ),
                      const Tab(text: 'Kampanye',
                          icon: Icon(Icons.campaign_outlined, size: 20)),
                      const Tab(text: 'Donasi',
                          icon: Icon(Icons.history_outlined, size: 20)),
                    ],
                  ),
                ),
              ],
              body: Column(
                children: [
                  // Stats bar
                  Container(
                    color: AppColors.ink50,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(children: [
                      _AdminStat(label: 'Kampanye',
                          value: '${allCampaigns.length}'),
                      _vDivider(),
                      _AdminStat(label: 'Donasi',
                          value: '${allDonations.length}'),
                      _vDivider(),
                      _AdminStat(label: 'Dana', value: fmtMoney(totalFunds)),
                    ]),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        _PendingTab(campaigns: campaigns),
                        _AllCampaignsTab(campaigns: campaigns),
                        _DonationsTab(donations: allDonations),
                      ],
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

  Widget _vDivider() => Container(
      width: 1, height: 32, color: AppColors.ink200,
      margin: const EdgeInsets.symmetric(horizontal: 12));
}

// ── Admin Stat ────────────────────────────────────────────
class _AdminStat extends StatelessWidget {
  final String label, value;
  const _AdminStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 18)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.ink600)),
        ]),
      );
}

// ── Pending Tab ───────────────────────────────────────────
class _PendingTab extends StatelessWidget {
  final CampaignProvider campaigns;
  const _PendingTab({required this.campaigns});

  @override
  Widget build(BuildContext context) {
    final pending = campaigns.pendingCampaigns;
    if (pending.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline,
        title: 'Semua beres!',
        subtitle: 'Tidak ada kampanye yang menunggu review.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) => _ReviewCard(
        campaign: pending[i],
        onApprove: () => campaigns.approveCampaign(pending[i].id),
        onReject:  () => campaigns.rejectCampaign(pending[i].id),
        onView: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                CampaignDetailScreen(campaignId: pending[i].id))),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final CampaignModel campaign;
  final VoidCallback onApprove, onReject, onView;
  const _ReviewCard({
    required this.campaign, required this.onApprove,
    required this.onReject, required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(campaign.title,
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          StatusBadge(campaign.status),
        ]),
        const SizedBox(height: 4),
        Text('oleh ${campaign.creatorName}', style: tt.bodySmall),
        const SizedBox(height: 6),
        Text(campaign.description, style: tt.bodyMedium,
            maxLines: 3, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Text('Target: ${fmtMoney(campaign.target)} • ${campaign.category.name}',
            style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReject,
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Tolak'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onApprove,
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Setujui'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 10)),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onView,
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 12)),
            child: const Icon(Icons.open_in_new, size: 16),
          ),
        ]),
      ]),
    );
  }
}

// ── All Campaigns Tab ─────────────────────────────────────
class _AllCampaignsTab extends StatelessWidget {
  final CampaignProvider campaigns;
  const _AllCampaignsTab({required this.campaigns});

  @override
  Widget build(BuildContext context) {
    final all = campaigns.allCampaigns;
    if (all.isEmpty) return const EmptyState(
        icon: Icons.campaign_outlined, title: 'Belum ada kampanye', subtitle: '');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: all.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final c = all[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.ink200),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(width: 48, height: 48,
                child: c.imageUrl.startsWith('http')
                    ? Image.network(c.imageUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: AppColors.ink100))
                    : Container(color: AppColors.ink100,
                        child: const Icon(Icons.campaign_outlined,
                            color: AppColors.ink500)),
              ),
            ),
            title: Text(c.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${fmtMoney(c.collected)} / ${fmtMoney(c.target)} • ${c.donors} donatur',
              style: const TextStyle(fontSize: 12, color: AppColors.ink600),
            ),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              StatusBadge(c.status),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    size: 18, color: AppColors.ink600),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (action) {
                  if (action == 'approve') campaigns.approveCampaign(c.id);
                  if (action == 'reject')  campaigns.rejectCampaign(c.id);
                  if (action == 'delete')  _confirmDelete(context, c, campaigns);
                },
                itemBuilder: (_) => [
                  if (c.status != CampaignStatus.active)
                    const PopupMenuItem(value: 'approve',
                        child: Row(children: [
                          Icon(Icons.check, size: 16, color: AppColors.success),
                          SizedBox(width: 8), Text('Setujui')])),
                  if (c.status != CampaignStatus.rejected)
                    const PopupMenuItem(value: 'reject',
                        child: Row(children: [
                          Icon(Icons.close, size: 16, color: AppColors.error),
                          SizedBox(width: 8), Text('Tolak')])),
                  const PopupMenuItem(value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline,
                            size: 16, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Hapus',
                            style: TextStyle(color: AppColors.error))])),
                ],
              ),
            ]),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CampaignDetailScreen(campaignId: c.id))),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, CampaignModel c,
      CampaignProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Kampanye?'),
        content: Text(
            'Kampanye "${c.title}" akan dihapus permanen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () {
              provider.deleteCampaign(c.id);
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ── Donations Tab ─────────────────────────────────────────
class _DonationsTab extends StatelessWidget {
  final List<DonationModel> donations;
  const _DonationsTab({required this.donations});

  @override
  Widget build(BuildContext context) {
    if (donations.isEmpty) return const EmptyState(
        icon: Icons.inbox_outlined, title: 'Belum ada donasi', subtitle: '');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: donations.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) => DonationTile(donation: donations[i]),
    );
  }
}
