import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:share_plus/share_plus.dart';

import '../app_info.dart';
import '../domain/reminders.dart';
import '../domain/share.dart';
import '../state/card_store.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/app_sheet.dart';
import '../widgets/confirm_destructive.dart';
import '../widgets/home_widget_help.dart';
import '../widgets/store_snack.dart';
import '../widgets/ui.dart';
import 'archive_screen.dart';
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

  /// Every record as a spreadsheet file, through the share sheet. The UTF-8
  /// byte order mark makes Excel read the Turkish letters correctly.
  Future<void> _exportCsv() async {
    final bytes = Uint8List.fromList([
      0xEF, 0xBB, 0xBF,
      ...utf8.encode(store.exportCsv()),
    ]);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'text/csv')],
        fileNameOverrides: ['kac-gun-oldu-${store.today}.csv'],
        subject: 'Kaç Gün Oldu? kayıtları',
      ),
    );
  }

  /// A card someone sent (Kart → ⋯ → Paylaş), copied from the message.
  Future<void> _importShared(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final shared = parseSharedCard(data?.text ?? '');
    if (shared == null) {
      store.toast('Panoda paylaşılan bir kart bulunamadı');
      return;
    }
    final id = store.importSharedCard(shared);
    if (id == null || !context.mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    store.openCardRequest.value = id;
  }

  void _explainSystemBackup(BuildContext context) {
    showAppSheet<void>(
      context: context,
      reduceMotion: MediaQuery.of(context).disableAnimations,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Telefonun yedeği',
            style: display(26, color: AppColor.onSurface, height: 1.14),
          ),
          const SizedBox(height: Space.s12),
          for (final line in const [
            'Android’de Google hesabına yedekleme, iPhone’da iCloud yedeği '
                'açıksa kartların ve kayıtların da otomatik olarak o yedeğe '
                'girer.',
            'Yeni telefonu kurarken bu yedekten geri yüklersen kartların '
                'kendiliğinden gelir; hatırlatmalar da yeniden kurulur.',
            'Yedeği telefonun ayarlarından açıp kapatabilirsin. Bu yedeği '
                'Google ya da Apple tutar; biz göremeyiz.',
            'Yedek günde bir kez, telefon şarjdayken ve Wi-Fi varken alınır; '
                'bugünkü son kayıtların henüz yedekte olmayabilir.',
            'Geri yükleme yalnızca uygulamayı kurarken olur; uygulama '
                'kuruluyken yedeğe dönemezsin. Mağaza dışından kurulan '
                'sürümlerde geri yükleme her telefonda çalışmayabilir.',
            'Yedeği kapatmışsan hiçbir şey yedeklenmez. Bunun yerine '
                'Ayarlar’daki “Yedeği panoya kopyala” ile verilerini elle '
                'saklayabilirsin.',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s8),
              child: Text(
                line,
                style: ui(
                  13.5,
                  color: AppColor.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ),
          const SizedBox(height: Space.s8),
          PrimaryButton(
            label: 'Tamam',
            onTap: () => Navigator.of(sheetContext).pop(),
          ),
        ],
      ),
    );
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
                          icon: Icons.archive_outlined,
                          label: 'Arşiv',
                          detail: store.archivedCards.isEmpty
                              ? 'Arşivde kart yok'
                              : '${store.archivedCards.length} kart arşivde',
                          onTap: () => pushPage<void>(
                            context,
                            (_) => ArchiveScreen(store: store),
                          ),
                        ),
                        ActionRow(
                          icon: Icons.move_to_inbox_outlined,
                          label: 'Paylaşılan kartı ekle',
                          detail: 'Sana gönderilen mesajı kopyala, sonra dokun',
                          onTap: () => _importShared(context),
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
                      title: "Ana ekran widget'ı",
                      children: [
                        if (store.canPinWidget) ...[
                          ActionRow(
                            icon: Icons.widgets_outlined,
                            label: "Kart widget'ı ekle",
                            detail: 'Tek bir kartın kaç gün olduğu',
                            onTap: () => pinHomeWidget(context, store),
                          ),
                          ActionRow(
                            icon: Icons.view_agenda_outlined,
                            label: "Kartlar widget'ı ekle",
                            detail: 'Sırası en yakın kartlar bir arada',
                            onTap: () => pinHomeWidget(context, store, list: true),
                          ),
                        ] else
                          ActionRow(
                            icon: Icons.widgets_outlined,
                            label: 'Ana ekrana widget ekle',
                            detail: 'Kartların uygulamayı açmadan görünsün',
                            onTap: () => showHomeWidgetHelp(context),
                          ),
                        ActionRow(
                          icon: Icons.check_circle_outline_rounded,
                          label: '“Bugün yaptım” düğmesi',
                          detail: "Widget'tan tek dokunuşla işaretle",
                          onTap: () => store.setWidgetDoneButton(!store.widgetDoneButton),
                          trailing: Switch(
                            value: store.widgetDoneButton,
                            onChanged: store.setWidgetDoneButton,
                            activeTrackColor: AppColor.primary,
                            activeThumbColor: AppColor.onPrimary,
                            inactiveTrackColor: AppColor.surfaceContainerHover,
                            inactiveThumbColor: AppColor.surfaceBright,
                            trackOutlineColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    _Group(
                      title: 'Yedekleme',
                      children: [
                        ActionRow(
                          icon: Icons.cloud_done_outlined,
                          label: 'Telefonun yedeği',
                          detail: 'Google ya da iCloud yedeği açıksa kartların da yedeklenir',
                          onTap: () => _explainSystemBackup(context),
                        ),
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
                        ActionRow(
                          icon: Icons.table_chart_outlined,
                          label: 'CSV olarak dışa aktar',
                          detail: 'Bütün kayıtlar, tablo programında açılır',
                          enabled: store.hasAnyCards,
                          onTap: _exportCsv,
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
                          enabled: store.hasAnyCards,
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
                      ],
                    ),
                    const SizedBox(height: Space.s12),
                    // The open source licenses (packages, and the bundled
                    // fonts' OFL) sit behind the version line, the way most
                    // apps tuck them away: required to be there, not needed
                    // in the list above.
                    Semantics(
                      button: true,
                      label: 'Açık kaynak lisansları',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: 'Kaç Gün Oldu?',
                          applicationVersion: appVersion,
                          applicationLegalese: '© 2026 EMA Labs',
                        ),
                        child: Text(
                          'Kaç gün oldu? · $appVersion',
                          textAlign: TextAlign.center,
                          style: ui(
                            12,
                            weight: FontWeight.w600,
                            color: AppColor.outline,
                          ),
                        ),
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
