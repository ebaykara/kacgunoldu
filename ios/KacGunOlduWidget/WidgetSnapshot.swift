import Foundation
import SwiftUI

/// The App Group both the app and this extension can read. The app writes the
/// snapshot here (AppDelegate, "kac_gun_oldu/widgets" channel).
let appGroup = "group.com.emalabs.kacgunoldu"
let snapshotKey = "widgets.snapshot"
/// Days marked with the widgets' "Bugün yaptım" button, waiting for the app.
let marksKey = "widgets.marks"

/// What the widgets draw, as the app last wrote it
/// (lib/services/home_widgets.dart).
///
/// It holds each card's last record and interval, never a day count: the
/// count is worked out here against the entry's date, so a widget is right
/// after midnight without the app being opened. The rules are the app's own
/// (`statsFor` in lib/domain/logic.dart) — keep the two in step.
struct WidgetSnapshot {
  let theme: ThemeColors
  /// Show the "Bugün yaptım" button (Ayarlar → Ana ekran widget'ı).
  var doneButton = true
  let tiers: [Tier: TierColors]
  let cards: [RawCard]

  struct RawCard {
    let id: String
    let name: String
    let icon: String
    let last: DateComponents?
    let typical: Int?
  }

  static func load() -> WidgetSnapshot? {
    guard
      let raw = UserDefaults(suiteName: appGroup)?.string(forKey: snapshotKey),
      let data = raw.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return nil }
    return parse(json)
  }

  static func parse(_ o: [String: Any]) -> WidgetSnapshot? {
    if let v = o["v"] as? Int, v > 1 { return nil }
    guard let t = o["theme"] as? [String: Any], let tierJson = o["tiers"] as? [String: Any] else {
      return nil
    }
    func color(_ d: [String: Any], _ key: String) -> Color { Color(argb: (d[key] as? NSNumber)?.uint32Value ?? 0xFF000000) }
    let theme = ThemeColors(
      surface: color(t, "surface"),
      onSurface: color(t, "onSurface"),
      muted: color(t, "muted"),
      primary: color(t, "primary"),
      onPrimary: color(t, "onPrimary")
    )
    var tiers: [Tier: TierColors] = [:]
    for tier in Tier.allCases {
      guard let c = tierJson[tier.rawValue] as? [String: Any] else { continue }
      tiers[tier] = TierColors(bg: color(c, "bg"), ink: color(c, "ink"), ring: color(c, "ring"), track: color(c, "track"))
    }
    let cards = (o["cards"] as? [[String: Any]] ?? []).compactMap { c -> RawCard? in
      guard let id = c["id"] as? String, !id.isEmpty else { return nil }
      let typical = (c["typical"] as? NSNumber)?.intValue
      return RawCard(
        id: id,
        name: c["name"] as? String ?? "",
        icon: c["icon"] as? String ?? "spark",
        last: (c["last"] as? String).flatMap(dateKey),
        typical: typical.flatMap { $0 > 0 ? $0 : nil }
      )
    }
    return WidgetSnapshot(theme: theme, doneButton: o["doneButton"] as? Bool ?? true, tiers: tiers, cards: cards)
  }

  /// A widget's "Bugün yaptım": the card is done today. The snapshot's
  /// `last` moves to today so the widget redraws at once; the mark waits
  /// under `marksKey` until the app records it (CardStore._takeWidgetMarks).
  static func markDone(_ cardId: String, on date: Date = Date()) {
    guard let defaults = UserDefaults(suiteName: appGroup) else { return }
    let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
    let day = String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    if let raw = defaults.string(forKey: snapshotKey),
      let data = raw.data(using: .utf8),
      var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      var cards = json["cards"] as? [[String: Any]]
    {
      for i in cards.indices where cards[i]["id"] as? String == cardId {
        let last = cards[i]["last"] as? String ?? ""
        if last < day { cards[i]["last"] = day }
      }
      json["cards"] = cards
      if let out = try? JSONSerialization.data(withJSONObject: json), let text = String(data: out, encoding: .utf8) {
        defaults.set(text, forKey: snapshotKey)
      }
    }
    var marks: [[String: String]] = []
    if let raw = defaults.string(forKey: marksKey), let data = raw.data(using: .utf8),
      let list = try? JSONSerialization.jsonObject(with: data) as? [[String: String]]
    {
      marks = list
    }
    marks.append(["id": cardId, "day": day])
    if let out = try? JSONSerialization.data(withJSONObject: marks), let text = String(data: out, encoding: .utf8) {
      defaults.set(text, forKey: marksKey)
    }
  }

  /// Overdue first, then everything else, each by how far along it is.
  func ordered(on date: Date) -> [WidgetCard] {
    let all = cards.map { WidgetCard($0, on: date) }
    let byRatio: (WidgetCard, WidgetCard) -> Bool = { $0.ratio > $1.ratio }
    return all.filter(\.isLate).sorted(by: byRatio) + all.filter { !$0.isLate }.sorted(by: byRatio)
  }

  func colors(_ card: WidgetCard) -> TierColors {
    tiers[card.tier] ?? TierColors(bg: theme.surface, ink: theme.onSurface, ring: theme.primary, track: theme.onSurface.opacity(0.1))
  }

  /// `YYYY-MM-DD` → calendar date.
  private static func dateKey(_ s: String) -> DateComponents? {
    let parts = s.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3 else { return nil }
    return DateComponents(year: parts[0], month: parts[1], day: parts[2])
  }
}

