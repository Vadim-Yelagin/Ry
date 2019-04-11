public struct ReadOnlyProperty<T> {
	public let getter: () -> T
	public let newValues: Signal<T>

	public init(getter: @escaping () -> T, newValues: Signal<T>) {
		self.getter = getter
		self.newValues = newValues
	}
}

public extension ReadOnlyProperty {
	var value: T {
		return getter()
	}

	var values: Signal<T> {
		return newValues.startWith(getter)
	}

	func map<U>(_ transform: @escaping (T) -> U) -> ReadOnlyProperty<U> {
		return ReadOnlyProperty<U>(
			getter: { [getter] in transform(getter()) },
			newValues: newValues.map(transform)
		)
	}

	func switchMap<U>(_ transform: @escaping (T) -> ReadOnlyProperty<U>) -> ReadOnlyProperty<U> {
		let newValues = self.newValues
			.map { transform($0).values }
			.startWith { [getter] in transform(getter()).newValues }
			.switchAll()
		return ReadOnlyProperty<U>(
			getter: { [getter] in transform(getter()).value },
			newValues: newValues
		)
	}
}
