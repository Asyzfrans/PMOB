// lib/screens/dashboard/create_campaign_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/campaign_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/campaign_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class CreateCampaignScreen extends StatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  State<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends State<CreateCampaignScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _targetCtrl= TextEditingController();
  CampaignCategory _category = CampaignCategory.sosial;
  DateTime? _deadline;
  File?     _imageFile;
  bool      _uploadingImage = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx)
              .colorScheme
              .copyWith(primary: AppColors.brand700),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().currentUser!;
    final ok = await context.read<CampaignProvider>().createCampaign(
      title:       _titleCtrl.text,
      description: _descCtrl.text,
      target:      double.parse(_targetCtrl.text.replaceAll('.', '')),
      category:    _category,
      creator:     user,
      imageFile:   _imageFile,
      deadline:    _deadline,
    );

    if (!mounted) return;
    if (ok) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Kampanye Dikirim!'),
          content: const Text(
            'Kampanyemu sedang direview oleh admin.\n'
            'Biasanya 1–2 hari kerja setelah pengajuan.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Oke'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            context.read<CampaignProvider>().error ?? 'Gagal membuat kampanye'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt      = Theme.of(context).textTheme;
    final loading = context.watch<CampaignProvider>().loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Kampanye'),
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
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFF92400E), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Kampanyemu akan diverifikasi admin sebelum ditampilkan ke publik.',
                        style: tt.bodySmall
                            ?.copyWith(color: const Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Gambar ──
              _Label('Foto Kampanye'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.ink50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.ink200, style: BorderStyle.solid),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(_imageFile!, fit: BoxFit.cover,
                              width: double.infinity),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate_outlined,
                                size: 40, color: AppColors.ink500),
                            const SizedBox(height: 8),
                            Text('Tap untuk pilih gambar',
                                style: tt.bodySmall),
                          ],
                        ),
                ),
              ),
              if (_imageFile != null)
                TextButton.icon(
                  onPressed: () => setState(() => _imageFile = null),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Hapus gambar'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.error),
                ),
              const SizedBox(height: 20),

              // ── Judul ──
              _Label('Judul Kampanye *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 100,
                decoration: const InputDecoration(
                  hintText: 'Mis. Beasiswa Anak Pesisir',
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Judul wajib diisi';
                  if (v.trim().length < 10) return 'Judul minimal 10 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Deskripsi ──
              _Label('Deskripsi *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText:
                      'Ceritakan tujuan kampanye, siapa yang akan dibantu, '
                      'dan bagaimana dana akan digunakan...',
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Deskripsi wajib diisi';
                  if (v.trim().length < 50)
                    return 'Deskripsi minimal 50 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Target ──
              _Label('Target Dana (Rp) *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _targetCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: '5000000',
                  prefixIcon: Icon(Icons.attach_money_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Target wajib diisi';
                  final n = double.tryParse(v);
                  if (n == null || n < 100000)
                    return 'Minimal target Rp 100.000';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Kategori ──
              _Label('Kategori *'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CampaignCategory.values.map((cat) {
                  final selected = _category == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.brand700
                            : AppColors.ink50,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: selected
                              ? AppColors.brand700
                              : AppColors.ink200,
                        ),
                      ),
                      child: Text(
                        cat.name[0].toUpperCase() + cat.name.substring(1),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.ink700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Deadline ──
              _Label('Tenggat Waktu (opsional)'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDeadline,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.ink50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.ink200),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: AppColors.ink600),
                    const SizedBox(width: 12),
                    Text(
                      _deadline == null
                          ? 'Pilih tanggal...'
                          : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
                      style: TextStyle(
                        color: _deadline == null
                            ? AppColors.ink500
                            : AppColors.ink900,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (_deadline != null)
                      GestureDetector(
                        onTap: () => setState(() => _deadline = null),
                        child: const Icon(Icons.clear,
                            size: 18, color: AppColors.ink500),
                      ),
                  ]),
                ),
              ),
              const SizedBox(height: 36),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : _submit,
                  child: loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Kirim untuk Review'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.ink900));
}
