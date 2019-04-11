import Ry

final class ClosureTracker<T> {
	private(set) var values = [T]()

	func call(_ t: T) {
		values.append(t)
	}
}

extension ClosureTracker {
	var observer: Observer<T> {
		return Observer(call)
	}
}

final class VoidClosureTracker {
	private(set) var timesCalled = 0

	func call() {
		timesCalled += 1
	}
}
