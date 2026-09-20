import 'package:flutter/material.dart' hide Card;

import '../domain/text.dart';
import '../l10n/strings.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'ui.dart';

/// Longest note a record takes — a line, not a diary.
const noteMaxLength = 140;

/// "Not" — one line written on a record ("45.200 km", "dolgu yapıldı").
/// Saving an empty field removes the note.
class NoteSheet extends StatefulWidget {
  const NoteSheet({
    super.key,
    required this.dateLabel,
    required this.initial,
    required this.onSave,
  });

  /// `18 Eylül 2026`, the record the note belongs to.
  final String dateLabel;
  final String initial;
  final ValueChanged<String> onSave;

  @override
  State<NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<NoteSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          upperTr(widget.dateLabel),
          style: overline(color: AppColor.outline),
        ),
        const SizedBox(height: Space.s6),
        Text(
          widget.initial.isEmpty ? S.addNote : S.editNote,
          style: display(26, color: AppColor.onSurface, height: 1.14),
        ),
        const SizedBox(height: Space.s16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: Space.s16),
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(Radii.field),
            border: Border.all(color: AppColor.outlineSheet, width: 1.5),
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            minLines: 1,
            maxLines: 3,
            maxLength: noteMaxLength,
            textCapitalization: TextCapitalization.sentences,
            cursorColor: AppColor.primary,
            style: ui(15, weight: FontWeight.w600, color: AppColor.onSurface),
            decoration: InputDecoration(
              border: InputBorder.none,
              counterText: '',
              hintText: S.notePlaceholder,
              hintStyle: ui(
                15,
                weight: FontWeight.w500,
                color: AppColor.outline,
              ),
            ),
          ),
        ),
        const SizedBox(height: Space.s18),
        PrimaryButton(
          label: S.save,
          onTap: () => widget.onSave(_controller.text),
        ),
      ],
    );
  }
}
