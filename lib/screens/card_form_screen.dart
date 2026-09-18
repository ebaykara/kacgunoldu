import 'dart:math' as math;

import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart' show FilteringTextInputFormatter;

import '../domain/date.dart';
import '../domain/frequency.dart';
import '../domain/icon_guess.dart';
import '../domain/logic.dart';
import '../domain/reminders.dart';
import '../state/card_store.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/app_sheet.dart';
import '../widgets/card_glyph.dart';
import '../widgets/record_sheet.dart';
import '../widgets/store_snack.dart';
import '../widgets/ui.dart';

/// "Yeni kart" — and, with [editCardId], "Kartı düzenle".
///
/// Name, first date and rhythm on one page; the glyph is guessed from the
/// name as it is typed and can be overridden from the field's trailing
/// button or under "Gelişmiş seçenekler".
class CardFormScreen extends StatefulWidget {
  const CardFormScreen({
    super.key,
    required this.store,
    this.editCardId,
    this.initialName,
    this.initialIcon,
    this.initialEvery,
  });

  final CardStore store;
  final String? editCardId;

  /// Prefill from a suggestion ("Önerilen kartlar").
  final String? initialName;
  final String? initialIcon;
  final int? initialEvery;

  @override
  State<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<CardFormScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  /// Picked glyph; `null` follows the name.
  String? _icon;
  int? _every;

  /// Days ago of the first record; `null` = "Henüz yapmadım".
  int? _offset = 0;
  bool _advanced = false;

  /// Remind me when it comes due.
  bool _notify = false;

  bool get _editing => widget.editCardId != null;
  bool get _valid => _controller.text.trim().isNotEmpty;
  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;
  String get _shownIcon => _icon ?? guessIcon(_controller.text);

