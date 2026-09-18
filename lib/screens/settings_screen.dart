import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../app_info.dart';
import '../domain/reminders.dart';
import '../state/card_store.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/confirm_destructive.dart';
import '../widgets/store_snack.dart';
import '../widgets/ui.dart';
import 'legal_screen.dart';
import 'legend_screen.dart';
import 'profile_screen.dart' show editProfile;
import 'theme_screen.dart';

/// "Ayarlar" — profile, ordering, backup and the destructive reset.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.store});

  final CardStore store;

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: store.reminderHour,
        minute: store.reminderMinute,
      ),
      helpText: 'Hatırlatma saati',
      cancelText: 'Vazgeç',
      confirmText: 'Tamam',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) store.setReminderTime(picked.hour, picked.minute);
  }

  Future<void> _copyBackup() async {
    await Clipboard.setData(ClipboardData(text: store.exportJson()));
    store.toast('Yedek panoya kopyalandı');
  }

  Future<void> _restore(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      store.toast('Panoda yedek bulunamadı');
      return;
    }
    if (!context.mounted) return;
    final ok = await confirmDestructive(
      context,
      title: 'Yedek geri yüklensin mi?',
      message:
          'Şu anki bütün kartların, panodaki yedekle değiştirilecek. Bu işlem geri alınamaz.',
      confirmLabel: 'Geri yükle',
      cancelLabel: 'Vazgeç',
    );
    if (!ok) return;
    if (store.importJson(text) == null) {
      store.toast('Panodaki metin geçerli bir yedek değil');
    }
  }

  Future<void> _clearAll(BuildContext context) async {
    final ok = await confirmDestructive(
      context,
      title: 'Bütün kartlar silinsin mi?',
      message:
          'Bütün kartlar ve kayıtları kalıcı olarak silinir. Bu işlem geri alınamaz.',
      confirmLabel: 'Hepsini sil',
      cancelLabel: 'Vazgeç',
    );
    if (!ok) return;
    store.clearAll();
    if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Stack(
      children: [
        ListenableBuilder(
          listenable: store,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(title: 'Ayarlar'),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    Space.s18,
                    Space.s8,
                    Space.s18,
                    media.padding.bottom + 96,
                  ),
                  children: [
                    _Group(
                      title: 'Görünüm',
                      children: [
                        ActionRow(
                          icon: Icons.color_lens_outlined,
                          label: 'Tema',
                          detail: AppColor.current.name,
                          onTap: () => pushPage<void>(context, (_) => ThemeScreen(store: store)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final c in [AppColor.primary, AppColor.primaryContainer, AppColor.tertiary])
                                Container(
                                  width: 14,
                                  height: 14,
                                  margin: const EdgeInsets.only(left: 4),
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColor.outlineVariant),
                                  ),
                                ),
                              const SizedBox(width: Space.xs),
                              Icon(Icons.chevron_right_rounded, color: AppColor.outline),
                            ],
                          ),
                        ),
                      ],
                    ),
                    _Group(
                      title: 'Profil',
                      children: [
                        ActionRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Profili düzenle',
                          detail: store.profile.isEmpty
                              ? 'Adını ekle'
                              : store.profile.name,
                          onTap: () => editProfile(context, store),
                        ),
                      ],
                    ),
                    _Group(
                      title: 'Kartlar',
                      children: [
                        ActionRow(
                          icon: Icons.palette_outlined,
                          label: 'Durum renkleri',
                          detail: 'Kartın rengi ne anlatıyor?',
                          onTap: () => pushPage<void>(
                            context,
                            (_) => const LegendScreen(),
                          ),
                        ),
                        ActionRow(
                          icon: Icons.sort_rounded,
                          label: 'Sıralamayı sıfırla',
                          detail: store.hasManualOrder
                              ? 'Sürükleyerek verdiğin sıra unutulur, kartlar aciliyete göre dizilir'
                              : 'Kartlar zaten aciliyete göre sıralı',
                          enabled: store.hasManualOrder,
                          onTap: store.resetOrder,
                        ),
                        ActionRow(
                          icon: Icons.library_add_outlined,
                          label: 'Örnek kartları ekle',
                          detail: 'Uygulamayı denemek için hazır kartlar',
                          onTap: () {
                            if (store.loadSamples() == 0) {
                              store.toast('Örnek kartların hepsi zaten ekli');
                            }
                          },
                        ),
                      ],
                    ),
                    _Group(
                      title: 'Bildirimler',
                      children: [
                        ActionRow(
                          icon: Icons.schedule_rounded,
                          label: 'Hatırlatma saati',
                          detail: store.reminderCount == 0
                              ? 'Kart eklerken “Bana hatırlat”ı aç'
                              : '${store.reminderCount} kart için hatırlatma açık',
                          onTap: () => _pickTime(context),
                          trailing: Text(
                            timeLabel(store.reminderHour, store.reminderMinute),
                            style: ui(
                              15,
                              weight: FontWeight.w700,
                              color: AppColor.primary,
                            ),
                          ),
                        ),
                        ActionRow(
                          icon: Icons.notifications_active_outlined,
                          label: 'Test bildirimi gönder',
                          detail: 'Bildirimin nasıl görüneceğini gör',
                          onTap: store.sendTestReminder,
                        ),
                      ],
                    ),
                    _Group(
                      title: 'Yedekleme',
                      children: [
                        ActionRow(
                          icon: Icons.copy_rounded,
                          label: 'Yedeği panoya kopyala',
                          detail:
                              'Notlarına ya da kendine mesaj olarak yapıştır',
                          onTap: _copyBackup,
                        ),
                        ActionRow(
                          icon: Icons.content_paste_rounded,
                          label: 'Panodaki yedeği geri yükle',
                          detail: 'Kopyaladığın yedeği bu cihaza aktar',
                          onTap: () => _restore(context),
                        ),
                      ],
                    ),
                    _Group(
                      title: 'Tehlikeli bölge',
                      children: [
                        ActionRow(
                          icon: Icons.delete_forever_outlined,
                          label: 'Bütün kartları sil',
                          detail: 'Geri alınamaz',
                          destructive: true,
                          enabled: store.cards.isNotEmpty,
                          onTap: () => _clearAll(context),
                        ),
                      ],
                    ),
                    _Group(
                      title: 'Hakkında',
                      children: [
                        ActionRow(
                          icon: Icons.privacy_tip_outlined,
                          label: 'Gizlilik politikası',
                          detail: 'Hiçbir veri toplanmaz',
                          onTap: () => openPrivacy(context),
                        ),
                        ActionRow(
                          icon: Icons.description_outlined,
                          label: 'Kullanım koşulları',
                          onTap: () => openTerms(context),
                        ),
                        ActionRow(
                          icon: Icons.article_outlined,
                          label: 'Açık kaynak lisansları',
                          onTap: () => showLicensePage(
                            context: context,
                            applicationName: 'Kaç Gün Oldu?',
                            applicationVersion: appVersion,
                            applicationLegalese: '© 2026 EMA Labs',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.s12),
                    Text(
                      'Kaç gün oldu? · $appVersion',
                      textAlign: TextAlign.center,
                      style: ui(
                        12,
                        weight: FontWeight.w600,
                        color: AppColor.outline,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Bütün verin yalnızca bu cihazda durur.',
                      textAlign: TextAlign.center,
                      style: ui(12, color: AppColor.outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        StoreSnackLayer(store: store, bottom: media.padding.bottom + Space.s16),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: Space.xs, bottom: Space.s8),
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: ui(
                  13,
                  weight: FontWeight.w700,
                  color: AppColor.onSurfaceMuted,
                ),
              ),
            ),
          ),
          Panel(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.s14,
              vertical: Space.s6,
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}
