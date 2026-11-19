import SwiftUI

struct FadeInRenderer: TextRenderer {
  var now: TimeInterval

  func draw(layout: Text.Layout, in context: inout GraphicsContext) {
    for line in layout {
      guard line.contains(where: { opacity(of: $0) < 1 }) else {
        context.draw(line)
        continue
      }
      for run in line {
        let opacity = opacity(of: run)
        if opacity < 1 {
          var faded = context
          faded.opacity = opacity
          faded.draw(run)
        } else {
          context.draw(run)
        }
      }
    }
  }

  private func opacity(of run: Text.Layout.Run) -> Double {
    run[FadeInAttribute.self].map { Self.opacity(since: $0.start, now: now) } ?? 1
  }

  static func opacity(since start: TimeInterval, now: TimeInterval) -> Double {
    now >= start + FadeIn.duration ? 1 : UnitCurve.easeOut.value(at: max(now - start, 0) / FadeIn.duration)
  }
}
