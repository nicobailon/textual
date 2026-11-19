#if os(macOS)
  import SwiftUI

  struct FadeInCovers: NSViewRepresentable {
    nonisolated static let duration: TimeInterval = 0.18

    let stretches: [Text.Layout.FadeInStretch]

    func makeNSView(context: Context) -> FadeInCoverView {
      FadeInCoverView()
    }

    func updateNSView(_ view: FadeInCoverView, context: Context) {
      view.show(stretches, dark: context.environment.colorScheme == .dark)
    }
  }
#endif
