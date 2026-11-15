#if TEXTUAL_ENABLE_TEXT_SELECTION
  import SwiftUI

  protocol TextLayoutCollection {
    var layouts: [any TextLayout] { get }
    // A selection area's texts are separate views: their words would run together when copied.
    var separatesLayouts: Bool { get }

    func isEqual(to other: any TextLayoutCollection) -> Bool
    func needsPositionReconciliation(with other: any TextLayoutCollection) -> Bool
    func index(of layout: Text.Layout) -> Int?
  }

  struct AnyTextLayoutCollection: TextLayoutCollection, Equatable {
    private let base: any TextLayoutCollection

    init(_ base: any TextLayoutCollection) {
      self.base = base
    }

    var layouts: [any TextLayout] {
      base.layouts
    }

    var separatesLayouts: Bool {
      base.separatesLayouts
    }

    func isEqual(to other: any TextLayoutCollection) -> Bool {
      base.isEqual(to: other)
    }

    func needsPositionReconciliation(with other: any TextLayoutCollection) -> Bool {
      base.needsPositionReconciliation(with: other)
    }

    func index(of layout: Text.Layout) -> Int? {
      base.index(of: layout)
    }

    static func == (lhs: AnyTextLayoutCollection, rhs: AnyTextLayoutCollection) -> Bool {
      lhs.isEqual(to: rhs.base)
    }
  }

  extension TextLayoutCollection {
    var separatesLayouts: Bool { false }

    func isText(at point: CGPoint) -> Bool {
      layouts.contains { layout in
        layout.frame.insetBy(dx: -2, dy: -2).contains(point)
          && layout.lines.contains {
            $0.typographicBounds.offsetBy(dx: layout.origin.x, dy: layout.origin.y)
              .insetBy(dx: -2, dy: -1).contains(point)
          }
      }
    }
  }

  protocol TextLayout {
    var attributedString: NSAttributedString { get }
    var origin: CGPoint { get }
    var bounds: CGRect { get }
    var lines: [any TextLine] { get }
  }

  extension TextLayout {
    var frame: CGRect {
      bounds.offsetBy(dx: origin.x, dy: origin.y)
    }

    var runs: [any TextRun] {
      lines.flatMap(\.runs)
    }
  }

  protocol TextLine {
    var origin: CGPoint { get }
    var typographicBounds: CGRect { get }
    var runs: [any TextRun] { get }
  }

  protocol TextRun {
    var layoutDirection: LayoutDirection { get }
    var typographicBounds: CGRect { get }
    var url: URL? { get }
    var slices: [any TextRunSlice] { get }
  }

  protocol TextRunSlice {
    var typographicBounds: CGRect { get }
    var characterRange: Range<Int> { get }
  }

#endif
