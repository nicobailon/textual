import SwiftUI

struct FadeIn: ViewModifier {
  nonisolated static let duration: TimeInterval = 0.18
  static let step: TimeInterval = 0.05

  let newest: TimeInterval
  @State private var now = ProcessInfo.processInfo.systemUptime

  // A clock stepped by a task, not an animation: a renderer that changes every display frame re-measures the window
  // up to its root. A stream faster than the step redraws only when its words land; a slower one adds a few steps,
  // then stops on `newest + duration`. Drawing a step ahead shows the newest words at once.
  func body(content: Content) -> some View {
    let end = newest + Self.duration
    content
      .textRenderer(FadeInRenderer(now: max(now, min(newest + Self.step, end))))
      .task(id: newest) {
        while now < end {
          try? await Task.sleep(for: .seconds(Self.step))
          if Task.isCancelled { return }
          now = min(ProcessInfo.processInfo.systemUptime, end)
        }
      }
  }
}