  @override
  void initState() {
    super.initState();
    final existing = _editing ? widget.store.byId(widget.editCardId!) : null;
    if (existing != null) {
      _controller.text = existing.name;
      _icon = existing.icon;
      _every = existing.every;
      _notify = existing.notify;
    } else {
      _controller.text = widget.initialName ?? '';
      _icon = widget.initialIcon;
      _every = widget.initialEvery;
    }
    _controller.addListener(() => setState(() {}));
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Turning reminders on asks for permission first; a refusal leaves the
  /// switch off and says why.
  Future<void> _toggleNotify(bool on) async {
    if (!on) {
      setState(() => _notify = false);
      return;
    }
    final granted = await widget.store.requestReminderPermission();
    if (!mounted) return;
    if (granted) {
      setState(() => _notify = true);
    } else {
      widget.store.toast('Bildirim izni kapalı. Telefon ayarlarından açabilirsin.');
    }
  }

  String _notifyHint() {
    final store = widget.store;
    final time = timeLabel(store.reminderHour, store.reminderMinute);
    final existing = _editing ? store.byId(widget.editCardId!) : null;
    final hasRhythm = _every != null ||
        (existing != null && statsFor(existing, store.today).typical != null);
    return hasRhythm
        ? 'Sırası gelince saat $time civarı haber veririm.'
        : 'Ritmini öğrenince haber veririm (3 kayıttan sonra) ya da bir sıklık seç.';
  }

  void _submit() {
    if (!_valid) return;
    final store = widget.store;
    if (_editing) {
      store.updateCard(
        widget.editCardId!,
        name: _controller.text,
        icon: _icon,
        every: _every,
        notify: _notify,
      );
    } else {
      store.addCard(
        _controller.text,
        _offset,
        icon: _icon,
        every: _every,
        notify: _notify,
      );
    }
    Navigator.of(context).pop();
  }

  String _dateLabel() {
    final o = _offset;
    if (o == null) return 'Henüz yapmadım';
    if (o == 0) return 'Bugün';
    if (o == 1) return 'Dün';
    final today = widget.store.today;
    return '${relativeLabel(o)} · ${formatDayMonth(shiftDays(today, -o), today)}';
  }

  Future<void> _pickDate() async {
    _focus.unfocus();
    await showAppSheet<void>(
      context: context,
      reduceMotion: _reduceMotion,
      builder: (sheetContext) => RecordSheet(
        card: null,
        today: widget.store.today,
        selectedOffset: _offset,
        onPick: (offset) {
          Navigator.of(sheetContext).pop();
          setState(() => _offset = offset);
        },
        onNotYet: () {
          Navigator.of(sheetContext).pop();
          setState(() => _offset = null);
        },
      ),
    );
  }

  Future<void> _pickIcon() async {
    _focus.unfocus();
    final picked = await showAppSheet<String>(
      context: context,
      reduceMotion: _reduceMotion,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Simge seç',
            style: display(26, color: AppColor.onSurface, height: 1.14),
          ),
          const SizedBox(height: Space.s14),
          IconGrid(
            selected: _icon,
            guessed: guessIcon(_controller.text),
            onPick: (key) => Navigator.of(sheetContext).pop(key ?? ''),
          ),
        ],
      ),
    );
    if (picked == null) return;
    setState(() => _icon = picked.isEmpty ? null : picked);
  }

  Future<void> _pickCustom() async {
    _focus.unfocus();
    final picked = await showAppSheet<int>(
      context: context,
      reduceMotion: _reduceMotion,
      builder: (sheetContext) => _CustomFrequency(
        initial: _every != null && !isPresetFrequency(_every!) ? _every! : 10,
        onDone: (days) => Navigator.of(sheetContext).pop(days),
      ),
    );
    if (picked != null) setState(() => _every = picked);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final customSelected = _every != null && !isPresetFrequency(_every!);

    final page = Column(
      children: [
        PageHeader(title: _editing ? 'Kartı düzenle' : 'Yeni kart'),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              Space.s20,
              Space.s8,
              Space.s20,
              media.padding.bottom + Space.s22,
            ),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Label('Ne yaptın?'),
                AnimatedContainer(
                  duration: Motion.hover,
                  decoration: BoxDecoration(
                    color: AppColor.surfaceBright,
                    borderRadius: BorderRadius.circular(Radii.field),
                    border: Border.all(
                      color: _focus.hasFocus
                          ? AppColor.primary
                          : AppColor.outlineSheet,
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.only(
                    left: Space.s16,
                    right: Space.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focus,
                          autofocus: !_editing && widget.initialName == null,
                          maxLines: 1,
                          maxLength: 60,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.done,
                          cursorColor: AppColor.primary,
                          style: ui(
                            15,
                            weight: FontWeight.w600,
                            color: AppColor.onSurface,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            counterText: '',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: Space.s16,
                            ),
                            hintText: 'Örn. Saçımı kestirdim',
                            hintStyle: ui(
                              15,
                              weight: FontWeight.w500,
                              color: AppColor.outline,
                            ),
                          ),
                          onSubmitted: (_) => _focus.unfocus(),
                        ),
                      ),
                      PressScale(
                        onTap: _pickIcon,
                        scale: 0.9,
                        semanticsLabel: 'Simge seç',
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColor.primaryContainer,
                            borderRadius: BorderRadius.circular(Radii.item - 2),
                          ),
                          child: CardGlyph(
                            iconKey: _shownIcon,
                            color: AppColor.primary,
                            size: 21,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_editing) ...[
                  const SizedBox(height: Space.s22),
                  const _Label('Ne zaman yaptın?'),
                  PressScale(
                    onTap: _pickDate,
                    scale: 0.985,
                    semanticsLabel: 'Ne zaman yaptın? ${_dateLabel()}',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.s16,
                        vertical: Space.s15,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.surfaceBright,
                        borderRadius: BorderRadius.circular(Radii.field),
                        border: Border.all(
                          color: AppColor.outlineSheet,
                          width: 1.5,
                        ),
                      ),
                      child: ExcludeSemantics(
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 19,
                              color: AppColor.onSurfaceMuted,
                            ),
                            const SizedBox(width: Space.s12),
                            Expanded(
                              child: Text(
                                _dateLabel(),
                                style: ui(
                                  15,
                                  weight: FontWeight.w600,
                                  color: AppColor.onSurface,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.expand_more_rounded,
                              color: AppColor.outline,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: Space.s22),
                const _Label('Ne sıklıkla tekrarlıyorsun?'),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = math.max(
                      0.0,
                      (constraints.maxWidth - Space.s8 * 2) / 3,
                    );
                    return Wrap(
                      spacing: Space.s8,
                      runSpacing: Space.s8,
                      children: [
                        for (final (days, label) in frequencyPresets)
                          SizedBox(
                            width: w,
                            child: _Chip(
                              label: label,
                              selected: _every == days,
                              onTap: () => setState(
                                () => _every = _every == days ? null : days,
                              ),
                            ),
                          ),
                        SizedBox(
                          width: w,
                          child: _Chip(
                            label: customSelected
                                ? '$_every günde bir'
                                : 'Özel',
                            selected: customSelected,
                            onTap: _pickCustom,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: Space.s12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColor.outline,
                      ),
                    ),
                    const SizedBox(width: Space.s8),
                    Expanded(
                      child: Text(
                        _every == null
                            ? 'Seçmezsen ritmini kayıtlarından kendim öğrenirim.'
                            : '${frequencyLabel(_every!)} demek: bu aralık belirgin şekilde aşılınca kart “gecikti” olur.',
                        style: ui(
                          12.5,
                          color: AppColor.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.s18),
                Panel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.s16,
                    vertical: Space.s12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _notify
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_none_rounded,
                        color: _notify ? AppColor.primary : AppColor.onSurfaceMuted,
                      ),
                      const SizedBox(width: Space.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bana hatırlat',
                              style: ui(
                                14,
                                weight: FontWeight.w700,
                                color: AppColor.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _notifyHint(),
                              style: ui(
                                12,
                                color: AppColor.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Semantics(
                        label: 'Bana hatırlat',
                        toggled: _notify,
                        child: Switch(
                          value: _notify,
                          onChanged: _toggleNotify,
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
                ),
                const SizedBox(height: Space.s12),
                Panel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PressScale(
                        onTap: () => setState(() => _advanced = !_advanced),
                        scale: 0.99,
                        semanticsLabel: 'Gelişmiş seçenekler',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.s16,
                            vertical: Space.s16,
                          ),
                          child: ExcludeSemantics(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Gelişmiş seçenekler',
                                    style: ui(
                                      14,
                                      weight: FontWeight.w600,
                                      color: AppColor.onSurface,
                                    ),
                                  ),
                                ),
                                AnimatedRotation(
                                  turns: _advanced ? 0.5 : 0,
                                  duration: Motion.hover,
                                  child: Icon(
                                    Icons.expand_more_rounded,
                                    color: AppColor.onSurfaceMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      AnimatedSize(
                        duration: _reduceMotion ? Duration.zero : Motion.swap,
                        curve: Motion.emphasized,
                        alignment: Alignment.topCenter,
                        child: _advanced
                            ? Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  Space.s16,
                                  0,
                                  Space.s16,
                                  Space.s16,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Simge',
                                      style: ui(
                                        12.5,
                                        weight: FontWeight.w700,
                                        color: AppColor.onSurfaceMuted,
                                      ),
                                    ),
                                    const SizedBox(height: Space.s8),
                                    IconGrid(
                                      selected: _icon,
                                      guessed: guessIcon(_controller.text),
                                      onPick: (key) =>
                                          setState(() => _icon = key),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox(width: double.infinity),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.s22),
                PrimaryButton(
                  label: _editing ? 'Kaydet' : 'Kartı oluştur',
                  enabled: _valid,
                  onTap: _submit,
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return Stack(
      children: [
        page,
        StoreSnackLayer(
          store: widget.store,
          bottom: media.viewInsets.bottom + media.padding.bottom + Space.s16,
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s8, left: 2),
      child: Text(
        text,
        style: ui(14, weight: FontWeight.w700, color: AppColor.onSurface),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      scale: 0.95,
      haptic: true,
      selected: selected,
      semanticsLabel: label,
      child: AnimatedContainer(
        duration: Motion.hover,
        height: 44,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: Space.s6),
        decoration: BoxDecoration(
          color: selected ? AppColor.primary : AppColor.surfaceBright,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(
            color: selected ? AppColor.primary : AppColor.outlineSheet,
          ),
          boxShadow: selected ? Elevation.button : null,
        ),
        child: ExcludeSemantics(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: ui(
                12.5,
                weight: FontWeight.w600,
                color: selected ? AppColor.onPrimary : AppColor.onSurfaceMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Every glyph, plus "Otomatik" (follow the name). [onPick] gets `null` for
/// automatic.
class IconGrid extends StatelessWidget {
  const IconGrid({
    super.key,
    required this.selected,
    required this.guessed,
    required this.onPick,
  });

  final String? selected;
  final String guessed;
  final ValueChanged<String?> onPick;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const perRow = 6;
        final w = math.max(
          0.0,
          (constraints.maxWidth - Space.s8 * (perRow - 1)) / perRow,
        );
        Widget cell({
          required String iconKey,
          required bool on,
          required String label,
          required VoidCallback onTap,
          bool auto = false,
        }) {
          return SizedBox(
            width: w,
            height: w,
            child: PressScale(
              onTap: onTap,
              scale: 0.9,
              selected: on,
              semanticsLabel: label,
              child: AnimatedContainer(
                duration: Motion.hover,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? AppColor.primary : AppColor.surfaceContainer,
                  borderRadius: BorderRadius.circular(Radii.item),
                ),
                child: auto
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CardGlyph(
                            iconKey: iconKey,
                            color: on
                                ? AppColor.onPrimary
                                : AppColor.onSurfaceMuted,
                            size: 16,
                          ),
                          Text(
                            'oto',
                            style: ui(
                              9,
                              weight: FontWeight.w700,
                              color: on
                                  ? AppColor.onPrimary
                                  : AppColor.onSurfaceMuted,
                            ),
                          ),
                        ],
                      )
                    : CardGlyph(
                        iconKey: iconKey,
                        color: on
                            ? AppColor.onPrimary
                            : AppColor.onSurfaceMuted,
                        size: 21,
                      ),
              ),
            ),
          );
        }

        return Wrap(
          spacing: Space.s8,
          runSpacing: Space.s8,
          children: [
            cell(
              iconKey: guessed,
              on: selected == null,
              label: 'Otomatik simge',
              onTap: () => onPick(null),
              auto: true,
            ),
            for (final key in cardGlyphs.keys)
              cell(
                iconKey: key,
                on: selected == key,
                label: glyphLabels[key] ?? key,
                onTap: () => onPick(key),
              ),
          ],
        );
      },
    );
  }
}

/// "Özel" — any interval, as a number of days, weeks or months.
class _CustomFrequency extends StatefulWidget {
  const _CustomFrequency({required this.initial, required this.onDone});

  final int initial;
  final ValueChanged<int> onDone;

  @override
  State<_CustomFrequency> createState() => _CustomFrequencyState();
}

class _CustomFrequencyState extends State<_CustomFrequency> {
  late final _controller = TextEditingController(text: '${widget.initial}');

  int get _days => int.tryParse(_controller.text) ?? 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _set(int v) {
    final clamped = v.clamp(1, 999);
    _controller.text = '$clamped';
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final valid = _days >= 1 && _days <= 999;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Kaç günde bir?',
          style: display(26, color: AppColor.onSurface, height: 1.14),
        ),
        const SizedBox(height: Space.s16),
        Row(
          children: [
            RoundIconButton(
              icon: Icons.remove_rounded,
              label: 'Azalt',
              background: AppColor.surfaceContainer,
              onTap: () => _set(_days - 1),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 3,
                cursorColor: AppColor.primary,
                style: display(48, color: AppColor.onSurface, height: 1.1),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
            RoundIconButton(
              icon: Icons.add_rounded,
              label: 'Artır',
              background: AppColor.surfaceContainer,
              onTap: () => _set(_days + 1),
            ),
          ],
        ),
        Text(
          'günde bir',
          textAlign: TextAlign.center,
          style: ui(
            13,
            weight: FontWeight.w600,
            color: AppColor.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Space.s14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: Space.s8,
          runSpacing: Space.s8,
          children: [
            for (final d in const [4, 5, 10, 21, 45, 120])
              PressScale(
                onTap: () => _set(d),
                semanticsLabel: '$d gün',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.s14,
                    vertical: Space.s8,
                  ),
                  decoration: BoxDecoration(
                    color: _days == d
                        ? AppColor.primaryContainer
                        : AppColor.surfaceContainer,
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  child: Text(
                    '$d gün',
                    style: ui(
                      12.5,
                      weight: FontWeight.w600,
                      color: AppColor.onSurfaceMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Space.s18),
        PrimaryButton(
          label: 'Tamam',
          enabled: valid,
          onTap: () => widget.onDone(_days),
        ),
      ],
    );
  }
}
