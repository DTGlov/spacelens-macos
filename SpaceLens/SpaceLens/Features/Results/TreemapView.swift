import SwiftUI

struct TreemapView: View {
  let items: [ScanItem]
  @Binding var selection: ScanItem.ID?
  let open: (ScanItem) -> Void

  private let layout = TreemapLayout()
  private let spacing: CGFloat = 2

  var body: some View {
    GeometryReader { proxy in
      let entries = layout.entries(
        for: items.map(\.allocatedSize),
        in: CGRect(origin: .zero, size: proxy.size)
      )

      ZStack(alignment: .topLeading) {
        ForEach(entries, id: \.index) { entry in
          let item = items[entry.index]
          TreemapTile(
            item: item,
            isSelected: selection == item.id
          ) {
            selection = item.id
          }
          .simultaneousGesture(
            TapGesture(count: 2).onEnded {
              open(item)
            }
          )
          .frame(
            width: max(entry.frame.width - spacing, 0),
            height: max(entry.frame.height - spacing, 0)
          )
          .offset(x: entry.frame.minX, y: entry.frame.minY)
        }
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Storage treemap")
  }
}

private struct TreemapTile: View {
  let item: ScanItem
  let isSelected: Bool
  let select: () -> Void

  @Environment(\.colorSchemeContrast) private var colorSchemeContrast

  var body: some View {
    Button(action: select) {
      GeometryReader { proxy in
        let classification = ItemClassification.classify(item)
        ZStack(alignment: .topLeading) {
          RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(classification.category.color.gradient)
            .overlay {
              RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(.black.opacity(colorSchemeContrast == .increased ? 0.24 : 0.12))
            }

          if proxy.size.width >= 72, proxy.size.height >= 42 {
            VStack(alignment: .leading, spacing: 2) {
              Label(item.name, systemImage: classification.category.systemImage)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
              Text(item.allocatedSize, format: .byteCount(style: .file))
                .font(.caption2)
                .monospacedDigit()
                .opacity(0.82)
            }
            .foregroundStyle(.white)
            .padding(7)
          }
        }
        .overlay {
          RoundedRectangle(cornerRadius: 5, style: .continuous)
            .strokeBorder(
              isSelected ? Color.primary : Color.primary.opacity(0.12),
              lineWidth: isSelected ? 4 : (colorSchemeContrast == .increased ? 2 : 1)
            )
        }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(item.name)
    .accessibilityValue(
      "\(ItemClassification.classify(item).category.rawValue), \(item.allocatedSize.formatted(.byteCount(style: .file)))"
    )
    .accessibilityHint("Selects this item for more details")
    .accessibilityAddTraits(isSelected ? .isSelected : [])
    .help(
      "\(item.name) — \(ItemClassification.classify(item).category.rawValue) — \(item.allocatedSize.formatted(.byteCount(style: .file)))"
    )
  }
}
