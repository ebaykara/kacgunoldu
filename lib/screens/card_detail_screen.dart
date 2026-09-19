import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:share_plus/share_plus.dart';

import '../domain/card.dart';
import '../domain/date.dart';
import '../domain/frequency.dart';
import '../domain/logic.dart';
import '../domain/share.dart';
import '../domain/text.dart';
import '../state/card_store.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/app_sheet.dart';
import '../widgets/card_glyph.dart';
import '../widgets/confirm_destructive.dart';
import '../widgets/day_count.dart';
import '../widgets/gap_chart.dart';
import '../widgets/halo.dart';
import '../widgets/home_widget_help.dart';
import '../widgets/note_sheet.dart';
import '../widgets/record_sheet.dart';
import '../widgets/rhythm_ring.dart';
import '../widgets/store_snack.dart';
import '../widgets/ui.dart';
import 'card_form_screen.dart';

/// History rows shown before "Tümünü göster".
const _historyPreview = 6;

/// "Kart detayı" — how long it has been, the rhythm, and every record.
///
/// "Bugün yaptım" records in place: the number counts down, the ring
/// refills and the halo plays, with the undo snackbar right here.
class CardDetailScreen extends StatefulWidget {
  const CardDetailScreen({
    super.key,
    required this.store,
    required this.cardId,
  });

  final CardStore store;
  final String cardId;

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  bool _showAll = false;

  CardStore get _store => widget.store;
  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;

  void _recordToday() {
    _store.record(widget.cardId, 0);
    if (!_reduceMotion) HapticFeedback.mediumImpact();
  }

