public struct SignalPipe<T> {
	private let observers = UnfairAtomic(Bag<Observer<T>>())
	public let signal: Signal<T>

	public init() {
		signal = Signal { [weak observers] observer in
			guard let observers = observers else {
				return Disposable()
			}
			let key = observers.access { $0.add(observer) }
			return Disposable { [weak observers] in
				observers?.access { $0.remove(key: key) }
			}
		}
	}

	public func send(_ t: T) {
		observers
			.access { $0.allItems }
			.forEach { $0.observe(t) }
	}
}
