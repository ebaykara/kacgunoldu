import SwiftUI
import WidgetKit

/// Home and lock screen widgets. They draw from the snapshot the app writes
/// to the App Group; tapping a card opens it in the app
/// (kacgunoldu://app/card/<id>, handled by CardStore through Flutter's deep
/// linking).
@main
struct KacGunOlduWidgets: WidgetBundle {
  var body: some Widget {
    CardWidget()
    CardListWidget()
  }
}

struct CardsEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshot?
  /// The card picked in the widget's settings; nil follows the most urgent.
  let cardId: String?

  var cards: [WidgetCard] { snapshot?.ordered(on: date) ?? [] }

  var card: WidgetCard? {
    let all = cards
    return all.first { $0.id == cardId } ?? all.first
  }
}

/// Today, then every coming midnight for a week: day counts move at
/// midnight, and the app reloads the timeline whenever the cards change.
private func makeTimeline(snapshot: WidgetSnapshot?, cardId: String?) -> Timeline<CardsEntry> {
  let calendar = Calendar.current
  let now = Date()
  var entries = [CardsEntry(date: now, snapshot: snapshot, cardId: cardId)]
  var day = calendar.startOfDay(for: now)
  for _ in 0..<7 {
    guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
    day = next
    entries.append(CardsEntry(date: day, snapshot: snapshot, cardId: cardId))
  }
  return Timeline(entries: entries, policy: .atEnd)
}

// MARK: - Kart

struct CardProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> CardsEntry {
    CardsEntry(date: Date(), snapshot: WidgetSnapshot.sample, cardId: nil)
  }

  func snapshot(for configuration: SelectCardIntent, in context: Context) async -> CardsEntry {
    // The widget gallery shows the sample until there are real cards.
    let real = WidgetSnapshot.load()
    let snapshot = context.isPreview && (real?.cards.isEmpty ?? true) ? WidgetSnapshot.sample : real
    return CardsEntry(date: Date(), snapshot: snapshot, cardId: configuration.card?.id)
  }

  func timeline(for configuration: SelectCardIntent, in context: Context) async -> Timeline<CardsEntry> {
    makeTimeline(snapshot: WidgetSnapshot.load(), cardId: configuration.card?.id)
  }
}

struct CardWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: "CardWidget", intent: SelectCardIntent.self, provider: CardProvider()) { entry in
      CardWidgetView(entry: entry)
    }
    .configurationDisplayName("Kart")
    .description("Tek bir kartın kaç gün olduğunu gösterir.")
    .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline])
  }
}

struct CardWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: CardsEntry

  var body: some View {
    let theme = entry.snapshot?.theme ?? .kiremit
    if let snapshot = entry.snapshot, let card = entry.card {
      switch family {
      case .accessoryCircular:
        CircularView(card: card)
          .containerBackground(for: .widget) { AccessoryWidgetBackground() }
          .widgetURL(card.link)
      case .accessoryRectangular:
        RectangularView(card: card)
          .containerBackground(for: .widget) { Color.clear }
          .widgetURL(card.link)
      case .accessoryInline:
        InlineView(card: card)
          .containerBackground(for: .widget) { Color.clear }
          .widgetURL(card.link)
      default:
        let colors = snapshot.colors(card)
        CardTileView(card: card, colors: colors, doneButton: snapshot.doneButton)
          .containerBackground(for: .widget) { colors.bg }
          .widgetURL(card.link)
      }
    } else {
      switch family {
      case .accessoryCircular, .accessoryRectangular, .accessoryInline:
        Text("Kaç gün oldu?")
          .containerBackground(for: .widget) { Color.clear }
      default:
        EmptyStateView(theme: theme, hasSnapshot: entry.snapshot != nil)
          .containerBackground(for: .widget) { theme.surface }
      }
    }
  }
}

// MARK: - Kartlar

struct CardListProvider: TimelineProvider {
  func placeholder(in context: Context) -> CardsEntry {
    CardsEntry(date: Date(), snapshot: WidgetSnapshot.sample, cardId: nil)
  }

  func getSnapshot(in context: Context, completion: @escaping (CardsEntry) -> Void) {
    let real = WidgetSnapshot.load()
    let snapshot = context.isPreview && (real?.cards.isEmpty ?? true) ? WidgetSnapshot.sample : real
    completion(CardsEntry(date: Date(), snapshot: snapshot, cardId: nil))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<CardsEntry>) -> Void) {
    completion(makeTimeline(snapshot: WidgetSnapshot.load(), cardId: nil))
  }
}

struct CardListWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "CardListWidget", provider: CardListProvider()) { entry in
      CardListWidgetView(entry: entry)
    }
    .configurationDisplayName("Kartlar")
    .description("Sırası en yakın kartlar bir arada.")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

struct CardListWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: CardsEntry

  var body: some View {
    let theme = entry.snapshot?.theme ?? .kiremit
    Group {
      if let snapshot = entry.snapshot, !entry.cards.isEmpty {
        CardListView(snapshot: snapshot, cards: entry.cards, large: family == .systemLarge)
      } else {
        EmptyStateView(theme: theme, hasSnapshot: entry.snapshot != nil)
      }
    }
    .containerBackground(for: .widget) { theme.surface }
  }
}

// MARK: - Örnek

extension WidgetSnapshot {
  /// The widget gallery's preview, in Kiremit, before there are real cards.
  static var sample: WidgetSnapshot {
    let calendar = Calendar.current
    func ago(_ days: Int) -> DateComponents {
      let d = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
      return calendar.dateComponents([.year, .month, .day], from: d)
    }
    func c(_ v: UInt32) -> Color { Color(argb: v) }
    return WidgetSnapshot(
      theme: .kiremit,
      tiers: [
        .fresh: TierColors(bg: c(0xFFE7F0DB), ink: c(0xFF1F2A14), ring: c(0xFF6B8F4E), track: c(0xFF1F2A14).opacity(0.13)),
        .calm: TierColors(bg: c(0xFFFFFDFA), ink: c(0xFF241F1B), ring: c(0xFFC98A6B), track: c(0xFF241F1B).opacity(0.10)),
        .soon: TierColors(bg: c(0xFFFFE2D5), ink: c(0xFF3A0C00), ring: c(0xFFB8492A), track: c(0xFF3A0C00).opacity(0.14)),
        .late: TierColors(bg: c(0xFFB8492A), ink: c(0xFFFFF3EA), ring: c(0xFFFFD7C4), track: c(0xFFFFF3EA).opacity(0.28)),
      ],
      cards: [
        RawCard(id: "s1", name: "Saçımı kestirdim", icon: "scissors", last: ago(24), typical: 30),
        RawCard(id: "s2", name: "Bitkileri suladım", icon: "plant", last: ago(9), typical: 4),
        RawCard(id: "s3", name: "Annemi aradım", icon: "phone", last: ago(6), typical: 7),
        RawCard(id: "s4", name: "Diş hekimi", icon: "tooth", last: ago(40), typical: 180),
        RawCard(id: "s5", name: "Spor yaptım", icon: "gym", last: ago(1), typical: 3),
        RawCard(id: "s6", name: "Arabayı yıkattım", icon: "car", last: ago(12), typical: 21),
      ]
    )
  }
}
