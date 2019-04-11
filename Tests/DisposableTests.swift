import XCTest
import Ry

class DisposableTests: XCTestCase {
	func test_whenInitialized_doesNotCallClosure() {
		let tracker = VoidClosureTracker()
		let disposable = Disposable(tracker.call)

		XCTAssertEqual(tracker.timesCalled, 0)
		disposable.dispose()
	}

	func test_whenDisposed_callsClosure() {
		let tracker = VoidClosureTracker()
		let disposable = Disposable(tracker.call)
		disposable.dispose()
		XCTAssertEqual(tracker.timesCalled, 1)
	}

	func test_whenDisposedTwice_callsClosureOnce() {
		let tracker = VoidClosureTracker()
		let disposable = Disposable(tracker.call)
		disposable.dispose()
		disposable.dispose()
		XCTAssertEqual(tracker.timesCalled, 1)
	}

	func test_whenDisposed_releasesClosure() {
		let tracker = DeinitTracker()
		let disposable = Disposable(tracker.captureObject())
		disposable.dispose()
		XCTAssert(tracker.isObjectDeinited)
	}
}
