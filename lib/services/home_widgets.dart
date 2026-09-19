import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/card.dart';
import '../domain/date.dart';
import '../domain/logic.dart';
import '../theme/tokens.dart';
import '../widgets/card_glyph.dart' show iconKeyOf;

/// The home screen widgets' side of the app (Android `widget/`, iOS
/// `KacGunOlduWidget`). They are drawn natively, from a snapshot this side
/// writes whenever the cards or the theme change.
///
/// The snapshot holds only what does not change from day to day — each card's
/// last record and its interval — so the widgets work out the day count
/// themselves and stay right past midnight without the app being opened.
abstract class HomeWidgets {
  /// Replaces what the widgets draw from and redraws them.
  Future<void> publish(String snapshot);

  /// Days marked with a widget's "Bugün yaptım" button since the last call,
  /// oldest first; handing them over clears them on the native side.
  Future<List<WidgetMark>> takeMarks();

  /// Whether the app can put a widget on the home screen itself (Android 8+
  /// with a launcher that allows it). Elsewhere the person adds it by hand.
  Future<bool> canPin();

  /// Asks the launcher to place a widget: the single-card one showing
  /// [cardId], or the list when [list] is set.
  Future<PinResult> pin({String? cardId, bool list = false});

  /// Opens the system page where a refused "add to home screen" permission
  /// can be turned back on (MIUI — see [PinResult.blocked]).
  Future<void> openPinPermission();

  /// A widget asked for with [pin] has been placed. MIUI places it without
  /// any dialog, so this is the only sign that it worked.
  Stream<void> get pinned;
}

/// What came of asking to place a widget.
enum PinResult {
  /// The launcher is asking the person to confirm.
  requested,

  /// The phone drops the request without asking: MIUI, after its
  /// "Ana ekran kısayolları" permission was refused once.
  blocked,

  /// Not possible from the app here; the person adds it by hand.
  unsupported,
}

/// One tap of a widget's "Bugün yaptım": this card, done on [day].
typedef WidgetMark = ({String id, DateKey day});

class NoopHomeWidgets implements HomeWidgets {
  @override
  Future<void> publish(String snapshot) async {}

  @override
  Future<List<WidgetMark>> takeMarks() async => const [];

  @override
  Future<bool> canPin() async => false;

  @override
  Future<PinResult> pin({String? cardId, bool list = false}) async => PinResult.unsupported;

  @override
  Future<void> openPinPermission() async {}

  @override
  Stream<void> get pinned => const Stream.empty();
}

class PlatformHomeWidgets implements HomeWidgets {
  PlatformHomeWidgets() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'pinned') _pinned.add(null);
    });
  }

  static const _channel = MethodChannel('kac_gun_oldu/widgets');
  final _pinned = StreamController<void>.broadcast();

  @override
  Stream<void> get pinned => _pinned.stream;

  @override
  Future<void> publish(String snapshot) async {
    try {
      await _channel.invokeMethod<void>('publish', snapshot);
    } catch (_) {}
  }

  @override
  Future<List<WidgetMark>> takeMarks() async {
    try {
      return parseWidgetMarks(await _channel.invokeMethod<String>('takeMarks'));
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<bool> canPin() async {
    try {
      return await _channel.invokeMethod<bool>('canPin') ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<PinResult> pin({String? cardId, bool list = false}) async {
    try {
      final r = await _channel.invokeMethod<String>('pin', {'cardId': cardId, 'list': list});
      return PinResult.values.firstWhere((v) => v.name == r, orElse: () => PinResult.unsupported);
    } catch (_) {
      return PinResult.unsupported;
    }
  }

  @override
  Future<void> openPinPermission() async {
    try {
      await _channel.invokeMethod<void>('openPinPermission');
    } catch (_) {}
  }
}

/// The native side's pending marks: a JSON list of `{"id", "day"}`.
/// Anything malformed is skipped rather than failing the rest.
List<WidgetMark> parseWidgetMarks(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  final Object? list;
  try {
    list = jsonDecode(raw);
  } catch (_) {
    return const [];
  }
  if (list is! List) return const [];
  return [
    for (final m in list)
      if (m is Map && m['id'] is String && m['day'] is String && _dayKey.hasMatch(m['day'] as String))
        (id: m['id'] as String, day: m['day'] as String),
  ];
}

final _dayKey = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// Snapshot format version; the native readers ignore anything newer.
const widgetSnapshotVersion = 1;

/// Everything the widgets draw, as JSON. Colours are ARGB ints from the
/// current theme so the widgets wear the same palette as the app.
///
/// Per card: `last` (newest record, or null) and `typical` (the declared or
/// learned interval, or null while learning). The learned median only depends
/// on the gaps between records, not on today, so it holds until the next
/// edit — which publishes a fresh snapshot anyway. The widgets then apply the
/// same rules as `statsFor` (`domain/logic.dart`).
///
/// [doneButton]: whether the widgets show the "Bugün yaptım" button (a
/// setting, Ayarlar → Ana ekran widget'ı).
String widgetSnapshot(List<Card> cards, DateKey today, {bool doneButton = true}) {
  int c(Color color) => color.toARGB32();
  final t = tiers;
  return jsonEncode({
    'v': widgetSnapshotVersion,
    'doneButton': doneButton,
    'theme': {
      'dark': AppColor.current.isDark,
      'surface': c(AppColor.surface),
      'onSurface': c(AppColor.onSurface),
      'muted': c(AppColor.onSurfaceVariant),
      'outline': c(AppColor.outlineVariant),
      'primary': c(AppColor.primary),
      'onPrimary': c(AppColor.onPrimary),
    },
    'tiers': {
      for (final tier in Tier.values)
        tier.name: {
          'bg': c(t[tier]!.bg),
          'ink': c(t[tier]!.ink),
          'ring': c(t[tier]!.ring),
          'track': c(t[tier]!.track),
        },
    },
    'cards': [
      for (final card in cards)
        {
          'id': card.id,
          'name': card.name,
          'icon': iconKeyOf(card),
          'last': card.recs.isEmpty ? null : card.recs.first,
          'typical': card.every ?? typicalInterval(offsetsOf(card, today)),
        },
    ],
  });
}

/// The scheme of the links the widgets open the app with.
const appLinkScheme = 'kacgunoldu';

/// The card a widget tap asks for. Widgets open the app with
/// `kacgunoldu://app/card/<id>`. It usually arrives as the full URL, but only
/// the path is read, so a bare `/card/<id>` route works too.
String? cardIdFromLink(Uri uri) {
  final s = uri.pathSegments;
  if (s.length < 2 || s[s.length - 2] != 'card' || s.last.isEmpty) return null;
  return s.last;
}
