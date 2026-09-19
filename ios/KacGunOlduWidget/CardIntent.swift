import AppIntents
import WidgetKit

/// A card, as the "Kart" widget's settings list it.
struct CardEntity: AppEntity {
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Kart"
  static var defaultQuery = CardQuery()

  let id: String
  let name: String

  var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

struct CardQuery: EntityQuery {
  private func all() -> [CardEntity] {
    (WidgetSnapshot.load()?.ordered(on: Date()) ?? []).map { CardEntity(id: $0.id, name: $0.name) }
  }

  func entities(for identifiers: [CardEntity.ID]) async throws -> [CardEntity] {
    all().filter { identifiers.contains($0.id) }
  }

  func suggestedEntities() async throws -> [CardEntity] { all() }
}

/// The widgets' "Bugün yaptım" button. Runs in the widget, which redraws
/// with the card done today; the app records it when next opened.
struct MarkDoneIntent: AppIntent {
  static var title: LocalizedStringResource = "Bugün yaptım"
  static var isDiscoverable = false

  @Parameter(title: "Kart")
  var cardId: String

  init() {}

  init(cardId: String) {
    self.cardId = cardId
  }

  func perform() async throws -> some IntentResult {
    WidgetSnapshot.markDone(cardId)
    return .result()
  }
}

/// "Kart" widget settings (long-press → Edit Widget): which card it shows.
/// Left empty it follows the most urgent card, day by day.
struct SelectCardIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Kart seç"
  static var description = IntentDescription("Widget'ın göstereceği kart. Boş bırakırsan her gün sırası en yakın kartı gösterir.")

  @Parameter(title: "Kart")
  var card: CardEntity?
}