  Future<void> _pickDay() async {
    await showAppSheet<void>(
      context: context,
      reduceMotion: _reduceMotion,
      builder: (sheetContext) => ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final card = _store.byId(widget.cardId);
          if (card == null) return const SizedBox.shrink();
          return RecordSheet(
            card: decorate(card, _store.today),
            today: _store.today,
            onPick: (offset) {
              Navigator.of(sheetContext).pop();
              _store.record(widget.cardId, offset);
              if (!_reduceMotion) HapticFeedback.lightImpact();
            },
          );
        },
      ),
    );
  }

  Future<void> _openMenu(Card card) async {
    await showAppSheet<void>(
      context: context,
      reduceMotion: _reduceMotion,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            card.name,
            style: display(24, color: AppColor.onSurface, height: 1.14),
          ),
          const SizedBox(height: Space.s14),
          // Eight rows outgrow a small phone (more so with large text): the
          // rows scroll, the title and grabber still drag the sheet away.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.62,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ActionRow(
                    icon: card.notify
                        ? Icons.notifications_off_outlined
                        : Icons.notifications_active_outlined,
                    label: card.notify ? 'Hatırlatmayı kapat' : 'Bana hatırlat',
                    detail: card.notify
                        ? 'Bu kart için bildirim gelmiyor olacak'
                        : 'Sırası gelince bildirim gönder',
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      final on = !card.notify;
                      if (await _store.setCardNotify(card.id, on) && on) {
                        _store.toast('Hatırlatma açıldı');
                      }
                    },
                  ),
                  ActionRow(
                    icon: Icons.edit_outlined,
                    label: 'Düzenle',
                    detail: 'Ad, simge ve sıklık',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      pushPage<void>(
                        context,
                        (_) =>
                            CardFormScreen(store: _store, editCardId: card.id),
                      );
                    },
                  ),
                  ActionRow(
                    icon: Icons.event_available_outlined,
                    label: 'Başka bir gün ekle',
                    detail: 'Geçmişe kayıt ekle',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _pickDay();
                    },
                  ),
                  ActionRow(
                    icon: Icons.widgets_outlined,
                    label: 'Ana ekrana ekle',
                    detail: 'Bu kartı widget olarak göster',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      if (_store.canPinWidget) {
                        pinHomeWidget(context, _store, card: card);
                      } else {
                        showHomeWidgetHelp(context, card: card);
                      }
                    },
                  ),
                  ActionRow(
                    icon: Icons.ios_share_rounded,
                    label: 'Paylaş',
                    detail: 'Kartın bir kopyasını birine gönder',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      SharePlus.instance.share(
                        ShareParams(
                          text: shareMessage(card),
                          subject: card.name,
                        ),
                      );
                    },
                  ),
                  ActionRow(
                    icon: card.archived
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined,
                    label: card.archived ? 'Arşivden çıkar' : 'Arşivle',
                    detail: card.archived
                        ? 'Kartlarının arasına geri döner'
                        : 'Kayıtlar kalır; listeden kalkar, hatırlatılmaz',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _store.setArchived(card.id, !card.archived);
                      if (!card.archived) Navigator.of(context).maybePop();
                    },
                  ),
                  ActionRow(
                    icon: Icons.delete_outline_rounded,
                    label: 'Kartı sil',
                    detail: 'Bütün kayıtlarıyla birlikte',
                    destructive: true,
                    onTap: () => _confirmDelete(sheetContext, card),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Deleting takes every record on the card with it and cannot be undone,
  /// so it always goes through a confirmation first.
  Future<void> _confirmDelete(BuildContext sheetContext, Card card) async {
    if (!_reduceMotion) HapticFeedback.mediumImpact();
    final confirmed = await confirmDestructive(
      sheetContext,
      title: '“${card.name}” silinsin mi?',
      message:
          'Bu kartın bütün kayıtları kalıcı olarak silinir. Bu işlem geri alınamaz.',
      confirmLabel: 'Sil',
      cancelLabel: 'Vazgeç',
    );
    if (!confirmed) return;
    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
    if (mounted) Navigator.of(context).pop();
    _store.deleteCard(card.id);
  }

  Future<void> _openRecord(Card card, DateKey key) async {
    final today = _store.today;
    await showAppSheet<void>(
      context: context,
      reduceMotion: _reduceMotion,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(upperTr('Kayıt'), style: overline(color: AppColor.outline)),
          const SizedBox(height: Space.s6),
          Text(
            formatFullDate(key),
            style: display(26, color: AppColor.onSurface, height: 1.14),
          ),
          const SizedBox(height: 3),
          Text(
            relativeLabel(daysSince(key, today)),
            style: ui(12.5, color: AppColor.onSurfaceVariant),
          ),
          if (card.notes[key] != null) ...[
            const SizedBox(height: Space.s12),
            Panel(
              color: AppColor.surfaceContainer,
              child: Text(
                card.notes[key]!,
                style: ui(14, color: AppColor.onSurface, height: 1.4),
              ),
            ),
          ],
          const SizedBox(height: Space.s14),
          ActionRow(
            icon: Icons.sticky_note_2_outlined,
            label: card.notes[key] == null ? 'Not ekle' : 'Notu düzenle',
            detail: 'Örn. kilometre, ne yapıldığı',
            onTap: () {
              Navigator.of(sheetContext).pop();
              _editNote(card, key);
            },
          ),
          ActionRow(
            icon: Icons.edit_calendar_outlined,
            label: 'Tarihi değiştir',
            detail: 'Bu kaydı başka bir güne taşı',
            onTap: () async {
              final picked = await showDatePicker(
                context: sheetContext,
                initialDate: fromDateKey(key),
                firstDate: DateTime(fromDateKey(today).year - 30),
                lastDate: fromDateKey(today),
                helpText: 'Yeni tarih',
                cancelText: 'Vazgeç',
                confirmText: 'Taşı',
              );
              if (picked == null) return;
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              _store.moveRecord(card.id, key, toDateKey(picked));
            },
          ),
          ActionRow(
            icon: Icons.delete_outline_rounded,
            label: 'Bu kaydı sil',
            detail: 'Geri alabilirsin',
            destructive: true,
            onTap: () {
              Navigator.of(sheetContext).pop();
              _store.removeRecord(card.id, key);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _editNote(Card card, DateKey key) async {
    await showAppSheet<void>(
      context: context,
      reduceMotion: _reduceMotion,
      builder: (sheetContext) => NoteSheet(
        dateLabel: formatFullDate(key),
        initial: card.notes[key] ?? '',
        onSave: (text) {
          Navigator.of(sheetContext).pop();
          _store.setNote(card.id, key, text);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Stack(
      children: [
        ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final card = _store.byId(widget.cardId);
            if (card == null) return const SizedBox.shrink();
            return _body(card, media);
          },
        ),
        StoreSnackLayer(
          store: _store,
          bottom: media.padding.bottom + Space.s16,
        ),
      ],
    );
  }

  Widget _body(Card card, MediaQueryData media) {
    final today = _store.today;
    final decorated = decorate(card, today);
    final stats = decorated.stats;
    final palette = tiers[stats.tier]!;
    final badge = badgeColors(stats.tier);
    final hasRecs = card.recs.isNotEmpty;
    final doneToday = hasRecs && stats.days == 0;
    final avg = averageGap(card, today);
    final pulse = _store.recordPulse;
    final nonce = pulse?.id == card.id ? pulse?.nonce : null;
    final reduceMotion = media.disableAnimations;

    final gaps = recordGaps(card);
    final history = _showAll
        ? card.recs
        : card.recs.take(_historyPreview).toList();

    // Late cards carry the solid terracotta on the ring; everything else
    // uses the tier ring over a light track.
    final ringColor = stats.tier == Tier.late ? AppColor.primary : palette.ring;
    final ringTrack = stats.tier == Tier.late
        ? AppColor.primaryContainer
        : palette.track;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: media.padding.bottom + 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: media.padding.top + Space.xs,
              left: Space.xs,
              right: Space.xs,
            ),
            child: Row(
              children: [
                RoundIconButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Geri',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const Spacer(),
                RoundIconButton(
                  icon: Icons.more_horiz_rounded,
                  label: 'Kart seçenekleri',
                  onTap: () => _openMenu(card),
                ),
              ],
            ),
          ),
          Center(
            child: GlyphBadge(
              iconKey: iconKeyOf(card),
              bg: badge.bg,
              fg: badge.fg,
              size: 64,
            ),
          ),
          const SizedBox(height: Space.s14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s20),
            child: Semantics(
              header: true,
              child: Text(
                card.name,
                textAlign: TextAlign.center,
                style: display(
                  30,
                  color: AppColor.onSurface,
                  height: 1.1,
                  letterSpacing: 30 * -0.01,
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.s6),
          Text(
            stats.meta,
            textAlign: TextAlign.center,
            style: ui(
              13,
              weight: FontWeight.w500,
              color: AppColor.onSurfaceVariant,
            ),
          ),
          if (card.archived)
            Padding(
              padding: const EdgeInsets.only(
                top: Space.s14,
                left: Space.s18,
                right: Space.s18,
              ),
              child: Panel(
                color: AppColor.surfaceContainer,
                padding: const EdgeInsets.only(
                  left: Space.s16,
                  right: Space.xs,
                  top: Space.xs,
                  bottom: Space.xs,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.archive_outlined,
                      size: 18,
                      color: AppColor.onSurfaceMuted,
                    ),
                    const SizedBox(width: Space.s8),
                    Expanded(
                      child: Text(
                        'Bu kart arşivde',
                        style: ui(
                          13,
                          weight: FontWeight.w600,
                          color: AppColor.onSurfaceMuted,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _store.setArchived(card.id, false),
                      child: Text(
                        'Arşivden çıkar',
                        style: ui(
                          13,
                          weight: FontWeight.w700,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: Space.s22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s18),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColor.surfaceBright,
                      borderRadius: BorderRadius.circular(Radii.card + 8),
                      boxShadow: Elevation.card,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.card + 8),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (nonce != null && !reduceMotion)
                            Positioned.fill(
                              child: Center(
                                child: Halo(color: palette.ring, nonce: nonce),
                              ),
                            ),
                          Semantics(
                            label: hasRecs
                                ? '${stats.days} gün oldu'
                                : 'henüz kayıt yok',
                            child: ExcludeSemantics(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: hasRecs
                                        ? DayCount(
                                            value: stats.days,
                                            color: AppColor.onSurface,
                                            reduceMotion: reduceMotion,
                                            size: 88,
                                          )
                                        : Text(
                                            '—',
                                            style: display(
                                              88,
                                              color: AppColor.outline,
                                              height: 0.86,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: Space.s12),
                                  Text(
                                    !hasRecs
                                        ? 'henüz kayıt yok'
                                        : doneToday
                                        ? 'bugün yaptın'
                                        : 'gün oldu',
                                    style: ui(
                                      13,
                                      weight: FontWeight.w600,
                                      color: AppColor.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Space.s16),
                Semantics(
                  label: stats.ringHint,
                  child: RhythmRing(
                    pct: stats.pct,
                    ring: ringColor,
                    track: ringTrack,
                    ink: stats.tier == Tier.late
                        ? AppColor.primary
                        : AppColor.onSurface,
                    label: stats.ringLabel,
                    reduceMotion: reduceMotion,
                    size: 104,
                  ),
                ),
                const SizedBox(width: Space.xs),
              ],
            ),
          ),
          const SizedBox(height: Space.s16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s18),
            child: Panel(
              padding: const EdgeInsets.symmetric(
                vertical: Space.s14,
                horizontal: Space.s16,
              ),
              color: AppColor.surfaceContainer,
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _Fact(
                        label: 'Son kayıt',
                        value: hasRecs ? formatFullDate(card.recs.first) : '—',
                      ),
                    ),
                    VerticalDivider(
                      width: Space.s20,
                      thickness: 1,
                      color: AppColor.outlineVariant,
                    ),
                    Expanded(
                      child: _Fact(
                        label: card.every != null ? 'Hedef' : 'Ortalama',
                        value: card.every != null
                            ? frequencyLabel(card.every!)
                            : avg != null
                            ? '$avg gün'
                            : '—',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (card.every != null && avg != null)
            Padding(
              padding: const EdgeInsets.only(
                top: Space.s8,
                left: Space.s22,
                right: Space.s22,
              ),
              child: Text(
                'Gerçekte ortalama $avg günde bir yapıyorsun.',
                style: ui(12, color: AppColor.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: Space.s18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s18),
            child: doneToday
                ? PrimaryButton(
                    label: 'Bugün işaretlendi',
                    icon: Icons.check_rounded,
                    tonal: true,
                    onTap: null,
                  )
                : PrimaryButton(
                    label: 'Bugün yaptım',
                    icon: Icons.check_rounded,
                    onTap: _recordToday,
                  ),
          ),
          QuietButton(
            label: 'Başka bir gün seç',
            icon: Icons.calendar_month_outlined,
            onTap: _pickDay,
          ),
          if (gaps.length >= 2)
            Padding(
              padding: const EdgeInsets.only(
                top: Space.s14,
                left: Space.s18,
                right: Space.s18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle('Aralıklar'),
                  Panel(
                    child: GapChart(gaps: gaps, typical: stats.typical),
                  ),
                ],
              ),
            ),
          const SizedBox(height: Space.s14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionTitle(
                  'Geçmiş',
                  trailing: hasRecs
                      ? Text(
                          '${card.recs.length} kayıt',
                          style: ui(
                            12.5,
                            weight: FontWeight.w600,
                            color: AppColor.outline,
                          ),
                        )
                      : null,
                ),
                if (!hasRecs)
                  Panel(
                    child: Text(
                      'Henüz kayıt yok. Yaptığında yukarıdaki düğmeyle işaretle.',
                      style: ui(
                        13,
                        color: AppColor.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  )
                else
                  Panel(
                    padding: const EdgeInsets.symmetric(vertical: Space.xs),
                    child: Column(
                      children: [
                        for (var i = 0; i < history.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              thickness: 1,
                              indent: 52,
                              endIndent: Space.s16,
                              color: AppColor.outlineTimeline,
                            ),
                          _HistoryRow(
                            dateKey: history[i],
                            gap: i + 1 < card.recs.length
                                ? daysSince(card.recs[i + 1], history[i])
                                : null,
                            latest: i == 0,
                            note: card.notes[history[i]],
                            onTap: () => _openRecord(card, history[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (card.recs.length > _historyPreview)
                  QuietButton(
                    label: _showAll
                        ? 'Daha az göster'
                        : 'Tümünü göster (${card.recs.length})',
                    onTap: () => setState(() => _showAll = !_showAll),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: ui(
            11.5,
            weight: FontWeight.w500,
            color: AppColor.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ui(14.5, weight: FontWeight.w700, color: AppColor.onSurface),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.dateKey,
    required this.gap,
    required this.latest,
    required this.note,
    required this.onTap,
  });

  final DateKey dateKey;
  final int? gap;
  final bool latest;

  /// The record's note, shown under the date.
  final String? note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      scale: 0.985,
      semanticsLabel:
          '${formatFullDate(dateKey)}${gap != null ? ', $gap gün arayla' : ''}'
          '${note != null ? ', not: $note' : ''}',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.s16,
          vertical: Space.s12,
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: latest
                      ? AppColor.primaryContainer
                      : AppColor.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  latest ? Icons.check_rounded : Icons.history_rounded,
                  size: 15,
                  color: latest ? AppColor.primary : AppColor.outline,
                ),
              ),
              const SizedBox(width: Space.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatFullDate(dateKey),
                      style: ui(
                        14,
                        weight: FontWeight.w600,
                        color: AppColor.onSurface,
                      ),
                    ),
                    if (note != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        note!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ui(12.5, color: AppColor.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              if (gap != null)
                Text(
                  '$gap gün arayla',
                  style: ui(
                    12,
                    weight: FontWeight.w500,
                    color: AppColor.outline,
                  ),
                )
              else
                Text(
                  'ilk kayıt',
                  style: ui(
                    12,
                    weight: FontWeight.w500,
                    color: AppColor.outline,
                  ),
                ),
              const SizedBox(width: Space.xs),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColor.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
