public extension Signal {
	static func combineLatest<U>(_ signals: [Signal<U>]) -> Signal where T == [U] {
		let count = signals.count
		return Signal { observer in
			func sendAll(_ latest: [U?]) {
				let compacted = latest.compactMap { $0 }
				if compacted.count == count {
					observer.observe(compacted)
				}
			}
			let latest = UnfairAtomic([U?](repeating: nil, count: count))
			let disposables = signals.enumerated().map { idx, signal in
				signal.addObserver { u in
					sendAll(latest.access {
						$0[idx] = u
						return $0
					})
				}
			}
			return Disposable(disposables)
		}
	}

	static func combineLatest<U0, U1>(_ signal0: Signal<U0>, _ signal1: Signal<U1>) -> Signal where T == (U0, U1) {
		return Signal { observer in
			func sendAll(_ latest: (U0?, U1?)) {
				if let u0 = latest.0, let u1 = latest.1 {
					observer.observe((u0, u1))
				}
			}
			let latest = UnfairAtomic<(U0?, U1?)>((nil, nil))
			return Disposable(
				signal0.addObserver { u0 in
					sendAll(latest.access {
						$0.0 = u0
						return $0
					})
				},
				signal1.addObserver { u1 in
					sendAll(latest.access {
						$0.1 = u1
						return $0
					})
				}
			)
		}
	}

	static func combineLatest<U0, U1, U2>(
		_ signal0: Signal<U0>,
		_ signal1: Signal<U1>,
		_ signal2: Signal<U2>) -> Signal where T == (U0, U1, U2)
	{
		return Signal { observer in
			func sendAll(_ latest: (U0?, U1?, U2?)) {
				if let u0 = latest.0, let u1 = latest.1, let u2 = latest.2 {
					observer.observe((u0, u1, u2))
				}
			}
			let latest = UnfairAtomic<(U0?, U1?, U2?)>((nil, nil, nil))
			return Disposable(
				signal0.addObserver { u0 in
					sendAll(latest.access {
						$0.0 = u0
						return $0
					})
				},
				signal1.addObserver { u1 in
					sendAll(latest.access {
						$0.1 = u1
						return $0
					})
				},
				signal2.addObserver { u2 in
					sendAll(latest.access {
						$0.2 = u2
						return $0
					})
				}
			)
		}
	}

	static func combineLatest<U0, U1, U2, U3>(
		_ signal0: Signal<U0>,
		_ signal1: Signal<U1>,
		_ signal2: Signal<U2>,
		_ signal3: Signal<U3>) -> Signal where T == (U0, U1, U2, U3)
	{
		return Signal { observer in
			func sendAll(_ latest: (U0?, U1?, U2?, U3?)) {
				if let u0 = latest.0, let u1 = latest.1, let u2 = latest.2, let u3 = latest.3 {
					observer.observe((u0, u1, u2, u3))
				}
			}
			let latest = UnfairAtomic<(U0?, U1?, U2?, U3?)>((nil, nil, nil, nil))
			return Disposable(
				signal0.addObserver { u0 in
					sendAll(latest.access {
						$0.0 = u0
						return $0
					})
				},
				signal1.addObserver { u1 in
					sendAll(latest.access {
						$0.1 = u1
						return $0
					})
				},
				signal2.addObserver { u2 in
					sendAll(latest.access {
						$0.2 = u2
						return $0
					})
				},
				signal3.addObserver { u3 in
					sendAll(latest.access {
						$0.3 = u3
						return $0
					})
				}
			)
		}
	}
}
