#if os(macOS)
  import AppKit
  import QuartzCore

  // A cover can't know the exact color under the text (the window tints its background with the wallpaper), so it
  // blends instead of painting: lighten with a near-white over light text areas and darken with a near-black over
  // dark ones leaves the background as it is and takes the glyphs to almost the background.
  final class FadeInCoverView: NSView {
    private var covers: [TimeInterval: CAShapeLayer] = [:]

    override init(frame: NSRect) {
      super.init(frame: frame)
      wantsLayer = true
      layerUsesCoreImageFilters = true
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override var isFlipped: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    func show(_ stretches: [Text.Layout.FadeInStretch], dark: Bool) {
      guard let layer else { return }
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      let starts = Set(stretches.map(\.start))
      for (start, cover) in covers where starts.contains(start) == false {
        cover.removeFromSuperlayer()
        covers[start] = nil
      }
      for stretch in stretches {
        let cover = covers[stretch.start] ?? makeCover(start: stretch.start, in: layer)
        cover.fillColor = CGColor(gray: dark ? 0.2 : 0.97, alpha: 1)
        cover.compositingFilter = CIFilter(name: dark ? "CIDarkenBlendMode" : "CILightenBlendMode")
        let path = CGMutablePath()
        path.addRects(stretch.rects.map { $0.insetBy(dx: -1, dy: -1) })
        cover.path = path
      }
      CATransaction.commit()
    }

    private func makeCover(start: TimeInterval, in layer: CALayer) -> CAShapeLayer {
      let cover = CAShapeLayer()
      cover.opacity = 0
      let fade = CABasicAnimation(keyPath: "opacity")
      fade.fromValue = 1
      fade.toValue = 0
      fade.duration = FadeInCovers.duration
      fade.timingFunction = CAMediaTimingFunction(name: .easeOut)
      fade.fillMode = .backwards
      let age = ProcessInfo.processInfo.systemUptime - start
      fade.beginTime = layer.convertTime(CACurrentMediaTime() - age, from: nil)
      cover.add(fade, forKey: "fade")
      layer.addSublayer(cover)
      covers[start] = cover
      return cover
    }
  }
#endif
