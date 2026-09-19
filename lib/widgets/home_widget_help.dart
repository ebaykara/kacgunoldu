import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart' hide Card;

import '../domain/card.dart';
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
          'Telefonun eklemeye izin vermiyor',
          style: display(24, color: AppColor.onSurface, height: 1.14),
        ),
        const SizedBox(height: Space.s8),
        Text(
          'Onay penceresinde “Reddet”i seçince telefon bu isteği bir daha sormadan '
          'engelliyor. İzinler sayfasında “Ana ekran kısayolları”nı açıp tekrar dene.',
          style: ui(14, color: AppColor.onSurfaceVariant, height: 1.45),
        ),
        const SizedBox(height: Space.s18),
        PrimaryButton(
          label: 'İzni aç',
          icon: Icons.open_in_new_rounded,
          onTap: () {
            Navigator.of(sheetContext).pop();
            store.openPinPermission();
          },
        ),
        const SizedBox(height: Space.s8),
        QuietButton(
          label: 'Elle eklemeyi göster',
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
  final steps = ios
      ? [
          'Ana ekranda boş bir yere basılı tut, sol üstteki Düzenle → Widget ekle’ye dokun.',
          'Listeden Kaç Gün Oldu?’yu seç: tek kart için Kart, birkaçı için Kartlar.',
          pick == null
              ? 'Kart’ın göstereceği kartı seçmek için widget’a basılı tut → Widget’ı Düzenle.'
              : 'Widget’a basılı tut → Widget’ı Düzenle → Kart: $pick.',
          'Kilit ekranına da ekleyebilirsin: kilit ekranına basılı tut → Özelleştir.',
        ]
      : [
          'Ana ekranda boş bir yere basılı tut, Widget’lar’a dokun.',
          'Kaç Gün Oldu?’yu bul: tek kart için Kart, birkaçı için Kartlar.',
          pick == null
              ? 'Kart’ı ekleyince hangi kartı göstereceğini sorar.'
              : 'Kart’ı ekleyince açılan listeden $pick kartını seç.',
        ];
  return showAppSheet<void>(
    context: context,
    reduceMotion: MediaQuery.of(context).disableAnimations,
    builder: (sheetContext) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ana ekrana widget ekle',
          style: display(24, color: AppColor.onSurface, height: 1.14),
        ),
        const SizedBox(height: Space.s6),
        Text(
          'Kartlarının kaç gün olduğunu uygulamayı açmadan gör; '
          '“Bugün yaptım”a widget’tan dokun.',
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
