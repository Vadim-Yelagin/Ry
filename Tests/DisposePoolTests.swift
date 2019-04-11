import XCTest
import Ry

class DisposePoolTests: XCTestCase {
	func test_whenDisposableIsAdded_retainsIt() {
		let tracker = DeinitTracker()
		let pool = DisposePool()
		Disposable(tracker.captureObject()).dispose(in: pool)
		XCTAssertFalse(tracker.isObjectDeinited)
	}

	func test_whenDrained_disposesDiposables() {
		let tracker = VoidClosureTracker()
		let pool = DisposePool()
		Disposable(tracker.call).dispose(in: pool)
		Disposable(tracker.call).dispose(in: pool)
		Disposable(tracker.call).dispose(in: pool)
		pool.drain()
		XCTAssertEqual(tracker.timesCalled, 3)
	}

	func test_whenDeinited_disposesDiposables() {
		let tracker = VoidClosureTracker()
		withExtendedLifetime(DisposePool()) {
			Disposable(tracker.call).dispose(in: $0)
			Disposable(tracker.call).dispose(in: $0)
			Disposable(tracker.call).dispose(in: $0)
		}
		XCTAssertEqual(tracker.timesCalled, 3)
	}
}
