import SwiftUI
import UIKit
import WidgetKit

/// The day count's face — the app's display serif, bundled in this extension.
func serif(_ size: CGFloat) -> Font { .custom("InstrumentSerif-Regular", size: size) }

/// A card's glyph, generated from the app's own icons (tool/gen_widget_glyphs.py).
func glyph(_ key: String) -> Image {
  let name = "glyph_\(key)"
  return Image(UIImage(named: name) != nil ? name : "glyph_spark").renderingMode(.template)
}

/// The rhythm ring with the card's glyph inside (lib/widgets/rhythm_ring.dart):
/// a track and an arc from 12 o'clock, stroke 6/52 of the size.
struct RingGlyph: View {
  let card: WidgetCard
  let colors: TierColors
  let size: CGFloat

  var body: some View {
    let stroke = size * 6 / 52
    ZStack {
      Circle().stroke(colors.track, lineWidth: stroke)
      Circle()
        .trim(from: 0, to: card.progress)
        .stroke(colors.ring, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
        .rotationEffect(.degrees(-90))
        .widgetAccentable()
      glyph(card.icon)
        .resizable()
        .scaledToFit()
        .frame(width: size * 0.45, height: size * 0.45)
        .foregroundStyle(colors.ink)
    }
    .padding(stroke / 2)
    .frame(width: size, height: size)
  }
}

/// "Bugün yaptım": a soft circle with a check, filled once the card is done
/// today (tapping it again changes nothing).
struct DoneButton: View {
  let card: WidgetCard
  let colors: TierColors
  let size: CGFloat

  var body: some View {
    Button(intent: MarkDoneIntent(cardId: card.id)) {
      ZStack {
        Circle().fill(card.doneToday ? colors.ring : colors.ink.opacity(0.1))
        glyph("check")
          .resizable()
          .scaledToFit()
          .frame(width: size * 0.55, height: size * 0.55)
          .foregroundStyle(card.doneToday ? colors.bg : colors.ink)
      }
      .frame(width: size, height: size)
    }
    .buttonStyle(.plain)
    .disabled(card.doneToday)
    .accessibilityLabel(card.doneToday ? "Bugün yapıldı" : "Bugün yaptım")
  }
}

// MARK: - Kart (small)

/// The app's card tile: ring, name, the day count on the bottom edge with
/// `gün oldu` on its baseline, and one status line.
struct CardTileView: View {
  let card: WidgetCard
  let colors: TierColors
  var doneButton = true

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top) {
        RingGlyph(card: card, colors: colors, size: 34)
        Spacer(minLength: 0)
        if doneButton { DoneButton(card: card, colors: colors, size: 32) }
      }
      Text(card.name)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(colors.ink)
        .lineLimit(1)
        .padding(.top, 8)
      Spacer(minLength: 0)
      HStack(alignment: .firstTextBaseline, spacing: 4) {
        Text(card.dayText)
          .font(serif(44))
          .foregroundStyle(colors.ink)
          .lineLimit(1)
          .minimumScaleFactor(0.5)
          .widgetAccentable()
        Text(card.unitText)
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(colors.ink.opacity(0.72))
          .lineLimit(1)
          .fixedSize()
      }
      Text(card.status)
        .font(.system(size: 12, weight: card.urgent ? .bold : .medium))
        .foregroundStyle(card.statusColor(colors))
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .accessibilityElement(children: .combine)
  }
}

// MARK: - Kilit ekranı

struct CircularView: View {
  let card: WidgetCard

  var body: some View {
    Gauge(value: card.progress) {
      glyph(card.icon).resizable().scaledToFit()
    } currentValueLabel: {
      Text(card.dayText).font(serif(22))
    }
    .gaugeStyle(.accessoryCircular)
    .accessibilityLabel("\(card.name), \(card.dayText) \(card.unitText)")
  }
}

struct RectangularView: View {
  let card: WidgetCard

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 4) {
        glyph(card.icon).resizable().scaledToFit().frame(width: 12, height: 12)
        Text(card.name).font(.system(size: 14, weight: .semibold)).lineLimit(1)
      }
      HStack(alignment: .firstTextBaseline, spacing: 3) {
        Text(card.dayText).font(serif(26)).widgetAccentable()
        Text(card.unitText).font(.system(size: 12, weight: .medium))
      }
      Text(card.status).font(.system(size: 12, weight: card.urgent ? .bold : .regular)).lineLimit(1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
  }
}

struct InlineView: View {
  let card: WidgetCard

