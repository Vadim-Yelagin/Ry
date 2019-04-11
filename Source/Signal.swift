public struct Signal<T> {
	public let addObserver: (Observer<T>) -> Disposable

	public init(_ addObserver: @escaping (Observer<T>) -> Disposable) {
		self.addObserver = addObserver
	}
}

public extension Signal {
	func addObserver(_ observe: @escaping (T) -> Void) -> Disposable {
		return addObserver(Observer(observe))
	}

	static var never: Signal {
		return Signal { _ in Disposable() }
	}

	static func value(_ value: T) -> Signal {
		return Signal { observer in
			observer.observe(value)
			return Disposable()
		}
	}

	static func values<S: Sequence>(_ values: S) -> Signal where S.Element == T {
		return Signal { observer in
			for value in values {
				observer.observe(value)
			}
			return Disposable()
		}
	}

	func contramap<U>(_ transform: @escaping (Observer<U>) -> Observer<T>) -> Signal<U> {
		return Signal<U> { [addObserver] observer in
			addObserver(transform(observer))
		}
	}

	func map<U>(_ transform: @escaping (T) -> U) -> Signal<U> {
		return contramap { $0.contramap(transform) }
	}

	func filter(_ predicate: @escaping (T) -> Bool) -> Signal {
		return contramap { $0.filter(predicate) }
	}

	func compactMap<U>(_ transform: @escaping (T) -> U?) -> Signal<U> {
		return contramap { $0.compactContramap(transform) }
	}

	func compacted<U>() -> Signal<U> where T == U? {
		return contramap { $0.compacted() }
	}

	func switchMap<U>(_ transform: @escaping (T) -> Signal<U>) -> Signal<U> {
		return Signal<U> { [addObserver] uObserver in
			let innerDisposable = UnfairAtomic<Disposable?>(nil)
			let tObserver = uObserver.mergeContramap(transform) { newDisposable in
				innerDisposable.swap(newDisposable)?.dispose()
			}
			let outerDisposable = addObserver(tObserver)
			return Disposable {
				outerDisposable.dispose()
				innerDisposable.swap(nil)?.dispose()
			}
		}
	}

	func switchAll<U>() -> Signal<U> where T == Signal<U> {
		return switchMap { $0 }
	}

	func mergeMap<U>(_ transform: @escaping (T) -> Signal<U>) -> Signal<U> {
		return Signal<U> { [addObserver] uObserver in
			let innerDisposables = UnfairAtomic([Disposable]())
			let tObserver = uObserver.mergeContramap(transform) { newDisposable in
				innerDisposables.access { $0.append(newDisposable) }
			}
			let outerDisposable = addObserver(tObserver)
			return Disposable {
				outerDisposable.dispose()
				innerDisposables.swap([]).forEach { $0.dispose() }
			}
		}
	}

	func mergeAll<U>() -> Signal<U> where T == Signal<U> {
		return mergeMap { $0 }
	}

	static func merge<S: Sequence>(_ signals: S) -> Signal where S.Element == Signal<T> {
		return Signal<Signal<T>>.values(signals).mergeAll()
	}

	static func merge(_ signals: Signal<T>...) -> Signal {
		return merge(signals)
	}

	func startWith(_ value: T) -> Signal {
		return Signal { [addObserver] observer in
			observer.observe(value)
			return addObserver(observer)
		}
	}

	func startWith(_ lazy: @escaping () -> T) -> Signal {
		return Signal { [addObserver] observer in
			observer.observe(lazy())
			return addObserver(observer)
		}
	}

	private struct TakeWhileState {
		var isStopped = false
		var disposable: Disposable?
	}

	func takeWhile(_ predicate: @escaping (T) -> Bool) -> Signal {
		return Signal { [addObserver] observer in
			let atomic = UnfairAtomic(TakeWhileState())
			let disposable = addObserver(Observer { t in
				let shouldStop = !predicate(t)
				let state = atomic.access { state -> TakeWhileState in
					if shouldStop {
						state.isStopped = true
					}
					return state
				}
				if state.isStopped {
					state.disposable?.dispose()
				} else {
					observer.observe(t)
				}
			})
			let isStopped = atomic.access { state -> Bool in
				state.disposable = disposable
				return state.isStopped
			}
			if isStopped {
				disposable.dispose()
			}
			return Disposable { [weak atomic] in
				atomic?.access { state -> Disposable? in
					state.isStopped = true
					return state.disposable
				}?.dispose()
			}
		}
	}

	func takeUntil<U>(_ terminator: Signal<U>) -> Signal {
		let nilTerminator = terminator.map { _ in Optional<T>.none }
		let optionals = map(Optional.some)
		return Signal<T?>
			.merge(nilTerminator, optionals)
			.takeWhile { $0 != nil }
			.compacted()
	}

	func skipRepeats(_ areEqual: @escaping (T, T) -> Bool) -> Signal {
		return contramap { $0.skipRepeats(areEqual) }
	}

	func withPrevious() -> Signal<(T, T)> {
		return contramap(Observer.withPrevious)
	}

	func multicast(disposeIn pool: DisposePool) -> Signal {
		let pipe = SignalPipe<T>()
		addObserver(pipe.send).dispose(in: pool)
		return pipe.signal
	}

	func injectEffect(
		beforeValue: ((T) -> Void)? = nil,
		afterValue: ((T) -> Void)? = nil,
		beforeObserver: ((Observer<T>) -> Void)? = nil,
		afterObserver: ((Observer<T>) -> Void)? = nil,
		beforeDispose: VoidClosure? = nil,
		afterDispose: VoidClosure? = nil) -> Signal
	{
		return Signal { [addObserver] observer in
			beforeObserver?(observer)
			let injectedObserver = observer.injectEffect(
				beforeValue: beforeValue,
				afterValue: afterValue
			)
			let disposable = addObserver(injectedObserver)
			afterObserver?(observer)
			return Disposable {
				beforeDispose?()
				disposable.dispose()
				afterDispose?()
			}
		}
	}
}

public extension Signal where T: Equatable {
	func skipRepeats() -> Signal {
		return skipRepeats(==)
	}
}
