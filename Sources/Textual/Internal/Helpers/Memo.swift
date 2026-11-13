import Foundation

// Kept in @State and filled from body: unlike state written from onChange, it has its value on the first layout and
// costs no second pass. Not observable on purpose, so filling it never invalidates the view.
@MainActor final class Memo<Key: Equatable, Value> {
  private(set) var value: Value?
  private var key: Key?

  func value(for key: Key, _ compute: (Key) -> Value) -> Value {
    if let value, self.key == key {
      return value
    }
    let value = compute(key)
    self.key = key
    self.value = value
    return value
  }
}
