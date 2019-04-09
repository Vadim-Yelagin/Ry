import Foundation

public final class UnfairAtomic<T> {
    private var unsafeValue: T
    private let lock: os_unfair_lock_t

    public init(_ initialValue: T) {
        unsafeValue = initialValue
        lock = .allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock())
    }

    deinit {
        lock.deinitialize(count: 1)
        lock.deallocate()
    }

    @discardableResult public func access<U>(_ block: (inout T) throws -> U) rethrows -> U {
        os_unfair_lock_lock(lock)
        defer { os_unfair_lock_unlock(lock) }
        return try block(&unsafeValue)
    }
}

public extension UnfairAtomic {
    var value: T {
        get {
            return access { $0 }
        }
        set {
            access { $0 = newValue }
        }
    }

    func swap(_ newValue: T) -> T {
        return access {
            let oldValue = $0
            $0 = newValue
            return oldValue
        }
    }
}
