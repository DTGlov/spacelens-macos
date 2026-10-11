import CoreGraphics

struct TreemapLayout {
  struct Entry: Equatable {
    let index: Int
    let frame: CGRect
  }

  func entries(for sizes: [Int64], in bounds: CGRect) -> [Entry] {
    let weightedIndices = sizes.indices.filter { sizes[$0] > 0 }
    guard !weightedIndices.isEmpty, bounds.width > 0, bounds.height > 0 else { return [] }

    var entries: [Entry] = []
    layout(
      indices: Array(weightedIndices),
      sizes: sizes,
      in: bounds,
      entries: &entries
    )
    return entries.sorted { $0.index < $1.index }
  }

  private func layout(
    indices: [Int],
    sizes: [Int64],
    in bounds: CGRect,
    entries: inout [Entry]
  ) {
    guard let firstIndex = indices.first else { return }
    guard indices.count > 1 else {
      entries.append(Entry(index: firstIndex, frame: bounds))
      return
    }

    let total = indices.reduce(Int64.zero) { $0 + sizes[$1] }
    let splitIndex = bestSplitIndex(for: indices, sizes: sizes, total: total)
    let leadingIndices = Array(indices[..<splitIndex])
    let trailingIndices = Array(indices[splitIndex...])
    let leadingTotal = leadingIndices.reduce(Int64.zero) { $0 + sizes[$1] }
    let fraction = CGFloat(leadingTotal) / CGFloat(total)

    let leadingBounds: CGRect
    let trailingBounds: CGRect
    if bounds.width >= bounds.height {
      let splitWidth = bounds.width * fraction
      leadingBounds = CGRect(
        x: bounds.minX,
        y: bounds.minY,
        width: splitWidth,
        height: bounds.height
      )
      trailingBounds = CGRect(
        x: bounds.minX + splitWidth,
        y: bounds.minY,
        width: bounds.width - splitWidth,
        height: bounds.height
      )
    } else {
      let splitHeight = bounds.height * fraction
      leadingBounds = CGRect(
        x: bounds.minX,
        y: bounds.minY,
        width: bounds.width,
        height: splitHeight
      )
      trailingBounds = CGRect(
        x: bounds.minX,
        y: bounds.minY + splitHeight,
        width: bounds.width,
        height: bounds.height - splitHeight
      )
    }

    layout(indices: leadingIndices, sizes: sizes, in: leadingBounds, entries: &entries)
    layout(indices: trailingIndices, sizes: sizes, in: trailingBounds, entries: &entries)
  }

  private func bestSplitIndex(for indices: [Int], sizes: [Int64], total: Int64) -> Int {
    var cumulativeSize: Int64 = 0
    var bestIndex = 1
    var smallestDifference = Int64.max

    for index in 1..<indices.count {
      cumulativeSize += sizes[indices[index - 1]]
      let difference = abs(total - (cumulativeSize * 2))
      if difference < smallestDifference {
        smallestDifference = difference
        bestIndex = index
      }
    }
    return bestIndex
  }
}
