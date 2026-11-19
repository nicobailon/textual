#if os(macOS)
  import SwiftUI
  import Testing

  @testable import Textual

  @MainActor
  struct FadeInTests {
    @Test func onlyMarkedTextFadesIn() {
      var text = AttributedString("settled fresh")
      #expect(text.fadesIn == false)
      text[text.range(of: "fresh")!].textual.fadeIn = 10
      #expect(text.fadesIn)
      #expect(text[text.range(of: "settled")!].fadesIn == false)
    }

    @Test func eachArrivalIsOneStretchCoveringItsRuns() {
      var text = AttributedString("settled fresh newest")
      text[text.range(of: "fresh")!].textual.fadeIn = 10
      text[text.range(of: "newest")!].textual.fadeIn = 12
      let recorder = Recorder()
      _ = ImageRenderer(content: Self.text(text).textRenderer(recorder)).nsImage
      #expect(recorder.box.stretches.map(\.start) == [10, 12])
      #expect(recorder.box.stretches.allSatisfy { $0.rects.count == 1 && $0.rects[0].width > 0 })
      let fresh = recorder.box.stretches[0].rects[0]
      let newest = recorder.box.stretches[1].rects[0]
      #expect(fresh.maxX <= newest.minX + 0.5)
    }

    @Test func aWrappedStretchCoversEachLine() {
      var text = AttributedString("settled " + String(repeating: "fresh words ", count: 12))
      text[text.range(of: "fresh words fresh")!.lowerBound...].textual.fadeIn = 10
      let recorder = Recorder()
      _ = ImageRenderer(content: Self.text(text).textRenderer(recorder).frame(width: 160)).nsImage
      let rects = recorder.box.stretches.first?.rects ?? []
      #expect(Set(rects.map(\.minY)).count > 1, "\(rects)")
    }

    @Test func onlyMarkedRunsCarryTheirArrivalIntoTheText() {
      var text = AttributedString("settled fresh")
      text[text.range(of: "fresh")!].textual.fadeIn = 10
      let recorder = Recorder()
      _ = ImageRenderer(content: Self.text(text).textRenderer(recorder)).nsImage
      #expect(recorder.box.starts.contains(nil), "\(recorder.box.starts)")
      #expect(recorder.box.starts.contains(10), "\(recorder.box.starts)")
    }

    @Test func markedTextRenders() {
      var text = AttributedString("settled fresh")
      text[text.range(of: "fresh")!].textual.fadeIn = ProcessInfo.processInfo.systemUptime
      let renderer = ImageRenderer(content: TextFragment(text).frame(width: 320).coordinateSpace(.textContainer))
      #expect(renderer.nsImage != nil)
    }

    private static func text(_ text: AttributedString) -> Text {
      TextFragment<AttributedString>.TextBuilder(text, environment: TextEnvironmentValues(dynamicTypeSize: .large)).text
    }
  }

  private struct Recorder: TextRenderer {
    final class Box {
      var starts: [TimeInterval?] = []
      var stretches: [Text.Layout.FadeInStretch] = []
    }
    let box = Box()

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
      box.stretches = layout.fadeInStretches(at: .zero)
      for line in layout {
        for run in line {
          box.starts.append(run[FadeInAttribute.self]?.start)
        }
      }
    }
  }
#endif
