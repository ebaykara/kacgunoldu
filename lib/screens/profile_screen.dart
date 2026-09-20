import 'dart:math' as math;

import 'package:flutter/material.dart' hide Card;

import '../domain/card.dart';
import '../domain/date.dart';
import '../domain/insights.dart';
import '../domain/logic.dart';
import '../domain/text.dart';
import '../l10n/strings.dart';
import '../state/card_store.dart';
import '../storage/repository.dart' show Profile;
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/app_sheet.dart';
import '../widgets/card_glyph.dart';
import '../widgets/icons.dart';
import '../widgets/store_snack.dart';
import '../widgets/ui.dart';
import 'card_detail_screen.dart';
import 'settings_screen.dart';

/// "Profil" — who is tracking, and what the records say about them.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.store});

  final CardStore store;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Stack(
      children: [
        ListenableBuilder(
          listenable: store,
          builder: (context, _) => _body(context, media),
        ),
        StoreSnackLayer(store: store, bottom: media.padding.bottom + Space.s16),
      ],
    );
  }

  void _openCard(BuildContext context, Card card) {
    pushPage<void>(
      context,
      (_) => CardDetailScreen(store: store, cardId: card.id),
    );
  }

  Widget _body(BuildContext context, MediaQueryData media) {
    final cards = store.cards;
    final today = store.today;
    final t = fromDateKey(today);
    final profile = store.profile;
    final thisMonth = recordsInMonth(cards, t.year, t.month);
    final prev = DateTime(t.year, t.month - 1);
    final lastMonth = recordsInMonth(cards, prev.year, prev.month);
    final delta = thisMonth - lastMonth;
    final regular = mostRegular(cards, today);
    final neglected = longestNeglected(cards, today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: S.profileTitle,
          trailing: RoundIconButton(
            icon: Icons.settings_outlined,
            label: S.settings,
            onTap: () =>
                pushPage<void>(context, (_) => SettingsScreen(store: store)),
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              Space.s18,
              Space.s8,
              Space.s18,
              media.padding.bottom + 96,
            ),
            children: [
              PressScale(
                onTap: () => editProfile(context, store),
                scale: 0.985,
                semanticsLabel: profile.isEmpty
                    ? S.addYourName
                    : S.editProfileSemantics(profile.name),
                child: ExcludeSemantics(
                  child: Row(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColor.primaryLight, AppColor.primary],
                          ),
                          boxShadow: Elevation.button,
                        ),
                        child: profile.isEmpty
                            ? PersonIcon(
                                color: AppColor.onPrimary,
                                size: 28,
                              )
                            : Text(
                                initialsOf(profile.name),
                                style: ui(
                                  24,
                                  weight: FontWeight.w600,
                                  color: AppColor.onPrimary,
                                ),
                              ),
                      ),
                      const SizedBox(width: Space.s16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.isEmpty ? S.addYourName : profile.name,
                              style: ui(
                                19,
                                weight: FontWeight.w700,
                                color: AppColor.onSurface,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              profile.handle.isNotEmpty
                                  ? '@${profile.handle}'
                                  : profile.isEmpty
                                  ? S.tapToPersonalise
                                  : S.tapToEdit,
                              style: ui(13, color: AppColor.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.edit_outlined,
                        size: 19,
                        color: AppColor.outline,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Space.s20),
              Row(
                children: [
                  Expanded(
                    child: _Stat(value: cards.length, label: S.statTotalCards),
                  ),
                  const SizedBox(width: Space.s12),
                  Expanded(
                    child: _Stat(
                      value: totalRecords(cards),
                      label: S.statTotalRecords,
                    ),
                  ),
                  const SizedBox(width: Space.s12),
                  Expanded(
                    child: _Stat(
                      value: newCardsThisMonth(cards, today),
                      label: S.statNewThisMonth,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.s16),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.monthSummary,
                      style: ui(
                        14,
                        weight: FontWeight.w700,
                        color: AppColor.onSurface,
                      ),
                    ),
                    const SizedBox(height: Space.s14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.event_note_outlined,
                                    size: 19,
                                    color: AppColor.onSurfaceMuted,
                                  ),
                                  const SizedBox(width: Space.s8),
                                  Flexible(
                                    child: Text(
                                      S.recordsMade(thisMonth),
                                      style: ui(
                                        15,
                                        weight: FontWeight.w700,
                                        color: AppColor.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: Space.s6),
                              Text.rich(
                                TextSpan(
                                  text: S.vsLastMonth,
                                  children: [
                                    TextSpan(
                                      text: delta > 0 ? '+$delta' : '$delta',
                                      style: ui(
                                        12.5,
                                        weight: FontWeight.w700,
                                        color: delta >= 0
                                            ? AppColor.tertiary
                                            : AppColor.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                style: ui(
                                  12.5,
                                  color: AppColor.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _MonthBars(counts: monthlyCounts(cards, today)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.s12),
              _Insight(
                icon: Icons.eco_outlined,
                title: S.insightRegular,
                card: regular?.card,
                detail: regular == null
                    ? null
                    : S.insightRegularDetail(regular.every),
                empty: S.insightRegularEmpty,
                store: store,
                onOpen: (c) => _openCard(context, c),
              ),
              const SizedBox(height: Space.s12),
              _Insight(
                icon: Icons.hourglass_bottom_rounded,
                title: S.insightNeglected,
                card: neglected?.card,
                detail: neglected == null ? null : S.nDays(neglected.days),
                empty: S.insightNeglectedEmpty,
                store: store,
                onOpen: (c) => _openCard(context, c),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Name + handle, from the profile row or the settings screen.
Future<void> editProfile(BuildContext context, CardStore store) {
  return showAppSheet<void>(
    context: context,
    reduceMotion: MediaQuery.of(context).disableAnimations,
    builder: (sheetContext) => _ProfileForm(
      initial: store.profile,
      onSave: (p) {
        store.updateProfile(p);
        Navigator.of(sheetContext).pop();
      },
    ),
  );
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({required this.initial, required this.onSave});

  final Profile initial;
  final ValueChanged<Profile> onSave;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  late final _name = TextEditingController(text: widget.initial.name);
  late final _handle = TextEditingController(text: widget.initial.handle);

  @override
  void dispose() {
    _name.dispose();
    _handle.dispose();
    super.dispose();
  }

  Widget _field(
    String label,
    TextEditingController c,
    String hint, {
    String? prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: ui(13, weight: FontWeight.w700, color: AppColor.onSurface),
        ),
        const SizedBox(height: Space.s6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: Space.s16),
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(Radii.field),
            border: Border.all(color: AppColor.outlineSheet, width: 1.5),
          ),
          child: TextField(
            controller: c,
            maxLength: 40,
            cursorColor: AppColor.primary,
            style: ui(15, weight: FontWeight.w600, color: AppColor.onSurface),
            decoration: InputDecoration(
              border: InputBorder.none,
              counterText: '',
              hintText: hint,
              prefixText: prefix,
              prefixStyle: ui(
                15,
                weight: FontWeight.w600,
                color: AppColor.outline,
              ),
              hintStyle: ui(
                15,
                weight: FontWeight.w500,
                color: AppColor.outline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          S.profileTitle,
          style: display(26, color: AppColor.onSurface, height: 1.14),
        ),
        const SizedBox(height: Space.s16),
        _field(S.fieldName, _name, S.fieldNameHint),
        const SizedBox(height: Space.s14),
        _field(S.fieldHandle, _handle, S.fieldHandleHint, prefix: '@'),
        const SizedBox(height: Space.s18),
        PrimaryButton(
          label: S.save,
          onTap: () =>
              widget.onSave(Profile(name: _name.text, handle: _handle.text)),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.symmetric(
        vertical: Space.s14,
        horizontal: Space.s8,
      ),
      radius: Radii.tile,
      child: Semantics(
        label: '$value $label',
        child: ExcludeSemantics(
          child: Column(
            children: [
              Text(
                '$value',
                style: display(30, color: AppColor.primary, height: 1),
              ),
              const SizedBox(height: Space.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: ui(
                    11.5,
                    weight: FontWeight.w600,
                    color: AppColor.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Six little bars, one per month; the current one in full terracotta.
class _MonthBars extends StatelessWidget {
  const _MonthBars({required this.counts});

  final List<MonthCount> counts;

  @override
  Widget build(BuildContext context) {
    final top = counts.fold<int>(1, (m, c) => math.max(m, c.count));
    return Semantics(
      label: counts.map((c) => '${c.label} ${c.count}').join(', '),
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < counts.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: counts[i].count / top),
                    duration: const Duration(milliseconds: 600),
                    curve: Motion.emphasized,
                    builder: (context, v, _) => Container(
                      width: 12,
                      height: math.max(4, 48 * v),
                      decoration: BoxDecoration(
                        color: i == counts.length - 1
                            ? AppColor.primary
                            : AppColor.primaryContainerHover,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    counts[i].label,
                    style: ui(
                      8.5,
                      weight: FontWeight.w600,
                      color: AppColor.outline,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Insight extends StatelessWidget {
  const _Insight({
    required this.icon,
    required this.title,
    required this.card,
    required this.detail,
    required this.empty,
    required this.store,
    required this.onOpen,
  });

  final IconData icon;
  final String title;
  final Card? card;
  final String? detail;
  final String empty;
  final CardStore store;
  final ValueChanged<Card> onOpen;

  @override
  Widget build(BuildContext context) {
    final c = card;
    final tier = c == null ? Tier.calm : decorate(c, store.today).stats.tier;
    final badge = badgeColors(tier);
    final content = Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColor.tertiary),
              const SizedBox(width: Space.s8),
              Expanded(
                child: Text(
                  title,
                  style: ui(
                    14,
                    weight: FontWeight.w700,
                    color: AppColor.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.s12),
          if (c == null)
            Text(empty, style: ui(13, color: AppColor.onSurfaceVariant))
          else
            Row(
              children: [
                GlyphBadge(
                  iconKey: iconKeyOf(c),
                  bg: badge.bg,
                  fg: badge.fg,
                  size: 38,
                ),
                const SizedBox(width: Space.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ui(
                          13.5,
                          weight: FontWeight.w600,
                          color: AppColor.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail!,
                        style: ui(12, color: AppColor.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColor.outline,
                ),
              ],
            ),
        ],
      ),
    );
    if (c == null) return content;
    return PressScale(
      onTap: () => onOpen(c),
      scale: 0.985,
      semanticsLabel: '$title: ${c.name}, $detail',
      child: ExcludeSemantics(child: content),
    );
  }
}