  var body: some View {
    Label {
      Text("\(card.name): \(card.dayText) \(card.unitText)")
    } icon: {
      glyph(card.icon)
    }
  }
}

// MARK: - Kartlar (medium, large)

/// Header, then the most urgent cards: a 2×2 grid on medium, rows on large.
struct CardListView: View {
  let snapshot: WidgetSnapshot
  let cards: [WidgetCard]
  let large: Bool

  var body: some View {
    let theme = snapshot.theme
    let late = cards.filter(\.isLate).count
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .center) {
        Text("Kaç gün oldu?")
          .font(serif(21))
          .foregroundStyle(theme.onSurface)
          .lineLimit(1)
        Spacer(minLength: 6)
        if late > 0 {
          Text("\(late) kart gecikti")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(theme.onPrimary)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Capsule().fill(theme.primary))
            .widgetAccentable()
        }
      }
      if large {
        VStack(spacing: 5) {
          ForEach(cards.prefix(6)) { card in
            HStack(spacing: 6) {
              Link(destination: card.link) { RowView(card: card, colors: snapshot.colors(card)) }
              if snapshot.doneButton { DoneButton(card: card, colors: snapshot.colors(card), size: 34) }
            }
          }
        }
      } else {
        let shown = Array(cards.prefix(4))
        Grid(horizontalSpacing: 6, verticalSpacing: 6) {
          ForEach(0..<((shown.count + 1) / 2), id: \.self) { r in
            GridRow {
              ForEach(shown[(r * 2)..<min(r * 2 + 2, shown.count)]) { card in
                Link(destination: card.link) { CellView(card: card, colors: snapshot.colors(card)) }
              }
            }
          }
        }
      }
      Spacer(minLength: 0)
    }
  }
}

/// A full row (large): ring, name over status, the count right-aligned with
/// `gün oldu` under it — the app's list row.
struct RowView: View {
  let card: WidgetCard
  let colors: TierColors

  var body: some View {
    HStack(spacing: 10) {
      RingGlyph(card: card, colors: colors, size: 32)
      VStack(alignment: .leading, spacing: 1) {
        Text(card.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(colors.ink).lineLimit(1)
        Text(card.status)
          .font(.system(size: 12, weight: card.urgent ? .bold : .medium))
          .foregroundStyle(card.statusColor(colors))
          .lineLimit(1)
      }
      Spacer(minLength: 4)
      VStack(alignment: .trailing, spacing: -2) {
        Text(card.dayText).font(serif(28)).foregroundStyle(colors.ink).lineLimit(1).widgetAccentable()
        Text(card.unitText).font(.system(size: 9.5, weight: .medium)).foregroundStyle(colors.ink.opacity(0.6)).lineLimit(1)
      }
      .frame(minWidth: 48, alignment: .trailing)
    }
    .padding(.leading, 6)
    .padding(.trailing, 12)
    .frame(height: 42)
    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(colors.bg))
    .accessibilityElement(children: .combine)
  }
}

/// A compact cell (medium): ring, name over status, the bare count.
struct CellView: View {
  let card: WidgetCard
  let colors: TierColors

  var body: some View {
    HStack(spacing: 7) {
      RingGlyph(card: card, colors: colors, size: 28)
      VStack(alignment: .leading, spacing: 0) {
        Text(card.name).font(.system(size: 12.5, weight: .semibold)).foregroundStyle(colors.ink).lineLimit(1)
        Text(card.status)
          .font(.system(size: 10.5, weight: card.urgent ? .bold : .medium))
          .foregroundStyle(card.statusColor(colors))
          .lineLimit(1)
      }
      Spacer(minLength: 2)
      Text(card.dayText).font(serif(24)).foregroundStyle(colors.ink).lineLimit(1).fixedSize().widgetAccentable()
    }
    .padding(.leading, 6)
    .padding(.trailing, 9)
    .frame(maxWidth: .infinity)
    .frame(height: 44)
    .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(colors.bg))
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(card.name), \(card.dayText) \(card.unitText), \(card.status)")
  }
}

/// Nothing to show yet: no cards, or the app not opened since installing.
struct EmptyStateView: View {
  let theme: ThemeColors
  let hasSnapshot: Bool

  var body: some View {
    VStack(spacing: 8) {
      glyph("spark").resizable().scaledToFit().frame(width: 24, height: 24).foregroundStyle(theme.primary)
      Text(hasSnapshot ? "İlk kartını oluştur" : "Kartlarını görmek için uygulamayı aç")
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(theme.onSurface)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
