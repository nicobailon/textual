import SwiftUI

struct FadeIn: ViewModifier {
  nonisolated static let duration: TimeInterval = 0.18
  static let step: TimeInterval = 0.06

  let newest: TimeInterval
  let gap: TimeInterval?
  @State private var now = ProcessInfo.processInfo.systemUptime

  // A clock stepped by a task, not an animation: a renderer that changes every display frame re-measures the window
  // up to its root. The first step waits out a pause longer than the stream's own gap between words, so a steady
  // stream redraws only when its words land; a pause adds a few steps, then stops on `newest + duration`. Drawing a
  // step ahead shows the newest words at once.
  func body(content: Content) -> some View {
    let end = newest + Self.duration
    content
      .textRenderer(FadeInRenderer(now: max(now, min(newest + Self.step, end))))
      .task(id: newest) {
        var wait = min(max((gap ?? 0) * 1.5, Self.step), 2 * Self.step)
        while now < end {
          try? await Task.sleep(for: .seconds(wait))
          if Task.isCancelled { return }
          now = min(ProcessInfo.processInfo.systemUptime, end)
          wait = Self.step
        }
      }
  }
}
