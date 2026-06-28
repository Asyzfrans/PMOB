// lib/screens/donation/donation_screen.dart
// Diupdate: campaignId int, donorUid dihapus (backend ambil dari token)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/campaign_model.dart';
import '../../models/donation_model.dart';
import '../../providers/donation_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_widgets.dart';

class DonationScreen extends StatefulWidget {
  final CampaignModel campaign;
  final VoidCallback? onDonated;
  const DonationScreen({super.key, required this.campaign, this.onDonated});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _amountCtrl  = TextEditingController();
  final _messageCtrl = TextEditingController();
  PaymentMethod _method = PaymentMethod.transfer;
  bool _anon = false;
  double? _selectedPreset;

  static const _presets = [10000, 25000, 50000, 100000, 250000, 500000];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _selectPreset(int amount) {
    setState(() {
      _selectedPreset = amount.toDouble();
      _amountCtrl.text = amount.toString();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount < 1000) {
      _showSnack('Nominal minimal Rp 1.000', error: true);
      return;
    }

    final donation = await context.read<DonationProvider>().donate(
      campaignId: widget.campaign.id,
      amount:     amount,
      method:     _method,
      anon:       _anon,
      message:    _messageCtrl.text.trim(),
    );

    if (!mounted) return;
    if (donation != null) {
      widget.onDonated?.call();
      _showSuccessSheet(donation);
    } else {
      final err = context.read<DonationProvider>().error;
      _showSnack(err ?? 'Donasi gagal, coba lagi.', error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccessSheet(DonationModel donation) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      // FIX: isScrollControlled=true supaya bottom sheet bisa
      // menyesuaikan tinggi konten dan tidak terpotong di layar kecil
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _SuccessSheet(
        donation: donation,
        onDone: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt      = Theme.of(context).textTheme;
    final loading = context.watch<DonationProvider>().loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donasi'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.ink200),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CampaignMini(campaign: widget.campaign),
              const SizedBox(height: 24),

              Text('Pilih Nominal', style: tt.headlineSmall),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.6,
                children: _presets.map((p) => _PresetChip(
                  amount: p,
                  selected: _selectedPreset == p.toDouble(),
                  onTap: () => _selectPreset(p),
                )).toList(),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Nominal lainnya (Rp)',
                  prefixIcon: Icon(Icons.attach_money_outlined),
                ),
                onChanged: (_) => setState(() => _selectedPreset = null),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Nominal wajib diisi';
                  final n = double.tryParse(v);
                  if (n == null || n < 1000) return 'Minimal Rp 1.000';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              Text('Metode Pembayaran', style: tt.headlineSmall),
              const SizedBox(height: 12),
              ...PaymentMethod.values.map((m) => _MethodTile(
                method: m,
                selected: _method == m,
                onTap: () => setState(() => _method = m),
              )),
              const SizedBox(height: 20),

              TextFormField(
                controller: _messageCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Pesan dukungan (opsional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.ink50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Donasi Anonim',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        SizedBox(height: 2),
                        Text('Nama Anda tidak akan ditampilkan',
                            style: TextStyle(fontSize: 12, color: AppColors.ink600)),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _anon,
                    onChanged: (v) => setState(() => _anon = v),
                    activeColor: AppColors.brand700,
                  ),
                ]),
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : _submit,
                  child: loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.favorite, size: 18),
                            const SizedBox(width: 8),
                            Text(_amountCtrl.text.isNotEmpty
                                ? 'Donasi ${fmtMoney(double.tryParse(_amountCtrl.text) ?? 0)}'
                                : 'Donasi Sekarang'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widget helpers ────────────────────────────────────────

class _CampaignMini extends StatelessWidget {
  final CampaignModel campaign;
  const _CampaignMini({required this.campaign});
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.ink50, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink200),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(width: 60, height: 60,
            child: campaign.imageUrl.isNotEmpty
                ? Image.network(campaign.imageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppColors.ink200))
                : Container(color: AppColors.ink200),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(campaign.title,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('${campaign.progressInt}% • ${fmtMoney(campaign.collected)} terkumpul',
                style: tt.bodySmall?.copyWith(color: AppColors.brand700)),
          ]),
        ),
      ]),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final int amount; final bool selected; final VoidCallback onTap;
  const _PresetChip({required this.amount, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.brand700 : AppColors.ink50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? AppColors.brand700 : AppColors.ink200),
      ),
      child: Text(fmtMoney(amount.toDouble()),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.ink700)),
    ),
  );
}

class _MethodTile extends StatelessWidget {
  final PaymentMethod method; final bool selected; final VoidCallback onTap;
  const _MethodTile({required this.method, required this.selected, required this.onTap});

  static const _labels = {
    PaymentMethod.transfer:    'Transfer Bank',
    PaymentMethod.qris:        'QRIS',
    PaymentMethod.ewallet:     'E-Wallet (OVO, GoPay, DANA)',
    PaymentMethod.kartuKredit: 'Kartu Kredit / Debit',
  };
  static const _icons = {
    PaymentMethod.transfer:    Icons.account_balance_outlined,
    PaymentMethod.qris:        Icons.qr_code_outlined,
    PaymentMethod.ewallet:     Icons.wallet_outlined,
    PaymentMethod.kartuKredit: Icons.credit_card_outlined,
  };

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? AppColors.brand50 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: selected ? AppColors.brand700 : AppColors.ink200,
            width: selected ? 1.5 : 1),
      ),
      child: Row(children: [
        Icon(_icons[method]!,
            color: selected ? AppColors.brand700 : AppColors.ink600, size: 22),
        const SizedBox(width: 12),
        Text(_labels[method]!,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                color: selected ? AppColors.brand700 : AppColors.ink900)),
        const Spacer(),
        if (selected)
          const Icon(Icons.check_circle, color: AppColors.brand700, size: 20),
      ]),
    ),
  );
}

// FIX OVERFLOW: Bungkus seluruh konten dengan SingleChildScrollView
// supaya konten bisa di-scroll kalau layar HP terlalu kecil.
// isScrollControlled=true di showModalBottomSheet mengizinkan
// bottom sheet mengambil tinggi lebih dari 50% layar.
class _SuccessSheet extends StatelessWidget {
  final DonationModel donation;
  final VoidCallback onDone;
  const _SuccessSheet({required this.donation, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            24, 28, 24, 24 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.ink200,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.check, color: AppColors.success, size: 36),
            ),
            const SizedBox(height: 20),
            Text('Donasi Berhasil!', style: tt.headlineLarge),
            const SizedBox(height: 8),
            Text('Terima kasih atas kepedulianmu 💙',
                style: tt.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.ink50,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                _Row('ID Transaksi', donation.transactionId),
                _Row('Kampanye', donation.campaignTitle),
                _Row('Nominal', fmtMoney(donation.amount)),
                _Row('Metode', donation.method.name.toUpperCase()),
                _Row('Tanggal', fmtDate(donation.date)),
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                  onPressed: onDone, child: const Text('Selesai')),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.ink600)),
      const Spacer(),
      Flexible(
        child: Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis),
      ),
    ]),
  );
}