enum Tier: String, CaseIterable { case fresh, calm, soon, late }

struct TierColors {
  let bg: Color
  let ink: Color
  let ring: Color
  let track: Color
}

struct ThemeColors {
  let surface: Color
  let onSurface: Color
  let muted: Color
  let primary: Color
  let onPrimary: Color

  /// Kiremit, the default theme — before the app has ever written a snapshot.
  static let kiremit = ThemeColors(
    surface: Color(argb: 0xFFFBF5F0),
    onSurface: Color(argb: 0xFF241F1B),
    muted: Color(argb: 0xFF87786C),
    primary: Color(argb: 0xFFB8492A),
    onPrimary: Color(argb: 0xFFFFF3EA)
  )
}

/// One card on a given day, with everything the app's `statsFor` derives.
struct WidgetCard: Identifiable {
  let id: String
  let name: String
  let icon: String
  let hasRecord: Bool
  let days: Int
  let ratio: Double
  let isLate: Bool
  let tier: Tier
  /// Ring fill, 0.03–1.
  let progress: Double
  /// Days left in the usual interval; negative past it, nil while learning.
  let remaining: Int?

  init(_ raw: WidgetSnapshot.RawCard, on date: Date) {
    id = raw.id
    name = raw.name
    icon = raw.icon
    let calendar = Calendar.current
    if let last = raw.last, let lastDate = calendar.date(from: last) {
      hasRecord = true
      let d = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: calendar.startOfDay(for: date)).day ?? 0
      days = max(0, d)
    } else {
      hasRecord = false
      days = 0
    }
    let typical = raw.typical
    if let typical, typical != 0 {
      ratio = Double(days) / Double(typical)
    } else {
      ratio = min(0.95, Double(days) / 30)
    }
    // `+1` keeps short-interval cards from flagging on a single late day.
    isLate = typical != nil && hasRecord && Double(days) > Double(typical ?? 0) * 1.25 + 1
    tier = isLate ? .late : ratio > 0.95 ? .soon : ratio < 0.5 ? .fresh : .calm
    progress = Double(min(100, max(3, Int((ratio * 100).rounded())))) / 100
    remaining = typical == nil || !hasRecord ? nil : typical! - days
  }

  /// The card's one status line — `CardStatus` in lib/widgets/card_status.dart.
  var status: String {
    guard hasRecord else { return "Henüz işaretlenmedi" }
    guard let r = remaining else { return "Ritim öğreniliyor" }
    if r > 0 { return "\(r) gün kaldı" }
    if r == 0 { return "Bugün sırası" }
    return "\(-r) gün geçti"
  }

  /// Due today or past due: drawn in the accent, bold.
  var urgent: Bool { (remaining ?? 1) <= 0 }

  /// Already recorded today: the "Bugün yaptım" button shows it's done.
  var doneToday: Bool { hasRecord && days == 0 }

  var dayText: String { hasRecord ? "\(days)" : "—" }
  var unitText: String { hasRecord ? "gün oldu" : "kayıt yok" }

  var link: URL {
    let id = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
    return URL(string: "kacgunoldu://app/card/\(id)")!
  }

  /// `CardStatus.color`: the accent when urgent (the ink itself on the solid
  /// overdue card), otherwise the ink, quietened.
  func statusColor(_ c: TierColors) -> Color {
    guard urgent else { return c.ink.opacity(0.6) }
    return tier == .late ? c.ink : c.ring
  }
}

extension Color {
  init(argb: UInt32) {
    self.init(
      .sRGB,
      red: Double((argb >> 16) & 0xFF) / 255,
      green: Double((argb >> 8) & 0xFF) / 255,
      blue: Double(argb & 0xFF) / 255,
      opacity: Double((argb >> 24) & 0xFF) / 255
    )
  }
}
