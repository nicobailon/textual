import SwiftUI

struct FadeInAttribute: TextAttribute {
  var start: TimeInterval
}

extension AttributedStringProtocol {
  var fadeIns: (newest: TimeInterval, gap: TimeInterval?)? {
    let starts = Set(runs[AttributeScopes.TextualAttributes.FadeInAttribute.self].compactMap(\.0)).sorted()
    guard let newest = starts.last else { return nil }
    return (newest, starts.dropLast().last.map { newest - $0 })
  }
}
