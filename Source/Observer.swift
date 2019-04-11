public struct Observer<T> {
	public let observe: (T) -> Void

	public init(_ observe: @escaping (T) -> Void) {
		self.observe = observe
	}
}

public extension Observer {
	func contramap<U>(_ transform: @escaping (U) -> T) -> Observer<U> {
		return Observer<U> { [observe] u in
			observe(transform(u))
		}
	}

	func filter(_ predicate: @escaping (T) -> Bool) -> Observer {
		return Observer { [observe] t in
			if predicate(t) {
				observe(t)
			}
		}
	}

	func compactContramap<U>(_ transform: @escaping (U) -> T?) -> Observer<U> {
		return Observer<U> { [observe] u in
			if let t = transform(u) {
				observe(t)
			}
		}
	}

	func compacted() -> Observer<T?> {
		return compactContramap { $0 }
	}

	func mergeContramap<U>(
		_ transform: @escaping (U) -> Signal<T>,
		addDisposable: @escaping (Disposable) -> Void) -> Observer<U>
	{
		return Observer<U> { u in
			addDisposable(transform(u).addObserver(self))
		}
	}

	func mergeAll(addDisposable: @escaping (Disposable) -> Void) -> Observer<Signal<T>> {
		return mergeContramap({ $0 }, addDisposable: addDisposable)
	}

	func skipRepeats(_ areEqual: @escaping (T, T) -> Bool) -> Observer {
		let atomic = UnfairAtomic<T?>(nil)
		return Observer { [observe] t in
			if let previous = atomic.swap(t), areEqual(previous, t) {
				// skip
			} else {
				observe(t)
			}
		}
	}

	static func withPrevious(_ observer: Observer<(T, T)>) -> Observer {
		let atomic = UnfairAtomic<T?>(nil)
		return Observer { [observe = observer.observe] t in
			if let previous = atomic.swap(t) {
				observe((previous, t))
			}
		}
	}

	func injectEffect(
		beforeValue: ((T) -> Void)? = nil,
		afterValue: ((T) -> Void)? = nil) -> Observer
	{
		if beforeValue == nil && afterValue == nil {
			return self
		}
		return Observer { [observe] t in
			beforeValue?(t)
			observe(t)
			afterValue?(t)
		}
	}
}

public extension Observer where T: Equatable {
	func skipRepeats() -> Observer {
		return skipRepeats(==)
	}
}
