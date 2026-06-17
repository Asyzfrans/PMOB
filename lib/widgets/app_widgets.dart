// lib/widgets/app_widgets.dart
//
// Shared / reusable widgets used across multiple screens.

import 'package:flutter/material.dart';
import '../models/campaign_model.dart';
import '../models/donation_model.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BRAND LOGO
// ─────────────────────────────────────────────────────────────────────────────

class DonateIDLogo extends StatelessWidget {
  final double size;
  final bool showText;
  const DonateIDLogo({super.key, this.size = 32, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppColors.brand700,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.volunteer_activism, color: Colors.white, size: size * 0.55),
        ),
        if (showText) ...[
          const SizedBox(width: 8),
          Text(
            'DonateID',
            style: TextStyle(
              fontSize: size * 0.55,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: AppColors.ink900,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CAMPAIGN CARD
// ─────────────────────────────────────────────────────────────────────────────

class CampaignCard extends StatelessWidget {
  final CampaignModel campaign;
  final VoidCallback? onTap;

  const CampaignCard({super.key, required this.campaign, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.ink200),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A020617),
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: campaign.imageUrl.startsWith('http')
                    ? Image.network(
                        campaign.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  _CategoryBadge(campaign.category),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    campaign.title,
                    style: tt.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Creator
                  Text(
                    'oleh ${campaign.creatorName}',
                    style: tt.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: campaign.progressPercent,
                      backgroundColor: AppColors.ink100,
                      valueColor: const AlwaysStoppedAnimation(AppColors.brand700),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fmtMoney(campaign.collected),
                            style: tt.titleMedium?.copyWith(
                              color: AppColors.brand700,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'dari ${fmtMoney(campaign.target)}',
                            style: tt.bodySmall,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${campaign.progressInt}%',
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (campaign.daysLeft != null)
                            Text(
                              '${campaign.daysLeft} hari lagi',
                              style: tt.bodySmall,
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.ink100,
        child: const Center(
          child: Icon(Icons.image_outlined, size: 48, color: AppColors.ink500),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final CampaignCategory category;
  const _CategoryBadge(this.category);

  static const _colors = {
    CampaignCategory.kesehatan:  Color(0xFFDCFCE7),
    CampaignCategory.pendidikan: Color(0xFFDBEAFE),
    CampaignCategory.bencana:    Color(0xFFFEF3C7),
    CampaignCategory.lingkungan: Color(0xFFD1FAE5),
    CampaignCategory.sosial:     Color(0xFFEDE9FE),
    CampaignCategory.lainnya:    Color(0xFFF1F5F9),
  };
  static const _textColors = {
    CampaignCategory.kesehatan:  Color(0xFF166534),
    CampaignCategory.pendidikan: Color(0xFF1E40AF),
    CampaignCategory.bencana:    Color(0xFF92400E),
    CampaignCategory.lingkungan: Color(0xFF065F46),
    CampaignCategory.sosial:     Color(0xFF5B21B6),
    CampaignCategory.lainnya:    AppColors.ink700,
  };

  @override
  Widget build(BuildContext context) {
    final bg = _colors[category] ?? AppColors.ink100;
    final fg = _textColors[category] ?? AppColors.ink700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        category.name[0].toUpperCase() + category.name.substring(1),
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CARD  (used in dashboards)
// ─────────────────────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor = AppColors.brand700,
    this.iconBg = AppColors.brand50,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration:
                BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: tt.headlineLarge
                  ?.copyWith(fontWeight: FontWeight.w800, fontSize: 22)),
          const SizedBox(height: 2),
          Text(label, style: tt.bodySmall),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DONATION TILE (list item)
// ─────────────────────────────────────────────────────────────────────────────

class DonationTile extends StatelessWidget {
  final DonationModel donation;
  const DonationTile({super.key, required this.donation});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.ink200)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.brand50,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                donation.displayName.isNotEmpty
                    ? donation.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(donation.displayName,
                    style: tt.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(donation.campaignTitle,
                    style: tt.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fmtMoney(donation.amount),
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand700,
                  )),
              Text(timeAgo(donation.date), style: tt.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brand700),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.ink100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 36, color: AppColors.ink500),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: tt.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: tt.bodyMedium, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING OVERLAY
// ─────────────────────────────────────────────────────────────────────────────

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.brand700,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BRAND BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class BrandButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;
  final IconData? icon;

  const BrandButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
              Text(label),
            ],
          );

    if (outlined) {
      return OutlinedButton(onPressed: loading ? null : onPressed, child: child);
    }
    return ElevatedButton(onPressed: loading ? null : onPressed, child: child);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BADGE
// ─────────────────────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final CampaignStatus status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      CampaignStatus.active    => ('Aktif', const Color(0xFFDCFCE7), const Color(0xFF166534)),
      CampaignStatus.pending   => ('Menunggu', const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      CampaignStatus.completed => ('Selesai', const Color(0xFFDBEAFE), const Color(0xFF1E40AF)),
      CampaignStatus.rejected  => ('Ditolak', const Color(0xFFFFE4E6), const Color(0xFF9F1239)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// USER AVATAR
// ─────────────────────────────────────────────────────────────────────────────

class UserAvatar extends StatelessWidget {
  final String initial;
  final double size;

  const UserAvatar({super.key, required this.initial, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.brand50,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
            color: AppColors.brand800,
          ),
        ),
      ),
    );
  }
}
