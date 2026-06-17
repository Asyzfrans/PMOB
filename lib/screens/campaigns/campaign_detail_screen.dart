// lib/screens/campaigns/campaign_detail_screen.dart
// ID diubah dari String ke int (sesuai MySQL primary key)

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
import '../auth/login_screen.dart';
import '../donation/donation_screen.dart';

class CampaignDetailScreen extends StatefulWidget {
  final int campaignId;
  const CampaignDetailScreen({super.key, required this.campaignId});

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  List<DonationModel> _donations = [];
  bool _loadingDonations = false;

  @override
  void initState() {
    super.initState();
    _fetchDonations();
  }

  Future<void> _fetchDonations() async {
    setState(() => _loadingDonations = true);
    final list = await context
        .read<DonationProvider>()
        .getDonationsByCampaign(widget.campaignId);
    if (mounted) setState(() { _donations = list; _loadingDonations = false; });
  }

  @override
  Widget build(BuildContext context) {
    final campaign = context.watch<CampaignProvider>().getById(widget.campaignId);
    if (campaign == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Kampanye tidak ditemukan')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Image header
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.ink900),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: campaign.imageUrl.isNotEmpty
                  ? Image.network(campaign.imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _CategoryBadge(campaign.category),
                    const SizedBox(width: 8),
                    StatusBadge(campaign.status),
                  ]),
                  const SizedBox(height: 12),
                  Text(campaign.title,
                      style: Theme.of(context).textTheme.displaySmall
                          ?.copyWith(fontSize: 24)),
                  const SizedBox(height: 8),
                  Row(children: [
                    UserAvatar(initial: campaign.creatorName[0], size: 28),
                    const SizedBox(width: 8),
                    Text('oleh ${campaign.creatorName}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ]),
                  const SizedBox(height: 20),
                  _ProgressBox(campaign: campaign),
                  const SizedBox(height: 24),
                  Text('Tentang Kampanye',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(campaign.description,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(height: 1.7)),
                  const SizedBox(height: 24),

                  // Donors
                  if (_loadingDonations)
                    const Center(child: CircularProgressIndicator(
                        color: AppColors.brand700, strokeWidth: 2))
                  else if (_donations.isNotEmpty) ...[
                    SectionHeader(title: 'Donatur (${_donations.length})'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.ink200),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          children: _donations.take(10)
                              .map((d) => DonationTile(donation: d))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: campaign.isActive
          ? _DonateCTA(campaign: campaign, onDonated: () {
              _fetchDonations();
              context.read<CampaignProvider>().refreshCampaign(campaign.id);
            })
          : null,
    );
  }

  Widget _placeholder() => Container(
    color: AppColors.ink100,
    child: const Center(
        child: Icon(Icons.campaign_outlined,
            size: 64, color: AppColors.ink500)),
  );
}

class _CategoryBadge extends StatelessWidget {
  final CampaignCategory category;
  const _CategoryBadge(this.category);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: AppColors.brand50, borderRadius: BorderRadius.circular(100)),
    child: Text(
      category.name[0].toUpperCase() + category.name.substring(1),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          color: AppColors.brand700),
    ),
  );
}

class _ProgressBox extends StatelessWidget {
  final CampaignModel campaign;
  const _ProgressBox({required this.campaign});
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.ink50, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(fmtMoney(campaign.collected),
                style: tt.headlineLarge?.copyWith(
                    color: AppColors.brand700, fontWeight: FontWeight.w800)),
            Text('dari ${fmtMoney(campaign.target)}', style: tt.bodySmall),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${campaign.progressInt}%',
                style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text('terkumpul', style: tt.bodySmall),
          ]),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: campaign.progressPercent / 100,
            backgroundColor: AppColors.ink200,
            valueColor: const AlwaysStoppedAnimation(AppColors.brand700),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Icon(Icons.people_outline, size: 16, color: AppColors.ink600),
            const SizedBox(width: 4),
            Text('${campaign.donors} donatur', style: tt.bodySmall),
          ]),
          if (campaign.daysLeft != null)
            Row(children: [
              const Icon(Icons.schedule_outlined, size: 16, color: AppColors.ink600),
              const SizedBox(width: 4),
              Text('${campaign.daysLeft} hari lagi', style: tt.bodySmall),
            ]),
        ]),
      ]),
    );
  }
}

class _DonateCTA extends StatelessWidget {
  final CampaignModel campaign;
  final VoidCallback onDonated;
  const _DonateCTA({required this.campaign, required this.onDonated});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.ink200)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sisa target',
                  style: TextStyle(fontSize: 11, color: AppColors.ink600)),
              Text(fmtMoney(campaign.target - campaign.collected),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              if (!context.read<AuthProvider>().isAuthenticated) {
                Navigator.of(context).push(LoginScreen.route());
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DonationScreen(
                    campaign: campaign,
                    onDonated: onDonated,
                  ),
                ),
              );
            },
            child: const Text('Donasi Sekarang'),
          ),
        ),
      ]),
    );
  }
}
