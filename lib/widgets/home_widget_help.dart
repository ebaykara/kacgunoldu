import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart' hide Card;

import '../domain/card.dart';
import '../l10n/strings.dart';
import '../services/home_widgets.dart' show PinResult;
import '../state/card_store.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'app_sheet.dart';
import 'ui.dart';

/// "Ana ekrana ekle" from the app: asks the launcher, and when that can't
/// work says why and what to do instead.
Future<void> pinHomeWidget(BuildContext context, CardStore store, {Card? card, bool list = false}) async {
  final result = await store.pinWidget(cardId: card?.id, list: list);
  if (!context.mounted) return;
  switch (result) {
    case PinResult.requested:
      break;
    case PinResult.blocked:
      await _showPinBlocked(context, store, card: card);
    case PinResult.unsupported:
      await showHomeWidgetHelp(context, card: card);
  }
}

/// MIUI refused once and now drops every request without a dialog.
Future<void> _showPinBlocked(BuildContext context, CardStore store, {Card? card}) {
  return showAppSheet<void>(
    context: context,
    reduceMotion: MediaQuery.of(context).disableAnimations,
    builder: (sheetContext) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          S.widgetCantPinTitle,
          style: display(24, color: AppColor.onSurface, height: 1.14),
        ),
        const SizedBox(height: Space.s8),
        Text(
          S.widgetCantPinBody,
          style: ui(14, color: AppColor.onSurfaceVariant, height: 1.45),
        ),
        const SizedBox(height: Space.s18),
        PrimaryButton(
          label: S.widgetOpenPermission,
          icon: Icons.open_in_new_rounded,
          onTap: () {
            Navigator.of(sheetContext).pop();
            store.openPinPermission();
          },
        ),
        const SizedBox(height: Space.s8),
        QuietButton(
          label: S.widgetShowManual,
          onTap: () {
            Navigator.of(sheetContext).pop();
            showHomeWidgetHelp(context, card: card);
          },
        ),
      ],
    ),
  );
}

/// How to put a widget on the home screen by hand — iOS always, Android when
/// the launcher can't take it from the app. With [card], the steps end on
/// picking that card.
Future<void> showHomeWidgetHelp(BuildContext context, {Card? card}) {
  final ios = defaultTargetPlatform == TargetPlatform.iOS;
  final pick = card == null ? null : '“${card.name}”';
  final steps = S.widgetHelpSteps(ios: ios, pick: pick);
  return showAppSheet<void>(
    context: context,
    reduceMotion: MediaQuery.of(context).disableAnimations,
    builder: (sheetContext) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          S.widgetHelpTitle,
          style: display(24, color: AppColor.onSurface, height: 1.14),
        ),
        const SizedBox(height: Space.s6),
        Text(
          S.widgetHelpBody,
          style: ui(13.5, color: AppColor.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: Space.s14),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.s12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColor.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: ui(12, weight: FontWeight.w700, color: AppColor.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: Space.s12),
                Expanded(
                  child: Text(
                    steps[i],
                    style: ui(14, color: AppColor.onSurface, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
