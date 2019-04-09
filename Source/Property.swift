public struct Property<T> {
    public let getter: () -> T
    public let setter: (T) -> Void
    public let newValues: Signal<T>

    public init(getter: @escaping () -> T, setter: @escaping (T) -> Void, newValues: Signal<T>) {
        self.getter = getter
        self.setter = setter
        self.newValues = newValues
    }
}

public extension Property {
    var value: T {
        get { return getter() }
        nonmutating set { setter(newValue) }
    }

    var values: Signal<T> {
        return newValues.startWith(getter)
    }

    init(getter: @escaping () -> T, setter: @escaping (T) -> Void) {
        let pipe = SignalPipe<T>()
        self.getter = getter
        self.setter = {
            setter($0)
            pipe.send($0)
        }
        self.newValues = pipe.signal
    }

    init(initialValue: T) {
        let atomic = UnfairAtomic(initialValue)
        self.init(
            getter: { atomic.value },
            setter: { atomic.value = $0 }
        )
    }

    func bimap<U>(to: @escaping (T) -> U, from: @escaping (U) -> T) -> Property<U> {
        return Property<U>(
            getter: { [getter] in to(getter()) },
            setter: { [setter] in setter(from($0)) },
            newValues: newValues.map(to)
        )
    }

    var readOnly: ReadOnlyProperty<T> {
        return ReadOnlyProperty(getter: getter, newValues: newValues)
    }
}
