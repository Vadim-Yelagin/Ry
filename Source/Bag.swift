public struct Bag<T> {
	public struct Key {
		fileprivate let value: Int
	}

	private var counter = 0
	private var items = [Int: T]()

	public mutating func add(_ item: T) -> Key {
		let key = counter
		counter += 1
		items[key] = item
		return Key(value: key)
	}

	public mutating func remove(key: Key) {
		items.removeValue(forKey: key.value)
	}

	public var allItems: [T] {
		return Array(items.values)
	}
}
