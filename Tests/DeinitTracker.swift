final class DeinitTracker {
	final class Object {
		fileprivate let onDeinit: () -> Void

		fileprivate init(onDeinit: @escaping () -> Void) {
			self.onDeinit = onDeinit
		}

		deinit {
			onDeinit()
		}
	}

	var object: Object?
	private(set) var isObjectDeinited = false

	init() {
		object = Object(onDeinit: { [weak self] in
			self?.isObjectDeinited = true
		})
	}

	func captureObject() -> () -> Void {
		defer { object = nil }
		return { [object] in
			withExtendedLifetime(object, {})
		}
	}
}

func withExtendedLifetime<T, Result>(_ x: T, _ body: (T) throws -> Result) rethrows -> Result {
	return try withExtendedLifetime(x) {
		try body(x)
	}
}
