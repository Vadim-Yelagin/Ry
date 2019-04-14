import Foundation

public protocol Atomic: class {
	associatedtype T

	@discardableResult
	func access<U>(_ block: (inout T) throws -> U) rethrows -> U

	func accessRead<U>(_ block: (T) throws -> U) rethrows -> U
}

public extension Atomic {
	@inlinable
	func accessRead<U>(_ block: (T) throws -> U) rethrows -> U {
		return try access { try block($0) }
	}

	var value: T {
		get {
			return accessRead { $0 }
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

public final class UnsafeAtomic<T>: Atomic {
	private var unsafeValue: T

	public init(_ initialValue: T) {
		unsafeValue = initialValue
	}

	@discardableResult
	public func access<U>(_ block: (inout T) throws -> U) rethrows -> U {
		return try block(&unsafeValue)
	}
}

public final class UnfairAtomic<T>: Atomic {
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

	@discardableResult
	public func access<U>(_ block: (inout T) throws -> U) rethrows -> U {
		os_unfair_lock_lock(lock)
		defer { os_unfair_lock_unlock(lock) }
		return try block(&unsafeValue)
	}
}
