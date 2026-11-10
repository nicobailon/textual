import SwiftUI

/// A range of characters in a text view, counted from its start, so it stays valid when the text rewraps.
public struct TextualTextRange: Hashable, Sendable {
  public let lowerBound: Int
  public let upperBound: Int

  public init(lowerBound: Int, upperBound: Int) {
    self.lowerBound = lowerBound
    self.upperBound = upperBound
  }
}

/// What lies under a point in a text view: the word, and the block (paragraph, list item, heading) that holds it.
///
/// `wordBounds` is in the coordinate space of the text view, like ``TextualSelection/bounds``.
public struct TextualHit: Equatable, Sendable {
  public let word: String
  public let wordRange: TextualTextRange
  public let wordBounds: CGRect
  public let block: String
  public let blockRange: TextualTextRange
}

#if TEXTUAL_ENABLE_TEXT_SELECTION
  /// The current layout of a text view, for asking what is under a point and where a range of its text sits now.
  ///
  /// A new value arrives with every layout change; points and bounds are in the text view's coordinate space.
  @MainActor
  public struct TextualTextLayout: Identifiable {
    let model: TextSelectionModel
    let origin: CGPoint

    /// The same for every layout of one text fragment, through rewraps: one per paragraph flow or code block.
    public var id: ObjectIdentifier { ObjectIdentifier(model) }

    init(model: TextSelectionModel, origin: CGPoint) {
      self.model = model
      self.origin = origin
    }

    /// The word and block under `point`, or `nil` when the view holds no text.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func hit(at point: CGPoint) -> TextualHit? {
      let local = CGPoint(x: point.x - origin.x, y: point.y - origin.y)
      guard model.hasText, let position = model.closestPosition(to: local),
        let word = wordRange(at: position), let block = model.blockRange(for: position)
      else { return nil }
      return TextualHit(
        word: model.text(in: word),
        wordRange: characters(of: word),
        wordBounds: rect(of: word),
        block: model.text(in: block),
        blockRange: characters(of: block)
      )
    }

    /// Where `range` sits in the current layout, or `nil` when it no longer fits the text.
    public func bounds(of range: TextualTextRange) -> CGRect? {
      guard model.hasText, range.lowerBound <= range.upperBound,
        let start = model.position(from: model.startPosition, offset: range.lowerBound),
        let end = model.position(from: model.startPosition, offset: range.upperBound)
      else { return nil }
      let rect = rect(of: TextRange(start: start, end: end))
      return rect.isNull ? nil : rect
    }

    /// All the text the view draws, in the order its offsets count it.
    public var string: String {
      model.hasText ? model.text(in: TextRange(start: model.startPosition, end: model.endPosition)) : ""
    }

    private func wordRange(at position: TextPosition) -> TextRange? {
      #if os(macOS)
        model.wordRange(for: position)
      #else
        model.characterRange(at: model.caretRect(for: position).origin)
      #endif
    }

    private func characters(of range: TextRange) -> TextualTextRange {
      TextualTextRange(
        lowerBound: model.offset(from: model.startPosition, to: range.start),
        upperBound: model.offset(from: model.startPosition, to: range.end)
      )
    }

    private func rect(of range: TextRange) -> CGRect {
      model.selectionRects(for: range).reduce(CGRect.null) { $0.union($1.rect) }
        .offsetBy(dx: origin.x, dy: origin.y)
    }
  }

  extension EnvironmentValues {
    @Entry var textLayoutChange: (@MainActor (TextualTextLayout) -> Void)?
  }

  extension TextualNamespace where Base: View {
    /// Calls `action` with the text's layout when it first lays out and after every change (a rewrap, a new size).
    ///
    /// Needs text selection enabled (`textual.textSelection(.enabled)`), which keeps the layout this reads.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func onLayoutChange(_ action: @escaping @MainActor (TextualTextLayout) -> Void) -> some View {
      base.environment(\.textLayoutChange, action)
    }
  }
#endif
