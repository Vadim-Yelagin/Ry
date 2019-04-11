public extension ReadOnlyProperty {
	static func combineLatest<U>(_ properties: [ReadOnlyProperty<U>]) -> ReadOnlyProperty where T == [U] {
		let getters = properties.map { $0.getter }
		func getter() -> T {
			return getters.map { $0() }
		}
		let newValues = Signal<T> { observer in
			func sendAll(changeIdx: Int, newU: U) {
				let values = getters.enumerated().map { idx, getter in
					idx == changeIdx ? newU : getter()
				}
				observer.observe(values)
			}
			let disposables = properties.enumerated().map { idx, property in
				property.newValues.addObserver { u in
					sendAll(changeIdx: idx, newU: u)
				}
			}
			return Disposable(disposables)
		}
		return ReadOnlyProperty(getter: getter, newValues: newValues)
	}

	static func combineLatest<U0, U1>(
		_ p0: ReadOnlyProperty<U0>,
		_ p1: ReadOnlyProperty<U1>) -> ReadOnlyProperty where T == (U0, U1)
	{
		let g0 = p0.getter
		let g1 = p1.getter
		func getter() -> T {
			return (g0(), g1())
		}
		let newValues = Signal<T> { observer in
			return Disposable(
				p0.newValues.addObserver { u0 in
					observer.observe((u0, g1()))
				},
				p1.newValues.addObserver { u1 in
					observer.observe((g0(), u1))
				}
			)
		}
		return ReadOnlyProperty(getter: getter, newValues: newValues)
	}

	static func combineLatest<U0, U1, U2>(
		_ p0: ReadOnlyProperty<U0>,
		_ p1: ReadOnlyProperty<U1>,
		_ p2: ReadOnlyProperty<U2>) -> ReadOnlyProperty where T == (U0, U1, U2)
	{
		let g0 = p0.getter
		let g1 = p1.getter
		let g2 = p2.getter
		func getter() -> T {
			return (g0(), g1(), g2())
		}
		let newValues = Signal<T> { observer in
			return Disposable(
				p0.newValues.addObserver { u0 in
					observer.observe((u0, g1(), g2()))
				},
				p1.newValues.addObserver { u1 in
					observer.observe((g0(), u1, g2()))
				},
				p2.newValues.addObserver { u2 in
					observer.observe((g0(), g1(), u2))
				}
			)
		}
		return ReadOnlyProperty(getter: getter, newValues: newValues)
	}

	static func combineLatest<U0, U1, U2, U3>(
		_ p0: ReadOnlyProperty<U0>,
		_ p1: ReadOnlyProperty<U1>,
		_ p2: ReadOnlyProperty<U2>,
		_ p3: ReadOnlyProperty<U3>) -> ReadOnlyProperty where T == (U0, U1, U2, U3)
	{
		let g0 = p0.getter
		let g1 = p1.getter
		let g2 = p2.getter
		let g3 = p3.getter
		func getter() -> T {
			return (g0(), g1(), g2(), g3())
		}
		let newValues = Signal<T> { observer in
			return Disposable(
				p0.newValues.addObserver { u0 in
					observer.observe((u0, g1(), g2(), g3()))
				},
				p1.newValues.addObserver { u1 in
					observer.observe((g0(), u1, g2(), g3()))
				},
				p2.newValues.addObserver { u2 in
					observer.observe((g0(), g1(), u2, g3()))
				},
				p3.newValues.addObserver { u3 in
					observer.observe((g0(), g1(), g2(), u3))
				}
			)
		}
		return ReadOnlyProperty(getter: getter, newValues: newValues)
	}
}
