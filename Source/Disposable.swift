public typealias VoidClosure = () -> Void

public struct Disposable {
	// The class is wrapped in an opaque struct to prevent bad practices
	// like comparing disposables or making a weak reference to a disposable
	private class Impl {
		var dispose: VoidClosure?

		init(_ dispose: @escaping VoidClosure) {
			self.dispose = dispose
		}

		deinit {
			assert(dispose == nil, "Disposable not disposed!")
		}
	}

	private let impl: Impl

	public init(_ dispose: @escaping VoidClosure = {}) {
		impl = Impl(dispose)
	}

	public var isDisposed: Bool {
		return impl.dispose == nil
	}

	public func dispose() {
		impl.dispose?()
		impl.dispose = nil
	}
}

public extension Disposable {
	init<S: Sequence>(_ disposables: S) where S.Element == Disposable {
		self.init {
			for disposable in disposables {
				disposable.dispose()
			}
		}
	}

	init(_ disposables: Disposable...) {
		self.init(disposables)
	}
}
