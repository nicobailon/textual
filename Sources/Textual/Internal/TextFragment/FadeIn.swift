import SwiftUI

struct FadeIn: ViewModifier {
  nonisolated static let duration: TimeInterval = 0.18

  let newest: TimeInterval
  @State private var appeared = false

  // The clock runs once from the newest arrival, so nothing draws once it ends, and a run that arrived earlier keeps
  // fading where it was when a newer one lands. Appearing counts as a trigger, so a new paragraph fades in too.
  func body(content: Content) -> some View {
    content
      .keyframeAnimator(initialValue: newest, trigger: appeared ? newest : -1) { content, now in
        content.textRenderer(FadeInRenderer(now: now))
      } keyframes: { _ in
        let end = newest + Self.duration
        let now = min(ProcessInfo.processInfo.systemUptime, end)
        MoveKeyframe(now)
        LinearKeyframe(end, duration: max(end - now, 0.001))
      }
      .onAppear { appeared = true }
  }
}
