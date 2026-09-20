import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:share_plus/share_plus.dart';

import '../app_info.dart';
import '../domain/reminders.dart';
import '../domain/share.dart';
import '../l10n/strings.dart';
import '../l10n/strings_en.dart';
import '../l10n/strings_tr.dart';
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

  /// "Dil" — the phone's language, or one the person picks. Applied at once,
  /// which also rewrites the pending reminders and the home screen widgets.
  Future<void> _pickLanguage(BuildContext context) {
    return showAppSheet<void>(
      context: context,
      reduceMotion: MediaQuery.of(context).disableAnimations,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            S.language,
            style: display(26, color: AppColor.onSurface, height: 1.14),
          ),
          const SizedBox(height: Space.s14),
          for (final option in AppLang.values)
            ActionRow(
              icon: option == store.lang
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              label: switch (option) {
                AppLang.system => S.languageSystem,
                AppLang.tr => const TrStrings().langName,
                AppLang.en => const EnStrings().langName,
              },
              detail: option == AppLang.system
                  ? _systemLanguageName()
                  : null,
              onTap: () {
                Navigator.of(sheetContext).pop();
                store.setLang(option);
              },
            ),
        ],
      ),
    );
  }

  /// What [AppLang.system] resolves to on this phone right now.
  String _systemLanguageName() {
    final device = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return device == 'en' ? const EnStrings().langName : const TrStrings().langName;
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: store.reminderHour,
        minute: store.reminderMinute,
      ),
      helpText: S.reminderTime,
      cancelText: S.cancel,
      confirmText: S.ok,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) store.setReminderTime(picked.hour, picked.minute);
  }

  Future<void> _copyBackup() async {
    await Clipboard.setData(ClipboardData(text: store.exportJson()));
    store.toast(S.backupCopied);
  }

  Future<void> _restore(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      store.toast(S.noBackupOnClipboard);
      return;
    }
    if (!context.mounted) return;
    final ok = await confirmDestructive(
      context,
      title: S.restoreTitle,
      message: S.restoreMessage,
      confirmLabel: S.restore,
      cancelLabel: S.cancel,
    );
    if (!ok) return;
    if (store.importJson(text) == null) {
      store.toast(S.notAValidBackup);
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
        subject: S.csvSubject,
      ),
    );
  }

  /// A card someone sent (Kart → ⋯ → Paylaş), copied from the message.
  Future<void> _importShared(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final shared = parseSharedCard(data?.text ?? '');
    if (shared == null) {
      store.toast(S.noSharedCardOnClipboard);
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
            S.systemBackup,
            style: display(26, color: AppColor.onSurface, height: 1.14),
          ),
          const SizedBox(height: Space.s12),
          for (final line in S.systemBackupExplainer)
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
            label: S.ok,
            onTap: () => Navigator.of(sheetContext).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAll(BuildContext context) async {
    final ok = await confirmDestructive(
      context,
      title: S.deleteAllTitle,
      message: S.deleteAllMessage,
      confirmLabel: S.deleteAll,
      cancelLabel: S.cancel,
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
              PageHeader(title: S.settingsTitle),
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
                      title: S.groupAppearance,
                      children: [
                        ActionRow(
                          icon: Icons.language_rounded,
                          label: S.language,
                          detail: store.lang == AppLang.system
                              ? '${S.languageSystem} · ${S.langName}'
                              : S.langName,
                          onTap: () => _pickLanguage(context),
                        ),
                        ActionRow(
                          icon: Icons.color_lens_outlined,
                          label: S.theme,
                          detail: S.themeName(AppColor.current.id),
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
                      title: S.groupProfile,
                      children: [
                        ActionRow(
                          icon: Icons.person_outline_rounded,
                          label: S.editProfile,
                          detail: store.profile.isEmpty
                              ? S.addYourName
                              : store.profile.name,
                          onTap: () => editProfile(context, store),
                        ),
                      ],
                    ),
                    _Group(
                      title: S.groupCards,
                      children: [
                        ActionRow(
                          icon: Icons.palette_outlined,
                          label: S.statusColours,
                          detail: S.statusColoursDetail,
                          onTap: () => pushPage<void>(
                            context,
                            (_) => const LegendScreen(),
                          ),
                        ),
                        ActionRow(
                          icon: Icons.sort_rounded,
                          label: S.resetOrder,
                          detail: store.hasManualOrder
                              ? S.resetOrderDetail
                              : S.resetOrderNoop,
                          enabled: store.hasManualOrder,
                          onTap: store.resetOrder,
                        ),
                        ActionRow(
                          icon: Icons.archive_outlined,
                          label: S.archive,
                          detail: store.archivedCards.isEmpty
                              ? S.archiveEmptyDetail
                              : S.archiveCount(store.archivedCards.length),
                          onTap: () => pushPage<void>(
                            context,
                            (_) => ArchiveScreen(store: store),
                          ),
                        ),
                        ActionRow(
                          icon: Icons.move_to_inbox_outlined,
                          label: S.importShared,
                          detail: S.importSharedDetail,
                          onTap: () => _importShared(context),
                        ),
                        ActionRow(
                          icon: Icons.library_add_outlined,
                          label: S.loadSamples,
                          detail: S.loadSamplesDetail,
                          onTap: () {
                            if (store.loadSamples() == 0) {
                              store.toast(S.samplesAlreadyThere);
                            }
                          },
                        ),
                      ],
                    ),
                    _Group(
                      title: S.groupNotifications,
                      children: [
                        ActionRow(
                          icon: Icons.schedule_rounded,
                          label: S.reminderTime,
                          detail: store.reminderCount == 0
                              ? S.reminderTimeNoneDetail
                              : S.reminderTimeCount(store.reminderCount),
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
                          label: S.sendTestNotification,
                          detail: S.sendTestNotificationDetail,
                          onTap: store.sendTestReminder,
                        ),
                      ],
                    ),
                    _Group(
                      title: S.groupHomeWidget,
                      children: [
                        if (store.canPinWidget) ...[
                          ActionRow(
                            icon: Icons.widgets_outlined,
                            label: S.addCardWidget,
                            detail: S.addCardWidgetDetail,
                            onTap: () => pinHomeWidget(context, store),
                          ),
                          ActionRow(
                            icon: Icons.view_agenda_outlined,
                            label: S.addListWidget,
                            detail: S.addListWidgetDetail,
                            onTap: () => pinHomeWidget(context, store, list: true),
                          ),
                        ] else
                          ActionRow(
                            icon: Icons.widgets_outlined,
                            label: S.addHomeWidget,
                            detail: S.addHomeWidgetDetail,
                            onTap: () => showHomeWidgetHelp(context),
                          ),
                        ActionRow(
                          icon: Icons.check_circle_outline_rounded,
                          label: S.doneButtonSetting,
                          detail: S.doneButtonSettingDetail,
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
                      title: S.groupBackup,
                      children: [
                        ActionRow(
                          icon: Icons.cloud_done_outlined,
                          label: S.systemBackup,
                          detail: S.systemBackupDetail,
                          onTap: () => _explainSystemBackup(context),
                        ),
                        ActionRow(
                          icon: Icons.copy_rounded,
                          label: S.copyBackup,
                          detail: S.copyBackupDetail,
                          onTap: _copyBackup,
                        ),
                        ActionRow(
                          icon: Icons.content_paste_rounded,
                          label: S.restoreBackup,
                          detail: S.restoreBackupDetail,
                          onTap: () => _restore(context),
                        ),
                        ActionRow(
                          icon: Icons.table_chart_outlined,
                          label: S.exportCsv,
                          detail: S.exportCsvDetail,
                          enabled: store.hasAnyCards,
                          onTap: _exportCsv,
                        ),
                      ],
                    ),
                    _Group(
                      title: S.groupDanger,
                      children: [
                        ActionRow(
                          icon: Icons.delete_forever_outlined,
                          label: S.deleteAllCards,
                          detail: S.notUndoable,
                          destructive: true,
                          enabled: store.hasAnyCards,
                          onTap: () => _clearAll(context),
                        ),
                      ],
                    ),
                    _Group(
                      title: S.groupAbout,
                      children: [
                        ActionRow(
                          icon: Icons.privacy_tip_outlined,
                          label: S.privacyPolicyRow,
                          detail: S.privacyPolicyRowDetail,
                          onTap: () => openPrivacy(context),
                        ),
                        ActionRow(
                          icon: Icons.description_outlined,
                          label: S.termsRow,
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
                      label: S.openSourceLicenses,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: S.appName,
                          applicationVersion: appVersion,
                          applicationLegalese: '© 2026 EMA Labs',
                        ),
                        child: Text(
                          S.versionLine(appVersion),
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
                      S.dataStaysHere,
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
