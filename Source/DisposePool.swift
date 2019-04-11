public final class DisposePool {
    private static let defaultVacuumThreshold = 10
    private var disposables = [Disposable]()
    private var vacuumThreshold = defaultVacuumThreshold

    public init() {}

    deinit {
        drain()
    }

    public func add(disposable: Disposable) {
        if disposable.isDisposed {
            return
        }
        disposables.append(disposable)
        if disposables.count >= vacuumThreshold {
            disposables.removeAll { $0.isDisposed }
            vacuumThreshold = max(disposables.count * 2, DisposePool.defaultVacuumThreshold)
        }
    }

    public func drain() {
        let disposables = self.disposables
        self.disposables.removeAll()
        for disposable in disposables {
            disposable.dispose()
        }
        vacuumThreshold = DisposePool.defaultVacuumThreshold
    }
}

public extension Disposable {
    func dispose(in pool: DisposePool) {
        pool.add(disposable: self)
    }
}
