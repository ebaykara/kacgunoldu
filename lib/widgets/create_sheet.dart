import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

/// The things people most often lose track of — one tap fills the field.
const _suggestions = [
  'çarşafları değiştirdim',
  'bitkileri suladım',
  'çamaşır yıkadım',
  'spor yaptım',
  'anneme telefon ettim',
  'diş hekimine gittim',
  'saçımı kestirdim',
  'arabanın yağını değiştirdim',
  'banyoyu temizledim',
  'ilaç aldım',
];

/// "Neyi takip edelim?" — the create sheet.
class CreateSheet extends StatefulWidget {
  const CreateSheet({
    super.key,
    required this.onAddAndPickDate,
    required this.onAddToday,
  });

  /// Add the card, then open the record sheet to pick a date.
  final ValueChanged<String> onAddAndPickDate;

  /// Add the card with today already recorded.
  final ValueChanged<String> onAddToday;

  @override
  State<CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends State<CreateSheet> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _primaryPressed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _disabled => _controller.text.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Neyi takip edelim?',
            style: display(26, color: AppColor.onSurface, height: 1.14),
          ),
        ),
        const SizedBox(height: Space.s14),
        Container(
          decoration: BoxDecoration(
            color: AppColor.surfaceBright,
            borderRadius: BorderRadius.circular(Radii.field),
            border: Border.all(
              color: _focus.hasFocus ? AppColor.primary : AppColor.outlineSheet,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(Space.s16),
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: true,
            maxLines: 1,
            textInputAction: TextInputAction.done,
            cursorColor: AppColor.primary,
            style: ui(15, weight: FontWeight.w600, color: AppColor.onSurface),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: 'örn. çarşafları değiştirdim',
              hintStyle: ui(15, weight: FontWeight.w600, color: AppColor.outline),
            ),
            onSubmitted: (_) {
              if (!_disabled) widget.onAddAndPickDate(_controller.text);
            },
          ),
        ),
        const SizedBox(height: Space.s8),
        Text(
          'Geçmiş zaman yaz — kart bir cümle gibi okunur.',
          style: ui(11.5, color: AppColor.outline),
        ),
        const SizedBox(height: Space.s14),
        Wrap(
          spacing: Space.s7,
          runSpacing: Space.s7,
          children: [
            for (final s in _suggestions)
              Semantics(
                button: true,
                label: s,
                child: GestureDetector(
                  onTap: () {
                    _controller.text = s;
                    _controller.selection = TextSelection.collapsed(offset: s.length);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: Space.s14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Radii.pill),
                      border: Border.all(color: AppColor.outlineSheet),
                    ),
                    child: Text(
                      s,
                      style: ui(12.5, weight: FontWeight.w600, color: AppColor.onSurfaceMuted),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Space.s18),
        Semantics(
          button: true,
          enabled: !_disabled,
          label: 'Ekle ve tarih seç',
          child: GestureDetector(
            onTap: _disabled ? null : () => widget.onAddAndPickDate(_controller.text),
            onTapDown: _disabled ? null : (_) => setState(() => _primaryPressed = true),
            onTapUp: _disabled ? null : (_) => setState(() => _primaryPressed = false),
            onTapCancel: () => setState(() => _primaryPressed = false),
            child: AnimatedScale(
              scale: _primaryPressed ? 0.98 : 1,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              child: Opacity(
                opacity: _disabled ? 0.45 : 1,
                child: Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: AppColor.primary,
                    borderRadius: BorderRadius.circular(Radii.button),
                  ),
                  child: Text(
                    'Ekle ve tarih seç',
                    textAlign: TextAlign.center,
                    style: ui(14.5, weight: FontWeight.w700, color: AppColor.onPrimary),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Space.s8),
        Semantics(
          button: true,
          enabled: !_disabled,
          label: 'Bugün itibariyle ekle',
          child: GestureDetector(
            onTap: _disabled ? null : () => widget.onAddToday(_controller.text),
            child: Opacity(
              opacity: _disabled ? 0.45 : 1,
              child: Container(
                padding: const EdgeInsets.all(Space.s16),
                decoration: BoxDecoration(
                  color: AppColor.surfaceContainer,
                  borderRadius: BorderRadius.circular(Radii.button),
                ),
                child: Text(
                  'Bugün itibariyle ekle',
                  textAlign: TextAlign.center,
                  style: ui(14.5, weight: FontWeight.w600, color: AppColor.onSurfaceMuted),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
