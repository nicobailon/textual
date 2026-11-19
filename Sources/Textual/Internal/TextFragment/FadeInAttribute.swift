import SwiftUI

struct FadeInAttribute: TextAttribute {
  var start: TimeInterval
}

extension AttributedStringProtocol {
  var fadesIn: Bool {
    runs[AttributeScopes.TextualAttributes.FadeInAttribute.self].contains { $0.0 != nil }
  }
}

extension Text.Layout {
  struct FadeInStretch: Equatable {
    var start: TimeInterval
    var rects: [CGRect]
  }

  func fadeInStretches(at origin: CGPoint) -> [FadeInStretch] {
    var stretches: [FadeInStretch] = []
    for line in self {
      for run in line {
        guard let start = run[FadeInAttribute.self]?.start else { continue }
        let rect = run.typographicBounds.rect.offsetBy(dx: origin.x, dy: origin.y)
        if let index = stretches.firstIndex(where: { $0.start == start }) {
          stretches[index].rects.append(rect)
        } else {
          stretches.append(FadeInStretch(start: start, rects: [rect]))
        }
      }
    }
    return stretches
  }
}
